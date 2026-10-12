package dev.nariinfo.evensies.sync

import tools.jackson.databind.JsonNode
import tools.jackson.databind.node.JsonNodeFactory
import tools.jackson.databind.node.ObjectNode

/** Pure in-memory group state. Maps keep insertion order (Kotlin's `+` returns a LinkedHashMap). */
data class GroupState(
    val name: String? = null,
    val defaultCurrency: String? = null,
    val members: Map<String, MemberDto> = emptyMap(),
    val expenses: Map<String, ExpenseDto> = emptyMap(),
    val payments: Map<String, PaymentDto> = emptyMap(),
    val comments: Map<String, CommentDto> = emptyMap(),
    val simplifyDebts: Boolean = true,
    /** SplitSpec (percent or shares) new expenses start from; null = equal. */
    val defaultSplit: JsonNode? = null,
    /** "group" or "friend" (a hidden two-person group); set by group.created only (rule 13). */
    val kind: String = "group",
    /** Receipts in attach order (rule 14). */
    val attachments: Map<String, AttachmentDto> = emptyMap(),
    /** Repeating series in creation order, stopped ones included (rule 15). */
    val recurrences: Map<String, RecurrenceDto> = emptyMap(),
)

/**
 * Kotlin twin of the Dart applier. Rules (docs/API.md "적용 규칙"):
 * 1. pure and idempotent; 2. field-level last-write-wins by applying in seq order;
 * 3. delete beats update; 4. unknown targets are ignored; 5. member.removed only flags;
 * 6. payment.confirmed sets status, ignored for unknown or deleted payments; 7. expense.restored / payment.restored are
 * the only way back from deleted (the status is kept); payment.deleted with a replacedBy string (an edit) also sets
 * replaced (never cleared), and payment.restored on a replaced payment is ignored; 8. comment.added only adds new ids,
 * comment.deleted flags and blanks the text; 9. missing notes = null, null clears notes/category/fxRateToDefault/split
 * and is ignored elsewhere; 10. payers are the source of truth and paidBy is the primary payer; 11. group settings keep absent keys; 12. the default currency is locked once the group
 * has an expense or a payment (deleted ones included); 13. group.created sets kind (missing or not a string = "group"),
 * nothing changes it afterwards; expense.deleted with a movedTo object also sets moved (never cleared), and
 * expense.restored on a moved expense is ignored (it counts in the other group now); 14. attachment.added appends a new
 * id for a known expense (deleted ones included) and ignores a known id or an unknown expense; attachment.deleted flags
 * a known id (its payload expenseId is never read); expense deletes and moves leave receipts alone; 15. recurrence.created
 * appends a new series id (a known one, stopped or not, changes nothing), recurrence.updated replaces template keys one
 * by one (null stored as null) on a live series and is ignored otherwise, recurrence.deleted flags a known series; series
 * events never touch expenses; 16. expenses carry recurrenceId/occurrence (missing = null), an update sets the keys present.
 * Payloads are assumed to be validated (EventValidator) — missing fields fall back to zero values.
 */
object EventApplier {
    fun apply(state: GroupState, type: String, p: JsonNode): GroupState = when (type) {
        "group.created" -> state.copy(
            name = p.text("name"), defaultCurrency = p.text("defaultCurrency"),
            kind = p.field("kind")?.takeIf { it.isString }?.asString() ?: "group",
        )
        "group.updated" -> state.copy(
            name = p.text("name") ?: state.name,
            defaultCurrency = p.text("defaultCurrency")?.takeIf { state.expenses.isEmpty() && state.payments.isEmpty() } ?: state.defaultCurrency,
            simplifyDebts = p.bool("simplifyDebts") ?: state.simplifyDebts,
            defaultSplit = if (p.has("defaultSplit")) p.field("defaultSplit") else state.defaultSplit,
        )

        "member.added" -> {
            val id = p.text("memberId") ?: ""
            if (id in state.members) state
            else state.withMember(MemberDto(id, p.text("name") ?: "", p.text("userId")))
        }
        "member.linked" -> state.members[p.text("memberId")]?.let { state.withMember(it.copy(userId = p.text("userId"))) } ?: state
        "member.removed" -> state.members[p.text("memberId")]?.let { state.withMember(it.copy(removed = true)) } ?: state

        "expense.created" -> {
            val id = p.text("expenseId") ?: ""
            if (id in state.expenses) state else state.withExpense(expense(id, p))
        }
        "expense.updated" -> {
            val e = state.expenses[p.text("expenseId")]
            val f = p.get("fields")
            if (e == null || e.deleted || f == null || !f.isObject) state
            else {
                val amount = f.long("amount") ?: e.amount
                // Rule 10: (a) payers replace, (b) a paidBy alone pays everything, (c) a single payer follows the amount, (d) kept.
                val payers = f.shares("payers")
                    ?: f.text("paidBy")?.let { listOf(ShareDto(it, amount)) }
                    ?: e.payers.singleOrNull()?.takeIf { f.long("amount") != null }?.let { listOf(it.copy(amount = amount)) }
                    ?: e.payers
                state.withExpense(
                    e.copy(
                        description = f.text("description") ?: e.description,
                        amount = amount,
                        currency = f.text("currency") ?: e.currency,
                        fxRateToDefault = if (f.has("fxRateToDefault")) f.double("fxRateToDefault") else e.fxRateToDefault,
                        paidBy = primaryPayer(payers) ?: e.paidBy,
                        date = f.text("date") ?: e.date,
                        category = if (f.has("category")) f.text("category") else e.category,
                        shares = f.shares("shares") ?: e.shares,
                        notes = if (f.has("notes")) f.text("notes") else e.notes,
                        payers = payers,
                        refund = f.bool("refund") ?: e.refund,
                        // By key presence: an amount or shares edit without a split makes the split exact.
                        split = when {
                            f.has("split") -> f.field("split")
                            f.field("shares") != null || f.field("amount") != null -> null
                            else -> e.split
                        },
                        recurrenceId = if (f.has("recurrenceId")) f.text("recurrenceId") else e.recurrenceId,
                        occurrence = if (f.has("occurrence")) f.int("occurrence") else e.occurrence,
                    )
                )
            }
        }
        "expense.deleted" -> state.expenses[p.text("expenseId")]
            ?.let { state.withExpense(it.copy(deleted = true, moved = it.moved || p.field("movedTo")?.isObject == true)) } ?: state
        "expense.restored" -> state.expenses[p.text("expenseId")]?.takeUnless { it.moved }
            ?.let { state.withExpense(it.copy(deleted = false)) } ?: state

        "comment.added" -> {
            val id = p.text("commentId") ?: ""
            if (id in state.comments) state
            else state.withComment(
                CommentDto(
                    id = id,
                    expenseId = p.text("expenseId"),
                    paymentId = p.text("paymentId"),
                    authorMemberId = p.text("authorMemberId") ?: "",
                    text = p.text("text") ?: "",
                    createdAt = p.text("createdAt") ?: "",
                )
            )
        }
        "comment.deleted" -> state.comments[p.text("commentId")]?.let { state.withComment(it.copy(deleted = true, text = "")) } ?: state

        "payment.created" -> {
            val id = p.text("paymentId") ?: ""
            if (id in state.payments) state
            else state.withPayment(
                PaymentDto(
                    id = id,
                    fromMember = p.text("fromMember") ?: "",
                    toMember = p.text("toMember") ?: "",
                    amount = p.long("amount") ?: 0,
                    currency = p.text("currency") ?: "",
                    date = p.text("date") ?: "",
                    deleted = false,
                    status = p.text("status") ?: "confirmed",
                )
            )
        }
        "payment.confirmed" -> state.payments[p.text("paymentId")]?.takeUnless { it.deleted }
            ?.let { state.withPayment(it.copy(status = "confirmed")) } ?: state
        "payment.deleted" -> state.payments[p.text("paymentId")]
            ?.let { state.withPayment(it.copy(deleted = true, replaced = it.replaced || p.field("replacedBy")?.isString == true)) } ?: state
        "payment.restored" -> state.payments[p.text("paymentId")]?.takeUnless { it.replaced }
            ?.let { state.withPayment(it.copy(deleted = false)) } ?: state

        "attachment.added" -> {
            val id = p.text("attachmentId") ?: ""
            val expenseId = p.text("expenseId")
            if (id in state.attachments || expenseId !in state.expenses) state
            else state.copy(attachments = state.attachments + (id to AttachmentDto(id, expenseId!!)))
        }
        "attachment.deleted" -> state.attachments[p.text("attachmentId")]
            ?.let { state.copy(attachments = state.attachments + (it.id to it.copy(deleted = true))) } ?: state

        "recurrence.created" -> {
            val id = p.text("recurrenceId") ?: ""
            if (id in state.recurrences) state
            else state.withRecurrence(
                RecurrenceDto(
                    id = id,
                    frequency = p.text("frequency") ?: "",
                    startDate = p.text("startDate") ?: "",
                    timeZone = p.text("timeZone") ?: "",
                    template = p.field("template") ?: JsonNodeFactory.instance.objectNode(),
                )
            )
        }
        "recurrence.updated" -> {
            val r = state.recurrences[p.text("recurrenceId")]
            val f = p.get("fields")
            if (r == null || r.deleted || f !is ObjectNode || r.template !is ObjectNode) state
            else state.withRecurrence(r.copy(template = r.template.deepCopy().setAll(f)))
        }
        "recurrence.deleted" -> state.recurrences[p.text("recurrenceId")]?.let { state.withRecurrence(it.copy(deleted = true)) } ?: state

        else -> state
    }

    /** The expense an `expense.created` payload (or a series template, Phase 8) describes; rule 10 sets payers and paidBy. */
    fun expense(id: String, p: JsonNode): ExpenseDto {
        val amount = p.long("amount") ?: 0
        val payers = p.shares("payers") ?: listOf(ShareDto(p.text("paidBy") ?: "", amount))
        return ExpenseDto(
            id = id,
            description = p.text("description") ?: "",
            amount = amount,
            currency = p.text("currency") ?: "",
            fxRateToDefault = p.double("fxRateToDefault"),
            paidBy = primaryPayer(payers) ?: p.text("paidBy") ?: "",
            date = p.text("date") ?: "",
            category = p.text("category"),
            deleted = false,
            shares = p.shares("shares") ?: emptyList(),
            notes = p.text("notes"),
            payers = payers,
            refund = p.bool("refund") ?: false,
            split = p.field("split"),
            recurrenceId = p.text("recurrenceId"),
            occurrence = p.int("occurrence"),
        )
    }

    /** Rule 10: the payer with the largest amount; on a tie the lowest memberId (UTF-16 order, like Dart). */
    fun primaryPayer(payers: List<ShareDto>): String? =
        payers.maxWithOrNull(compareBy<ShareDto> { it.amount }.thenByDescending { it.memberId })?.memberId

    private fun GroupState.withMember(m: MemberDto) = copy(members = members + (m.id to m))
    private fun GroupState.withExpense(e: ExpenseDto) = copy(expenses = expenses + (e.id to e))
    private fun GroupState.withPayment(p: PaymentDto) = copy(payments = payments + (p.id to p))
    private fun GroupState.withComment(c: CommentDto) = copy(comments = comments + (c.id to c))
    private fun GroupState.withRecurrence(r: RecurrenceDto) = copy(recurrences = recurrences + (r.id to r))
}

// Null-safe payload readers: missing or JSON null → null.
internal fun JsonNode.field(k: String): JsonNode? = get(k)?.takeUnless { it.isNull }
internal fun JsonNode.text(k: String): String? = field(k)?.let { if (it.isString) it.asString() else it.toString() }
internal fun JsonNode.long(k: String): Long? = field(k)?.takeIf { it.isNumber }?.asLong()
internal fun JsonNode.int(k: String): Int? = field(k)?.takeIf { it.isIntegralNumber && it.canConvertToInt() }?.asInt()
internal fun JsonNode.double(k: String): Double? = field(k)?.takeIf { it.isNumber }?.asDouble()
internal fun JsonNode.bool(k: String): Boolean? = field(k)?.takeIf { it.isBoolean }?.asBoolean()
internal fun JsonNode.shares(k: String): List<ShareDto>? = field(k)?.takeIf { it.isArray }?.values()?.map {
    ShareDto(it.text("memberId") ?: "", it.long("amount") ?: 0)
}

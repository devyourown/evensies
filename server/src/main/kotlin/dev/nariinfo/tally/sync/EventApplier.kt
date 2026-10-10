package dev.nariinfo.tally.sync

import tools.jackson.databind.JsonNode

/** Pure in-memory group state. Maps keep insertion order (Kotlin's `+` returns a LinkedHashMap). */
data class GroupState(
    val name: String? = null,
    val defaultCurrency: String? = null,
    val members: Map<String, MemberDto> = emptyMap(),
    val expenses: Map<String, ExpenseDto> = emptyMap(),
    val payments: Map<String, PaymentDto> = emptyMap(),
)

/**
 * Kotlin twin of the Dart applier. Rules (docs/API.md "적용 규칙"):
 * 1. pure and idempotent; 2. field-level last-write-wins by applying in seq order;
 * 3. delete beats update; 4. unknown targets are ignored; 5. member.removed only flags.
 * Payloads are assumed to be validated (EventValidator) — missing fields fall back to zero values.
 */
object EventApplier {
    fun apply(state: GroupState, type: String, p: JsonNode): GroupState = when (type) {
        "group.created" -> state.copy(name = p.text("name"), defaultCurrency = p.text("defaultCurrency"))
        "group.updated" -> state.copy(
            name = p.text("name") ?: state.name,
            defaultCurrency = p.text("defaultCurrency") ?: state.defaultCurrency,
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
            if (id in state.expenses) state
            else state.withExpense(
                ExpenseDto(
                    id = id,
                    description = p.text("description") ?: "",
                    amount = p.long("amount") ?: 0,
                    currency = p.text("currency") ?: "",
                    fxRateToDefault = p.double("fxRateToDefault"),
                    paidBy = p.text("paidBy") ?: "",
                    date = p.text("date") ?: "",
                    category = p.text("category"),
                    deleted = false,
                    shares = p.shares("shares") ?: emptyList(),
                )
            )
        }
        "expense.updated" -> {
            val e = state.expenses[p.text("expenseId")]
            val f = p.get("fields")
            if (e == null || e.deleted || f == null || !f.isObject) state
            else state.withExpense(
                e.copy(
                    description = if (f.has("description")) f.text("description") ?: e.description else e.description,
                    amount = if (f.has("amount")) f.long("amount") ?: e.amount else e.amount,
                    currency = if (f.has("currency")) f.text("currency") ?: e.currency else e.currency,
                    fxRateToDefault = if (f.has("fxRateToDefault")) f.double("fxRateToDefault") else e.fxRateToDefault,
                    paidBy = if (f.has("paidBy")) f.text("paidBy") ?: e.paidBy else e.paidBy,
                    date = if (f.has("date")) f.text("date") ?: e.date else e.date,
                    category = if (f.has("category")) f.text("category") else e.category,
                    shares = if (f.has("shares")) f.shares("shares") ?: e.shares else e.shares,
                )
            )
        }
        "expense.deleted" -> state.expenses[p.text("expenseId")]?.let { state.withExpense(it.copy(deleted = true)) } ?: state

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
                )
            )
        }
        "payment.deleted" -> state.payments[p.text("paymentId")]?.let { state.withPayment(it.copy(deleted = true)) } ?: state

        else -> state
    }

    private fun GroupState.withMember(m: MemberDto) = copy(members = members + (m.id to m))
    private fun GroupState.withExpense(e: ExpenseDto) = copy(expenses = expenses + (e.id to e))
    private fun GroupState.withPayment(p: PaymentDto) = copy(payments = payments + (p.id to p))
}

// Null-safe payload readers: missing or JSON null → null.
internal fun JsonNode.field(k: String): JsonNode? = get(k)?.takeUnless { it.isNull }
internal fun JsonNode.text(k: String): String? = field(k)?.let { if (it.isString) it.asString() else it.toString() }
internal fun JsonNode.long(k: String): Long? = field(k)?.takeIf { it.isNumber }?.asLong()
internal fun JsonNode.double(k: String): Double? = field(k)?.takeIf { it.isNumber }?.asDouble()
internal fun JsonNode.shares(k: String): List<ShareDto>? = field(k)?.takeIf { it.isArray }?.values()?.map {
    ShareDto(it.text("memberId") ?: "", it.long("amount") ?: 0)
}

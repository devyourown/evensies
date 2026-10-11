package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.money.Money
import org.springframework.stereotype.Component
import tools.jackson.databind.JsonNode
import tools.jackson.databind.node.ObjectNode
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeParseException
import java.util.UUID
import kotlin.math.abs

/**
 * Rejects a push batch before anything is stored. Validates each event against the state after the previous ones
 * and returns the batch to store: a `payment.created` with `status: "sent"` whose receiver is a placeholder or the
 * sender themselves is rewritten to `"confirmed"`, and an expense carrying `payers` gets `paidBy` = the primary payer
 * (applier rule 10), so every client pulls the same payload.
 * [paymentCreator] returns the user id that created an already-stored payment.
 */
@Component
class EventValidator {
    fun validateAll(
        initial: GroupState, actorUserId: UUID, events: List<IncomingEvent>, paymentCreator: (String) -> String? = { null },
    ): List<IncomingEvent> {
        var state = initial
        val createdHere = HashSet<String>()
        return events.map { raw ->
            val e = normalize(state, actorUserId, raw)
            validate(state, actorUserId, e) { id -> if (id in createdHere) actorUserId.toString() else paymentCreator(id) }
            if (e.type == "payment.created") createdHere += e.payload.text("paymentId")!!
            state = EventApplier.apply(state, e.type, e.payload)
            e
        }
    }

    private fun normalize(s: GroupState, actor: UUID, e: IncomingEvent): IncomingEvent {
        if (!e.payload.isObject) return e
        return when (e.type) {
            "expense.created" -> withPrimaryPayer(e) { it }
            "expense.updated" -> withPrimaryPayer(e) { it.get("fields")?.takeIf(JsonNode::isObject) }
            "payment.created" -> {
                if (e.payload.text("status") != "sent") return e
                val receiverUser = s.members[e.payload.text("toMember")]?.userId
                if (receiverUser != null && receiverUser != actor.toString()) return e
                e.copy(payload = (e.payload.deepCopy() as ObjectNode).put("status", "confirmed"))
            }
            else -> e
        }
    }

    /**
     * Rewrites (or adds) `paidBy` in the object [at] picks (the payload or `fields`) to the primary payer when it carries
     * well-formed, non-empty `payers`. Anything malformed is left for [validate] to reject.
     */
    private fun withPrimaryPayer(e: IncomingEvent, at: (JsonNode) -> JsonNode?): IncomingEvent {
        val target = at(e.payload) ?: return e
        val payers = target.field("payers")?.takeIf { isShareList(it) && !it.isEmpty }?.let { target.shares("payers") } ?: return e
        if (target.field("paidBy")?.isString == false) return e
        val primary = EventApplier.primaryPayer(payers)!!
        if (target.text("paidBy") == primary) return e
        val copy = e.payload.deepCopy() as ObjectNode
        (at(copy) as ObjectNode).put("paidBy", primary)
        return e.copy(payload = copy)
    }

    private fun validate(s: GroupState, actor: UUID, e: IncomingEvent, paymentCreator: (String) -> String?) {
        val p = e.payload
        if (!p.isObject) bad("payload must be an object")
        when (e.type) {
            "group.created" -> { requireText(p, "name", MAX_GROUP_NAME); requireCurrency(p.text("defaultCurrency")) }
            "group.updated" -> {
                if (p.has("name")) requireText(p, "name", MAX_GROUP_NAME)
                // Rule 12 ignores a late currency change instead of rejecting it: an offline client can't know.
                if (p.field("defaultCurrency") != null) requireCurrency(p.text("defaultCurrency"))
                if (p.has("simplifyDebts") && !p.get("simplifyDebts").isBoolean) bad("simplifyDebts must be true or false")
                p.field("defaultSplit")?.let { validateDefaultSplit(s, it) }
            }
            "member.added" -> {
                requireUuid(p, "memberId"); requireText(p, "name", MAX_MEMBER_NAME); requireOwnUser(p, actor)
                if (p.text("memberId") !in s.members) {
                    if (s.members.size >= MAX_MEMBERS) throw ApiException.limit("A group can have at most $MAX_MEMBERS members")
                    if (p.text("userId") != null) requireNoActiveMember(s, actor)
                }
            }
            "member.linked" -> {
                requireMember(s, p.text("memberId")); requireUuid(p, "userId"); requireOwnUser(p, actor)
                if (s.members.getValue(p.text("memberId")!!).userId != null) {
                    throw ApiException.badRequest("MEMBER_TAKEN", "That member is already linked to a user")
                }
                requireNoActiveMember(s, actor)
            }
            "member.removed" -> requireMember(s, p.text("memberId"))
            "expense.created" -> {
                requireUuid(p, "expenseId"); requireExpenseFields(p, created = true); requireNoDeleted(p)
                validateExpense(s, EventApplier.apply(s, e.type, p).expenses.getValue(p.text("expenseId")!!))
            }
            "expense.updated" -> {
                requireUuid(p, "expenseId")
                val f = p.get("fields")
                if (f == null || !f.isObject) bad("fields must be an object")
                requireExpenseFields(f, created = false)
                val before = s.expenses[p.text("expenseId")]
                if (before != null && !before.deleted) {
                    validateExpense(s, EventApplier.apply(s, e.type, p).expenses.getValue(before.id))
                }
            }
            "expense.deleted", "expense.restored" -> requireUuid(p, "expenseId")
            "comment.added" -> {
                requireUuid(p, "commentId"); requireUuid(p, "expenseId"); requireNoDeleted(p)
                val author = s.members[p.text("authorMemberId")]
                if (author == null || author.removed || author.userId != actor.toString()) {
                    throw ApiException.forbidden("authorMemberId must be your own member")
                }
                if (p.text("expenseId") !in s.expenses) bad("expenseId refers to an unknown expense")
                val text = p.field("text")?.takeIf { it.isString }?.asString()
                if (text.isNullOrBlank() || text.length > MAX_COMMENT) bad("text must be 1 to $MAX_COMMENT characters")
                try { Instant.parse(p.text("createdAt") ?: bad("createdAt is required")) } catch (_: DateTimeParseException) {
                    bad("createdAt must be an ISO-8601 instant")
                }
            }
            "comment.deleted" -> {
                requireUuid(p, "commentId")
                val comment = s.comments[p.text("commentId")] ?: return // rule 4: ignored by the applier
                if (s.members[comment.authorMemberId]?.userId != actor.toString()) {
                    throw ApiException.forbidden("Only the author can delete a comment")
                }
            }
            "payment.created" -> {
                requireUuid(p, "paymentId"); requireNoDeleted(p)
                requireMember(s, p.text("fromMember")); requireMember(s, p.text("toMember"))
                requireAmount(p.field("amount")?.takeIf(::isMinorUnits)?.asLong()); requireCurrency(p.text("currency")); requireDate(p.text("date"))
                p.text("status")?.let { if (it != "sent" && it != "confirmed") bad("status must be sent or confirmed") }
            }
            "payment.confirmed" -> {
                requireUuid(p, "paymentId")
                val payment = s.payments[p.text("paymentId")] ?: bad("paymentId refers to an unknown payment")
                if (s.members[payment.toMember]?.userId != actor.toString()) {
                    throw ApiException.forbidden("Only the receiver can confirm a payment")
                }
            }
            "payment.deleted" -> {
                requireUuid(p, "paymentId")
                val payment = s.payments[p.text("paymentId")] ?: return // rule 4: ignored by the applier
                val me = actor.toString()
                val allowed = paymentCreator(payment.id) == me ||
                    s.members[payment.fromMember]?.userId == me || s.members[payment.toMember]?.userId == me
                if (!allowed) throw ApiException.forbidden("Only the payer or the receiver can delete a payment")
            }
            else -> throw ApiException.badRequest("UNKNOWN_TYPE", "Unknown event type ${e.type}")
        }
    }

    private fun validateExpense(s: GroupState, e: ExpenseDto) {
        if (e.description.isBlank()) bad("description is required")
        requireAmount(e.amount); requireCurrency(e.currency); requireDate(e.date)
        requireMember(s, e.paidBy)
        if (e.fxRateToDefault != null && e.fxRateToDefault < 0) bad("fxRateToDefault must be >= 0")
        // Payers before shares: an amount-only edit of a multi-payer expense (rule 10d) breaks both, the payers explain it.
        val payers = HashSet<String>()
        for (p in e.payers) {
            requireMember(s, p.memberId); requireAmount(p.amount)
            if (!payers.add(p.memberId)) bad("duplicate payer ${p.memberId}")
        }
        if (e.payers.sumOf { it.amount } != e.amount) {
            throw ApiException.badRequest("PAYERS_SUM_MISMATCH", "Payers sum to ${e.payers.sumOf { it.amount }} but amount is ${e.amount}")
        }
        e.split?.field("input")?.propertyNames()?.forEach { requireMember(s, it) }
        val seen = HashSet<String>()
        for (sh in e.shares) {
            requireMember(s, sh.memberId); requireAmount(sh.amount)
            if (!seen.add(sh.memberId)) bad("duplicate share for member ${sh.memberId}")
        }
        if (e.shares.sumOf { it.amount } != e.amount) {
            throw ApiException.badRequest("SUM_MISMATCH", "Shares sum to ${e.shares.sumOf { it.amount }} but amount is ${e.amount}")
        }
    }

    /**
     * Raw JSON types of the expense keys present in `expense.created` or `expense.updated.fields` (docs/API.md 적용
     * 규칙 9). The Kotlin readers coerce a wrong type (a number becomes a string, a string amount null) while the Dart
     * applier casts and throws, so such an event would stop sync on every app. `null` passes here: it is ignored or
     * clears the value in an update, and [validateExpense] rejects it where a created expense needs a value — except
     * `amount` and `shares`, which the readers would default and so must be present in `expense.created`.
     */
    private fun requireExpenseFields(node: JsonNode, created: Boolean) {
        for (k in listOf("description", "currency", "paidBy", "date", "category", "notes")) {
            if (node.field(k)?.isString == false) bad("$k must be a string")
        }
        node.field("description")?.let { if (it.asString().length > MAX_DESCRIPTION) bad("description must be at most $MAX_DESCRIPTION characters") }
        node.field("notes")?.let { if (it.asString().length > MAX_NOTES) bad("notes must be a string of at most $MAX_NOTES characters") }
        node.field("amount")?.let { if (!isMinorUnits(it)) bad("amount must be an integer") }
        node.field("fxRateToDefault")?.let { if (!it.isNumber) bad("fxRateToDefault must be a number or null") }
        node.field("shares")?.let { if (!isShareList(it)) bad("shares must be an array of {memberId: string, amount: integer}") }
        node.field("payers")?.let {
            if (!isShareList(it) || it.isEmpty) bad("payers must be a non-empty array of {memberId: string, amount: integer}")
        }
        node.field("refund")?.let { if (!it.isBoolean) bad("refund must be true or false") }
        node.field("split")?.let { requireSplitSpec(it, "split", EXPENSE_SPLIT_MODES) }
        if (created && node.field("amount") == null) bad("amount is required")
        if (created && node.field("shares") == null) bad("shares is required")
    }

    private fun isMinorUnits(n: JsonNode) = n.isIntegralNumber && n.canConvertToLong()

    private fun isShareList(n: JsonNode) =
        n.isArray && n.values().all { it.isObject && it.field("memberId")?.isString == true && it.field("amount")?.let(::isMinorUnits) == true }

    /**
     * SplitSpec shape (docs/API.md "SplitSpec"): `{mode, input?}`, other keys kept as sent. `input` values are finite
     * numbers: percent and share counts >= 0, adjustments whole by value (Dart's jsonEncode sends `1000.0`).
     */
    private fun requireSplitSpec(spec: JsonNode, name: String, modes: Set<String>) {
        if (!spec.isObject) bad("$name must be an object or null")
        val mode = spec.field("mode")?.takeIf { it.isString }?.asString()
        if (mode !in modes) bad("$name.mode must be one of ${modes.joinToString()}")
        val input = spec.field("input")
        if (mode == "equal") {
            if (input != null) bad("$name.input is not used with equal")
            return
        }
        if (input == null || !input.isObject) bad("$name.input must be an object for $mode")
        for (v in input.values()) {
            val d = v.takeIf { it.isNumber }?.asDouble()
            if (d == null || !d.isFinite()) bad("$name.input values must be finite numbers")
            if (mode == "adjustment") {
                if (d != Math.rint(d)) bad("adjustments must be whole minor units")
            } else if (d < 0) {
                bad("$name.input values must be >= 0")
            }
        }
    }

    private fun validateDefaultSplit(s: GroupState, spec: JsonNode) {
        requireSplitSpec(spec, "defaultSplit", DEFAULT_SPLIT_MODES)
        val input = spec.get("input")
        input.propertyNames().forEach { requireMember(s, it) }
        val total = input.values().sumOf { it.asDouble() }
        when (spec.get("mode").asString()) {
            "percent" -> if (abs(total - 100.0) >= 0.001) throw ApiException.badRequest("SUM_MISMATCH", "defaultSplit percents sum to $total, not 100")
            "shares" -> if (total == 0.0) bad("defaultSplit shares must not all be 0")
        }
    }

    /** The Dart applier builds created rows with `fromJson({...payload})`, which would honour a `deleted` key; Kotlin ignores it. */
    private fun requireNoDeleted(p: JsonNode) {
        val d = p.field("deleted") ?: return
        if (!d.isBoolean || d.asBoolean()) bad("deleted cannot be set when creating")
    }

    /** One active member per user: a second one (or re-linking someone else's) would let a user act as another member. */
    private fun requireNoActiveMember(s: GroupState, actor: UUID) {
        if (s.members.values.any { it.userId == actor.toString() && !it.removed }) {
            throw ApiException.badRequest("MEMBER_TAKEN", "You already have a member in this group")
        }
    }

    private fun requireMember(s: GroupState, id: String?) {
        if (id == null || id !in s.members) throw ApiException.badRequest("UNKNOWN_MEMBER", "Member $id is not in this group")
    }

    /** Clients may only link a member to themselves. */
    private fun requireOwnUser(p: JsonNode, actor: UUID) {
        val userId = p.text("userId") ?: return
        if (userId != actor.toString()) throw ApiException.forbidden("userId must be your own user id")
    }

    /** A non-blank JSON string (no coercion from numbers: the Dart applier casts) of at most [max] UTF-16 units. */
    private fun requireText(p: JsonNode, k: String, max: Int = Int.MAX_VALUE) {
        val v = p.field(k)?.takeIf { it.isString }?.asString()
        if (v.isNullOrBlank() || v.length > max) bad("$k must be a non-blank string" + if (max < Int.MAX_VALUE) " of at most $max characters" else "")
    }

    private fun requireUuid(p: JsonNode, k: String) {
        val v = p.text(k) ?: bad("$k is required")
        try { UUID.fromString(v) } catch (_: IllegalArgumentException) { bad("$k must be a UUID") }
    }

    /**
     * 0..[MAX_AMOUNT]: with at most [MAX_MEMBERS] distinct payers or shares a sum stays far below Long.MAX_VALUE, so
     * `Σ payers == amount` can't pass by wrapping around.
     */
    private fun requireAmount(amount: Long?) {
        if (amount == null) bad("amount must be an integer")
        if (amount < 0) throw ApiException.badRequest("NEGATIVE_AMOUNT", "Amounts must be >= 0")
        if (amount > MAX_AMOUNT) bad("Amounts must be at most $MAX_AMOUNT minor units")
    }

    private fun requireCurrency(c: String?) {
        if (c == null || !Money.isKnown(c)) throw ApiException.badRequest("UNKNOWN_CURRENCY", "Unknown currency $c")
    }

    private fun requireDate(d: String?) {
        try { LocalDate.parse(d ?: bad("date is required")) } catch (_: DateTimeParseException) { bad("date must be YYYY-MM-DD") }
    }

    private fun bad(message: String): Nothing = throw ApiException.badRequest("VALIDATION", message)

    companion object {
        const val MAX_MEMBERS = 50
        const val MAX_DESCRIPTION = 200
        const val MAX_NOTES = 500
        const val MAX_COMMENT = 1000
        const val MAX_GROUP_NAME = 100
        const val MAX_MEMBER_NAME = 100
        const val MAX_AMOUNT = 10_000_000_000_000L
        val EXPENSE_SPLIT_MODES = setOf("equal", "percent", "shares", "adjustment")
        val DEFAULT_SPLIT_MODES = setOf("percent", "shares")
    }
}

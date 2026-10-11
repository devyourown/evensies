package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.money.Money
import org.springframework.stereotype.Component
import tools.jackson.databind.JsonNode
import tools.jackson.databind.node.ObjectNode
import java.time.LocalDate
import java.time.format.DateTimeParseException
import java.util.UUID

/**
 * Rejects a push batch before anything is stored. Validates each event against the state after the previous ones
 * and returns the batch to store: a `payment.created` with `status: "sent"` whose receiver is a placeholder or the
 * sender themselves is rewritten to `"confirmed"`, so every client pulls the same payload.
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
        if (e.type != "payment.created" || !e.payload.isObject || e.payload.text("status") != "sent") return e
        val receiverUser = s.members[e.payload.text("toMember")]?.userId
        if (receiverUser != null && receiverUser != actor.toString()) return e
        return e.copy(payload = (e.payload.deepCopy() as ObjectNode).put("status", "confirmed"))
    }

    private fun validate(s: GroupState, actor: UUID, e: IncomingEvent, paymentCreator: (String) -> String?) {
        val p = e.payload
        if (!p.isObject) bad("payload must be an object")
        when (e.type) {
            "group.created" -> { requireText(p, "name"); requireCurrency(p.text("defaultCurrency")) }
            "group.updated" -> {
                if (p.has("name")) requireText(p, "name")
                if (p.field("defaultCurrency") != null) requireCurrency(p.text("defaultCurrency"))
            }
            "member.added" -> {
                requireUuid(p, "memberId"); requireText(p, "name"); requireOwnUser(p, actor)
                if (p.text("memberId") !in s.members && s.members.size >= MAX_MEMBERS) {
                    throw ApiException.limit("A group can have at most $MAX_MEMBERS members")
                }
            }
            "member.linked" -> { requireMember(s, p.text("memberId")); requireUuid(p, "userId"); requireOwnUser(p, actor) }
            "member.removed" -> requireMember(s, p.text("memberId"))
            "expense.created" -> {
                requireUuid(p, "expenseId")
                validateExpense(s, EventApplier.apply(s, e.type, p).expenses.getValue(p.text("expenseId")!!))
            }
            "expense.updated" -> {
                requireUuid(p, "expenseId")
                val f = p.get("fields")
                if (f == null || !f.isObject) bad("fields must be an object")
                val before = s.expenses[p.text("expenseId")]
                if (before != null && !before.deleted) {
                    validateExpense(s, EventApplier.apply(s, e.type, p).expenses.getValue(before.id))
                }
            }
            "expense.deleted" -> requireUuid(p, "expenseId")
            "payment.created" -> {
                requireUuid(p, "paymentId")
                requireMember(s, p.text("fromMember")); requireMember(s, p.text("toMember"))
                requireAmount(p.long("amount")); requireCurrency(p.text("currency")); requireDate(p.text("date"))
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
        val seen = HashSet<String>()
        for (sh in e.shares) {
            requireMember(s, sh.memberId); requireAmount(sh.amount)
            if (!seen.add(sh.memberId)) bad("duplicate share for member ${sh.memberId}")
        }
        if (e.shares.sumOf { it.amount } != e.amount) {
            throw ApiException.badRequest("SUM_MISMATCH", "Shares sum to ${e.shares.sumOf { it.amount }} but amount is ${e.amount}")
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

    private fun requireText(p: JsonNode, k: String) {
        if (p.text(k).isNullOrBlank()) bad("$k is required")
    }

    private fun requireUuid(p: JsonNode, k: String) {
        val v = p.text(k) ?: bad("$k is required")
        try { UUID.fromString(v) } catch (_: IllegalArgumentException) { bad("$k must be a UUID") }
    }

    private fun requireAmount(amount: Long?) {
        if (amount == null) bad("amount must be an integer")
        if (amount < 0) throw ApiException.badRequest("NEGATIVE_AMOUNT", "Amounts must be >= 0")
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
    }
}

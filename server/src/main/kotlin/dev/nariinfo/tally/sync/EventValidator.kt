package dev.nariinfo.tally.sync

import dev.nariinfo.tally.common.ApiException
import dev.nariinfo.tally.money.Money
import org.springframework.stereotype.Component
import tools.jackson.databind.JsonNode
import java.time.LocalDate
import java.time.format.DateTimeParseException
import java.util.UUID

/** Rejects a push batch before anything is stored. Validates each event against the state after the previous ones. */
@Component
class EventValidator {
    fun validateAll(initial: GroupState, actorUserId: UUID, events: List<IncomingEvent>) {
        var state = initial
        for (e in events) {
            validate(state, actorUserId, e)
            state = EventApplier.apply(state, e.type, e.payload)
        }
    }

    private fun validate(s: GroupState, actor: UUID, e: IncomingEvent) {
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
            }
            "payment.deleted" -> requireUuid(p, "paymentId")
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

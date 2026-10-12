package dev.nariinfo.evensies.activity

import dev.nariinfo.evensies.export.Categories
import dev.nariinfo.evensies.money.Money

/**
 * English feed sentences and push batch text (docs/API.md "문장"), the only place the server renders words, so Phase 9
 * can localize per recipient here. [names] maps member id → name; [me] is the viewer's member id.
 */
object ActivityText {
    const val MAX_TITLE = 100
    const val MAX_BODY = 200
    private const val DOT = " · "
    private const val ARROW = " → "

    private fun quote(s: Any?) = "“${s ?: ""}”"

    private fun onOff(v: Any?) = if (v == true) "on" else "off"

    /**
     * `category Dining out → General`, each side as the app shows a stored value (`labelOf`: the label, `Entertainment -
     * Other`, else `General`); bare `category` when both show the same (null → `uncategorized.general`).
     */
    private fun category(from: Any?, to: Any?): String {
        fun label(raw: Any?) = Categories.label(Categories.keyForLabel(raw as String?)) ?: "General"
        return if (label(from) == label(to)) "category" else "category ${label(from)}$ARROW${label(to)}"
    }

    /** Phase 8 frequency words (Phase 9 translates them). */
    private fun repeats(frequency: String?) = if (frequency == "biweekly") "every 2 weeks" else frequency ?: ""

    private fun who(id: String?, names: Map<String, String>, me: String?, start: Boolean = false): String = when {
        id != null && id == me -> if (start) "You" else "you"
        id == null || id !in names -> if (start) "Someone" else "someone"
        else -> names.getValue(id)
    }

    fun sentence(item: ActivityItem, names: Map<String, String>, me: String?): String {
        fun who(id: String?, start: Boolean = false) = who(id, names, me, start)
        fun money(minor: Any?, currency: String? = item.currency) = Money.display((minor as Number?)?.toLong() ?: 0, currency ?: "")
        val a = who(item.actorMemberId, start = true)
        val delta = item.myDelta ?: 0
        val owes = when {
            delta < 0 -> "${DOT}you owe ${money(-delta)}"
            delta > 0 -> "${DOT}${if (item.refund == true) "you get back" else "you lent"} ${money(delta)}"
            else -> ""
        }
        fun changes(): String {
            fun changed(field: String) = item.changes.any { it.field == field }
            val amountChanged = changed("amount")
            val fromCurrency = item.changes.firstOrNull { it.field == "currency" }?.from as String? ?: item.currency
            return item.changes.mapNotNull { c ->
                when (c.field) {
                    "description" -> "description ${quote(c.from)}$ARROW${quote(c.to)}"
                    "amount" -> "${money(c.from, fromCurrency)}$ARROW${money(c.to)}"
                    "currency" -> "currency ${c.from}$ARROW${c.to}"
                    "fxRateToDefault" -> "exchange rate"
                    "paidBy" -> "paid by ${who(c.from as String?)}$ARROW${who(c.to as String?)}"
                    "payers" -> "payers" // listed only when several people paid before or after (Activity.expenseChanges)
                    "refund" -> "refund " + onOff(c.to)
                    "date" -> "date ${c.from}$ARROW${c.to}"
                    "category" -> category(c.from, c.to)
                    "shares" -> if (amountChanged) null else "split" // a new amount always changes the split
                    "split" -> if (amountChanged || changed("shares")) null else "split" // the split mode alone
                    else -> c.field // notes
                }
            }.joinToString(", ")
        }
        return when (item.kind) {
            "group_created" -> "$a created the group ${quote(item.name)}"
            "group_updated" -> "$a changed the group: " + item.changes.joinToString(", ") {
                when (it.field) {
                    "name" -> "name ${quote(it.from)}$ARROW${quote(it.to)}"
                    "simplifyDebts" -> "simplify debts " + onOff(it.to)
                    "defaultSplit" -> "default split"
                    else -> "currency ${it.from}$ARROW${it.to}"
                }
            }
            "member_added" -> "$a added ${who(item.memberId)}"
            "member_joined" -> "${who(item.memberId, start = true)} joined"
            "member_removed" -> "$a removed ${who(item.memberId)}"
            "member_left" -> "${who(item.memberId, start = true)} left the group"
            "friend_added" -> "$a added ${who(item.memberId)} as a friend"
            "expense_added" -> "$a added ${if (item.refund == true) "a refund " else ""}${quote(item.description)}$DOT${money(item.amount)}$owes"
            "expense_repeated" -> // Phase 8: added by Evensies, so no actor
                "${if (item.refund == true) "A refund " else ""}${quote(item.description)}$DOT${money(item.amount)} was added (repeats ${repeats(item.frequency)})$owes"
            "expense_updated" -> "$a changed ${quote(item.description)}: ${changes()}"
            "expense_deleted" -> "$a deleted ${quote(item.description)}"
            "expense_restored" -> "$a restored ${quote(item.description)}"
            "expense_moved" -> "$a moved ${quote(item.description)} to another group" // the target may be a group the viewer isn't in
            "comment_added" -> if (item.paymentId != null) {
                "$a commented on a payment of ${money(item.amount)} from ${who(item.fromMember)} to ${who(item.toMember)}: ${item.text}"
            } else {
                "$a commented on ${quote(item.description)}: ${item.text}"
            }
            "payment_added" -> "${who(item.fromMember, start = true)} paid ${who(item.toMember)} ${money(item.amount)}" +
                if (item.status == "sent") "${DOT}waiting for ${who(item.toMember)} to confirm" else ""
            "payment_confirmed" -> "$a confirmed receiving ${money(item.amount)} from ${who(item.fromMember)}"
            "payment_deleted" -> "$a deleted a payment of ${money(item.amount)} from ${who(item.fromMember)} to ${who(item.toMember)}"
            "payment_edited" -> "$a edited a payment of ${money(item.amount)} from ${who(item.fromMember)} to ${who(item.toMember)}"
            "payment_restored" -> "$a restored a payment of ${money(item.amount)} from ${who(item.fromMember)} to ${who(item.toMember)}"
            "receipt_added" -> "$a added a receipt to ${quote(item.description)}"
            "receipt_removed" -> "$a removed a receipt from ${quote(item.description)}"
            "recurrence_created" -> "$a set ${quote(item.description)} to repeat ${repeats(item.frequency)}"
            "recurrence_updated" -> "$a changed future ${quote(item.description)}: ${changes()}"
            "recurrence_deleted" -> "$a stopped ${quote(item.description)} repeating"
            else -> "$a made a change"
        }
    }

    /** Reminder push (docs/API.md "리마인더"): [amounts] currency → minor units, sorted by currency; [from] the sender's name. */
    fun reminder(from: String, amounts: List<Pair<String, Long>>): Pair<String, String> {
        val a = from.ifBlank { "Someone" }
        val m = amounts.map { (c, v) -> Money.display(v, c) }
        val owed = when (m.size) {
            1 -> m[0]
            2 -> "${m[0]} and ${m[1]}"
            else -> "${m[0]}, ${m[1]} and more"
        }
        return "$a sent a reminder".clip(MAX_TITLE) to "You owe $a $owed.".clip(MAX_BODY)
    }

    /** Visible push title: the group name (a friend group: the other member's name), clipped like [body]. */
    fun title(groupName: String): String = groupName.clip(MAX_TITLE)

    /**
     * Visible push body: the sentence for one item, a batch sentence for more, clipped to [MAX_BODY] chars so a long
     * comment or description never pushes the message past FCM/APNs' 4096-byte limit (which would drop the sync data too).
     * A `receipt_added` on an expense added in the same batch is left out first (Phase 7: saving a scanned expense is
     * one sentence), and so is a `recurrence_*` item whose series has an `expense_*` item by the same actor in the batch
     * (Phase 8: starting, editing ahead or deleting-and-stopping a series is one save, the expense's sentence; another
     * member's stop or a repeat by Evensies next to it stays); the feed keeps both.
     */
    fun body(items: List<ActivityItem>, names: Map<String, String>, me: String?): String {
        val added = items.filter { it.kind == "expense_added" }.mapTo(HashSet()) { it.expenseId }
        val series = items.filter { it.kind.startsWith("expense_") }.mapNotNullTo(HashSet()) { i -> i.recurrenceId?.let { it to i.actorMemberId } }
        val shown = items.filterNot {
            (it.kind == "receipt_added" && it.expenseId in added) || (it.kind.startsWith("recurrence_") && (it.recurrenceId to it.actorMemberId) in series)
        }
        return batch(shown, names, me).clip(MAX_BODY)
    }

    private fun batch(items: List<ActivityItem>, names: Map<String, String>, me: String?): String {
        if (items.size == 1) return sentence(items[0], names, me)
        val actors = items.map { it.actorMemberId }.distinct() // [null] = one unknown actor ("Someone")
        if (actors.size > 1) return "${items.size} new changes"
        val a = who(actors[0], names, me, start = true)
        return when (items.map { it.kind }.distinct().singleOrNull()) {
            "expense_added" -> "$a added ${items.size} expenses"
            "comment_added" -> "$a added ${items.size} comments"
            "expense_repeated" -> "${items.size} repeating expenses were added" // no actor (Evensies), never "Someone"
            else -> "$a made ${items.size} changes"
        }
    }
}

/** At most [max] UTF-16 chars, ending in "…" when cut; never splits a surrogate pair. */
fun String.clip(max: Int): String {
    if (length <= max) return this
    val end = if (Character.isHighSurrogate(this[max - 2])) max - 2 else max - 1
    return substring(0, end) + "…"
}

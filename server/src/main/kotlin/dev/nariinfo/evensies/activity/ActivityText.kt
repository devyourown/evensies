package dev.nariinfo.evensies.activity

import dev.nariinfo.evensies.common.Strings
import dev.nariinfo.evensies.export.Categories
import dev.nariinfo.evensies.money.Money

/**
 * Feed sentences and push batch text (docs/API.md "문장", "문장 만들기"), rendered per language from strings.json, the
 * only place the server renders activity words. [names] maps member id → name; [me] is the viewer's member id; [lang]
 * a language code (one strings.json lacks renders English).
 */
object ActivityText {
    const val MAX_TITLE = 100
    const val MAX_BODY = 200

    /** One render: who is who and in which language; [friend]: the group is a friend group (Phase 6). */
    private class Render(lang: String, val names: Map<String, String>, val me: String?, val friend: Boolean = false) {
        val lang = Strings.lang(lang)

        fun s(vararg path: String): String = Strings.get(lang, *path) ?: ""

        /** The viewer (`words.you`) or an unknown member (`words.someone`) rather than a name. */
        fun isWord(id: String?) = id == null || id == me || id !in names

        fun who(id: String?): String = when {
            id != null && id == me -> s("words", "you")
            id == null || id !in names -> s("words", "someone")
            else -> names.getValue(id)
        }

        fun money(minor: Any?, currency: String?) = Money.display((minor as Number?)?.toLong() ?: 0, currency ?: "", lang)

        /** `words.groupType`; an unknown type reads as Other (rule 17). */
        fun groupType(type: String?) = type?.let { Strings.get(lang, "words", "groupType", it) } ?: s("words", "groupType", "other")
    }

    /** The member a kind is about (`self` variant) and the one it is done to (`you` variant), docs/API.md "문장 만들기" 2. */
    private fun subject(i: ActivityItem) = when (i.kind) {
        "member_joined", "member_left" -> i.memberId
        "payment_added" -> i.fromMember
        else -> i.actorMemberId
    }

    private fun target(i: ActivityItem) = when (i.kind) {
        "member_added", "member_removed", "friend_added" -> i.memberId
        "payment_added" -> i.toMember
        "payment_confirmed" -> i.fromMember
        else -> null
    }

    /**
     * The template key: refunds, payment comments, a friend group's delete/restore (`friend_deleted`, `friend_restored`:
     * its name is internal) and kinds `en` lacks (`unknown`) have their own.
     */
    private fun key(i: ActivityItem, friend: Boolean): String {
        val k = when {
            i.refund == true && (i.kind == "expense_added" || i.kind == "expense_repeated") -> i.kind + "_refund"
            i.kind == "comment_added" && i.paymentId != null -> "comment_added_payment"
            friend && (i.kind == "group_deleted" || i.kind == "group_restored") -> i.kind.replace("group_", "friend_")
            else -> i.kind
        }
        return if (Strings.get("en", "activity", k, "other") != null) k else "unknown"
    }

    fun sentence(item: ActivityItem, names: Map<String, String>, me: String?, lang: String = "en", friend: Boolean = false): String =
        sentence(item, Render(lang, names, me, friend))

    private fun sentence(item: ActivityItem, r: Render): String {
        val key = key(item, r.friend)
        fun viewer(id: String?) = id != null && id == r.me
        val variant = when {
            viewer(subject(item)) && Strings.get("en", "activity", key, "self") != null -> "self"
            viewer(target(item)) && Strings.get("en", "activity", key, "you") != null -> "you"
            else -> "other"
        }
        val members = mapOf("A" to item.actorMemberId, "member" to item.memberId, "from" to item.fromMember, "to" to item.toMember)
        val values = members.mapValues { r.who(it.value) } + mapOf(
            "name" to (item.name ?: ""), "description" to (item.description ?: ""), "text" to (item.text ?: ""),
            "amount" to r.money(item.amount, item.currency),
            "frequency" to (item.frequency?.let { Strings.get(r.lang, "words", "frequency", it) ?: it } ?: ""),
            "changes" to changes(item, r),
        )
        val main = Strings.fill(r.s("activity", key, variant), values, members.filterValues(r::isWord).keys)
        val delta = item.myDelta ?: 0
        val tails = listOfNotNull(
            when {
                item.kind != "expense_added" && item.kind != "expense_repeated" || delta == 0L -> null
                delta < 0 -> Strings.fill(r.s("suffix", "owe"), mapOf("amount" to r.money(-delta, item.currency)))
                else -> Strings.fill(r.s("suffix", if (item.refund == true) "getBack" else "lent"), mapOf("amount" to r.money(delta, item.currency)))
            },
            if (item.kind == "payment_added" && item.status == "sent") {
                Strings.fill(r.s("suffix", "waiting", if (viewer(item.toMember)) "you" else "other"), mapOf("to" to r.who(item.toMember)))
            } else null,
        )
        return (listOf(main) + tails).joinToString(r.s("words", "dot"))
    }

    /** `{changes}`: one label per change in order, joined; an unknown field adds `changes.other` once, and so does none. */
    private fun changes(item: ActivityItem, r: Render): String {
        fun changed(field: String) = item.changes.any { it.field == field }
        fun label(key: String, from: Any?, to: Any?) = Strings.fill(r.s("changes", key), mapOf("from" to (from?.toString() ?: ""), "to" to (to?.toString() ?: "")))
        val amountChanged = changed("amount")
        val fromCurrency = item.changes.firstOrNull { it.field == "currency" }?.from as String? ?: item.currency
        val other = r.s("changes", "other")
        var unknown = false
        val labels = item.changes.mapNotNull { c ->
            when (c.field) {
                "name" -> label("name", c.from, c.to) // group_updated
                "defaultCurrency" -> label("currency", c.from, c.to) // group_updated
                "simplifyDebts" -> r.s("changes", if (c.to == true) "simplifyDebtsOn" else "simplifyDebtsOff") // group_updated
                "defaultSplit" -> r.s("changes", "defaultSplit") // group_updated
                "type" -> label("type", null, r.groupType(c.to as String?)) // group_updated
                "coverImageId" -> r.s("changes", "coverImageId") // group_updated
                "description" -> label("description", c.from, c.to)
                "amount" -> label("amount", r.money(c.from, fromCurrency), r.money(c.to, item.currency))
                "currency" -> label("currency", c.from, c.to)
                "fxRateToDefault" -> r.s("changes", "fxRateToDefault")
                "paidBy" -> label("paidBy", r.who(c.from as String?), r.who(c.to as String?)) // names, never upper-cased
                "payers" -> r.s("changes", "payers") // listed only when several people paid before or after (Activity.expenseChanges)
                "refund" -> r.s("changes", if (c.to == true) "refundOn" else "refundOff")
                "date" -> label("date", c.from, c.to)
                "category" -> category(c.from, c.to, r)
                "shares" -> if (amountChanged) null else r.s("changes", "split") // a new amount always changes the split
                "split" -> if (amountChanged || changed("shares")) null else r.s("changes", "split") // the split mode alone
                "notes" -> r.s("changes", "notes")
                else -> if (unknown) null else other.also { unknown = true }
            }
        }
        return labels.ifEmpty { listOf(other) }.joinToString(r.s("changes", "joiner"))
    }

    /**
     * `category Dining out → General`, each side as the app shows a stored value (`labelOf` in the viewer's language:
     * `categories[key]`, `*.other` as `words.categoryOther`, anything else General); `categorySame` when both read the
     * same (null → `uncategorized.general`).
     */
    private fun category(from: Any?, to: Any?, r: Render): String {
        fun label(raw: Any?): String {
            val key = Categories.keyForLabel(raw as String?) ?: "uncategorized.general"
            return if (key.endsWith(".other")) Strings.fill(r.s("words", "categoryOther"), mapOf("parent" to r.s("categories", key.substringBefore('.'))))
            else r.s("categories", key)
        }
        val (a, b) = label(from) to label(to)
        return if (a == b) r.s("changes", "categorySame") else Strings.fill(r.s("changes", "category"), mapOf("from" to a, "to" to b))
    }

    /**
     * Reminder push (docs/API.md "리마인더") in the recipient's [lang]: [amounts] currency → minor units, sorted by
     * currency; [from] the sender's name (blank: `words.someone`, upper-cased only at the start).
     */
    fun reminder(from: String, amounts: List<Pair<String, Long>>, lang: String = "en"): Pair<String, String> {
        val r = Render(lang, emptyMap(), null)
        val a = from.ifBlank { r.s("words", "someone") }
        val words = if (from.isBlank()) setOf("A") else emptySet()
        val m = amounts.map { (c, v) -> Money.display(v, c, r.lang) }
        val owed = when (m.size) {
            1 -> m[0]
            2 -> Strings.fill(r.s("remind", "two"), mapOf("a" to m[0], "b" to m[1]))
            else -> Strings.fill(r.s("remind", "more"), mapOf("a" to m[0], "b" to m[1]))
        }
        return Strings.fill(r.s("remind", "title"), mapOf("A" to a), words).clip(MAX_TITLE) to
            Strings.fill(r.s("remind", "body"), mapOf("A" to a, "amounts" to owed), words).clip(MAX_BODY)
    }

    /** Visible push title: the group name (a friend group: the other member's name), clipped like [body]. */
    fun title(groupName: String): String = groupName.clip(MAX_TITLE)

    /**
     * Visible push body in the recipient's [lang]: the sentence for one item, a batch sentence for more, clipped to
     * [MAX_BODY] chars so a long comment or description never pushes the message past FCM/APNs' 4096-byte limit (which
     * would drop the sync data too). A `receipt_added` on an expense added in the same batch is left out first (Phase 7:
     * saving a scanned expense is one sentence), and so is a `recurrence_*` item whose series has an `expense_*` item by
     * the same actor in the batch (Phase 8: starting, editing ahead or deleting-and-stopping a series is one save, the
     * expense's sentence; another member's stop or a repeat by Evensies next to it stays); the feed keeps both.
     */
    fun body(items: List<ActivityItem>, names: Map<String, String>, me: String?, lang: String = "en", friend: Boolean = false): String {
        val added = items.filter { it.kind == "expense_added" }.mapTo(HashSet()) { it.expenseId }
        val series = items.filter { it.kind.startsWith("expense_") }.mapNotNullTo(HashSet()) { i -> i.recurrenceId?.let { it to i.actorMemberId } }
        val shown = items.filterNot {
            (it.kind == "receipt_added" && it.expenseId in added) || (it.kind.startsWith("recurrence_") && (it.recurrenceId to it.actorMemberId) in series)
        }
        return batch(shown, Render(lang, names, me, friend)).clip(MAX_BODY)
    }

    private fun batch(items: List<ActivityItem>, r: Render): String {
        if (items.size == 1) return sentence(items[0], r)
        val n = mapOf("n" to items.size.toString())
        val actors = items.map { it.actorMemberId }.distinct() // [null] = one unknown actor ("Someone")
        if (actors.size > 1) return Strings.fill(r.s("batch", "mixed"), n)
        val key = when (items.map { it.kind }.distinct().singleOrNull()) {
            "expense_added" -> "expenses"
            "comment_added" -> "comments"
            "expense_repeated" -> "repeats" // no actor (Evensies), never "Someone"
            else -> "changes"
        }
        return Strings.fill(r.s("batch", key), n + ("A" to r.who(actors[0])), if (r.isWord(actors[0])) setOf("A") else emptySet())
    }
}

/** At most [max] UTF-16 chars, ending in "…" when cut; never splits a surrogate pair. */
fun String.clip(max: Int): String {
    if (length <= max) return this
    val end = if (Character.isHighSurrogate(this[max - 2])) max - 2 else max - 1
    return substring(0, end) + "…"
}

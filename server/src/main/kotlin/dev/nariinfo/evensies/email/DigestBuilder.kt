package dev.nariinfo.evensies.email

import dev.nariinfo.evensies.activity.ActivityItem
import dev.nariinfo.evensies.activity.ActivityText
import dev.nariinfo.evensies.common.Strings
import dev.nariinfo.evensies.money.Balances
import dev.nariinfo.evensies.money.Money
import dev.nariinfo.evensies.sync.GroupState
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalTime
import java.time.YearMonth
import java.time.ZoneOffset
import java.time.format.TextStyle
import java.time.temporal.TemporalAdjusters
import java.util.Locale

/**
 * One group in a digest, in the order the email lists it. [items]: the window's feed items for the recipient (member
 * [me]), newest first, already without the recipient's own and blocked people's events. [balances]: the recipient's
 * balance per currency (empty for a deleted group); null when it can't be computed (a money function not ported to Kotlin yet).
 */
data class DigestGroup(
    val name: String,
    val items: List<ActivityItem>,
    val names: Map<String, String>,
    val me: String?,
    val deleted: Boolean = false,
    val balances: Map<String, Long>? = emptyMap(),
    val friend: Boolean = false,
)

/** The email summary (docs/API.md "Summary emails"): pure, checked by server/src/test/resources/digest-cases.json. */
object DigestBuilder {
    /**
     * A group's section from its state after the whole log and the window's [items] (newest first) for member [me].
     * Balances per currency bucket (Phase 6 port); a `NotImplementedError` (a money function whose Kotlin port hasn't
     * landed) leaves them null, so the section is left out and the lines still go.
     */
    fun group(state: GroupState, items: List<ActivityItem>, me: String): DigestGroup {
        val balances = if (state.deleted) emptyMap() else try {
            Balances.ofGroup(state).byCurrency.mapValues { it.value[me] ?: 0L }
        } catch (_: NotImplementedError) {
            null
        }
        return DigestGroup(groupName(state, me), items, state.members.mapValues { it.value.name }, me, state.deleted, balances, state.kind == "friend")
    }

    /** The group as [me] sees it: a friend group is named after the other member (like push titles). */
    fun groupName(state: GroupState, me: String): String =
        if (state.kind == "friend") state.members.values.firstOrNull { it.id != me }?.name ?: state.name.orEmpty() else state.name.orEmpty()

    const val MAX_PER_GROUP = 10
    const val MAX_LINES = 30
    private val ADDED = setOf("expense_added", "expense_repeated")
    private val GONE = setOf("expense_deleted", "expense_moved")

    /**
     * [mode] daily, weekly or monthly; [auto] = chosen by "auto" (the reason line says why). [month]: the month a monthly
     * summary is about. Null when there is nothing to say: daily and weekly need a line, monthly a line or a balance.
     */
    fun build(
        name: String, lang: String, mode: String, auto: Boolean, groups: List<DigestGroup>, unsubscribeUrl: String, month: YearMonth,
    ): Email? {
        val l = Strings.lang(lang)
        val sections = groups.map { g -> g to lines(g, l) }.filter { it.second.isNotEmpty() }
        val total = sections.sumOf { it.second.size }
        val balances = if (groups.any { !it.deleted && it.balances == null }) emptyList() else groups.filterNot { it.deleted }.flatMap { g ->
            g.balances.orEmpty().filterValues { it != 0L }.map { (currency, b) ->
                "• " + EmailTemplates.fill(l, arrayOf("digest", if (b < 0) "owe" else "owed"), "group" to EmailTemplates.clean(g.name, EmailTemplates.MAX_NAME),
                    "amount" to Money.display(kotlin.math.abs(b), currency, l))
            }
        }
        if (total == 0 && (mode != "monthly" || balances.isEmpty())) return null

        val body = StringBuilder()
        var room = MAX_LINES
        for ((g, lines) in sections) {
            val group = EmailTemplates.clean(g.name, EmailTemplates.MAX_NAME)
            val shown = lines.take(minOf(MAX_PER_GROUP, room))
            room -= shown.size
            body.append(group).append('\n')
            shown.forEach { body.append("• ").append(it).append('\n') }
            if (lines.size > shown.size) {
                body.append(EmailTemplates.fill(l, arrayOf("digest", "more"), "n" to (lines.size - shown.size).toString(), "group" to group)).append('\n')
            }
            body.append('\n')
        }
        if (balances.isNotEmpty()) {
            body.append(EmailTemplates.s(l, "digest", "balances")).append('\n')
            balances.forEach { body.append(it).append('\n') }
            body.append('\n')
        }
        body.append(EmailTemplates.s(l, "digest", "open"))
        val reason = EmailTemplates.s(l, "digest", if (auto) (if (mode == "daily") "reasonAuto" else "reasonAutoMonthly") else "reason${mode.replaceFirstChar(Char::uppercase)}")
        val footer = reason + "\n" + EmailTemplates.fill(l, arrayOf("digest", "unsubscribe"), "url" to unsubscribeUrl)
        return Email(subject(l, mode, sections.map { it.first.name to it.second.size }, month), EmailTemplates.compose(l, name, body.toString(), footer), unsubscribeUrl)
    }

    private fun subject(l: String, mode: String, sections: List<Pair<String, Int>>, month: YearMonth): String {
        if (mode == "monthly") {
            val locale = Locale.forLanguageTag(l)
            return EmailTemplates.fill(l, arrayOf("digest", "subjectMonthly"), "month" to month.month.getDisplayName(TextStyle.FULL_STANDALONE, locale), "year" to month.year.toString())
        }
        val n = sections.sumOf { it.second }
        val group = EmailTemplates.clean(sections.first().first, EmailTemplates.MAX_NAME)
        val key = when {
            sections.size == 2 -> "subjectGroupsOne"
            sections.size > 2 -> "subjectGroups"
            n == 1 -> "subjectOne"
            else -> "subjectMany"
        }
        return EmailTemplates.fill(l, arrayOf("digest", key), "n" to n.toString(), "group" to group, "k" to (sections.size - 1).toString())
    }

    /**
     * The group's sentences, newest first: a deleted group only its `group_deleted` lines; an expense added and deleted
     * inside the window drops out with everything about it; kinds without a sentence are dropped.
     */
    private fun lines(g: DigestGroup, l: String): List<String> {
        val items = if (g.deleted) g.items.filter { it.kind == "group_deleted" } else g.items
        val added = items.filter { it.kind in ADDED }.mapNotNull { it.expenseId }.toSet()
        val gone = items.filter { it.kind in GONE }.mapNotNull { it.expenseId }.filter { it in added }.toSet()
        val names = g.names.mapValues { EmailTemplates.clean(it.value, EmailTemplates.MAX_NAME) }
        return items.filter { it.expenseId == null || it.expenseId !in gone }
            .filter { Strings.get("en", "activity", it.kind, "other") != null }
            .map { i ->
                val clean = i.copy(text = i.text?.let { EmailTemplates.clean(it, EmailTemplates.MAX_COMMENT) }, description = i.description?.let(EmailTemplates::clean),
                    name = i.name?.let { EmailTemplates.clean(it, EmailTemplates.MAX_NAME) })
                ActivityText.sentence(clean, names, g.me, l, g.friend)
            }
    }

    /**
     * When the next summary is due after [last] (UTC; due means now >= this, so missed runs catch up): daily the next
     * 17:00, weekly the next Monday 17:00, monthly the next 1st at 09:00. ponytail: UTC only (Phase 8 stores a zone
     * per series, not per user); add `users.time_zone` if people ask.
     */
    fun nextDue(last: Instant, mode: String): Instant {
        val t = last.atOffset(ZoneOffset.UTC)
        val next = when (mode) {
            "daily" -> t.with(LocalTime.of(17, 0)).let { if (it.isAfter(t)) it else it.plusDays(1) }
            "weekly" -> t.with(TemporalAdjusters.nextOrSame(DayOfWeek.MONDAY)).with(LocalTime.of(17, 0)).let { if (it.isAfter(t)) it else it.plusWeeks(1) }
            else -> t.withDayOfMonth(1).with(LocalTime.of(9, 0)).let { if (it.isAfter(t)) it else it.plusMonths(1) }
        }
        return next.toInstant()
    }
}

package dev.nariinfo.evensies.email

import dev.nariinfo.evensies.activity.clip
import dev.nariinfo.evensies.common.Strings
import dev.nariinfo.evensies.money.Money
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

/**
 * Plain-text emails per kind (docs/API.md "이메일 문구"), from strings.json `email.*` in the reader's language (one
 * strings.json lacks is English, leaf by leaf). Pure: the caller passes links and names. User text loses CR/LF; names
 * are cut to 40 characters and comments to 80 ([clean]).
 */
object EmailTemplates {
    const val MAX_NAME = 40
    const val MAX_COMMENT = 80

    /** User text in a header or a line: no CR/LF, at most [max] chars ("…" when cut). */
    fun clean(s: String?, max: Int = Int.MAX_VALUE): String = (s ?: "").replace(Regex("[\\r\\n]+"), " ").trim().clip(max)

    internal fun s(lang: String, vararg path: String): String = Strings.get(Strings.lang(lang), "email", *path)!!

    internal fun fill(lang: String, key: Array<String>, vararg values: Pair<String, String>) = Strings.fill(s(lang, *key), values.toMap())

    /** "Hi {name}," (just "Hi," for an empty name), a blank line, the body, then the "—" footer. */
    internal fun compose(lang: String, name: String, body: String, footer: String): String {
        val n = clean(name, MAX_NAME)
        val hi = if (n.isEmpty()) s(lang, "hiNoName") else Strings.fill(s(lang, "hi"), mapOf("name" to n))
        return "$hi\n\n$body\n\n—\n$footer"
    }

    fun loginCode(lang: String, code: String) =
        Email(fill(lang, arrayOf("code", "subject"), "code" to code), fill(lang, arrayOf("code", "login"), "code" to code))

    fun changeCode(lang: String, code: String) =
        Email(fill(lang, arrayOf("code", "subject"), "code" to code), fill(lang, arrayOf("code", "change"), "code" to code))

    /** [code] the group's invite code as shown (`ABC-DEF`); [link] `{publicUrl}/j/{code}?m={memberId}`. */
    fun invite(lang: String, reminder: Boolean, inviter: String, group: String, name: String, link: String, code: String, unsubscribeUrl: String): Email {
        val v = arrayOf("inviter" to clean(inviter, MAX_NAME), "group" to clean(group, MAX_NAME))
        val subject = fill(lang, arrayOf("invite", if (reminder) "reminderSubject" else "subject"), *v)
        val body = fill(lang, arrayOf("invite", "body"), *v, "link" to link, "code" to code)
        val footer = fill(lang, arrayOf("invite", "footer"), *v, "url" to unsubscribeUrl)
        return Email(subject, compose(lang, name, body, footer), unsubscribeUrl)
    }

    /** [amount]/[share] in [currency] minor units; [creator] blank = `words.someone`; [byRecipient]: the reader made the series. */
    fun recurringReminder(
        lang: String, name: String, description: String, amount: Long, share: Long, currency: String, date: LocalDate,
        group: String, frequency: String, creator: String, unsubscribeUrl: String, byRecipient: Boolean = false,
    ): Email {
        val l = Strings.lang(lang)
        val v = arrayOf(
            "description" to clean(description), "amount" to Money.display(amount, currency, l), "share" to Money.display(share, currency, l),
            "date" to date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(Locale.forLanguageTag(l))),
            "group" to clean(group, MAX_NAME), "frequency" to (Strings.get(l, "words", "frequency", frequency) ?: frequency),
            "creator" to clean(creator, MAX_NAME).ifEmpty { Strings.get(l, "words", "someone")!! },
        )
        val subject = fill(lang, arrayOf("recurring", "subject"), *v)
        val body = fill(lang, arrayOf("recurring", "body"), *v)
        val footer = fill(lang, arrayOf("recurring", if (byRecipient) "footerSelf" else "footer"), *v, "url" to unsubscribeUrl)
        return Email(subject, compose(lang, name, body, footer), unsubscribeUrl)
    }
}

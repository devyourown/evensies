package dev.nariinfo.evensies.email

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.AppProperties
import jakarta.mail.SendFailedException
import jakarta.mail.internet.AddressException
import jakarta.mail.internet.InternetAddress
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.ObjectProvider
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Condition
import org.springframework.context.annotation.ConditionContext
import org.springframework.context.annotation.Conditional
import org.springframework.context.annotation.Configuration
import org.springframework.core.type.AnnotatedTypeMetadata
import org.springframework.http.HttpStatus
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.mail.MailException
import org.springframework.mail.MailSendException
import org.springframework.mail.javamail.JavaMailSender
import org.springframework.mail.javamail.JavaMailSenderImpl
import org.springframework.mail.javamail.MimeMessageHelper
import org.springframework.stereotype.Component
import java.time.Clock
import java.time.Duration
import java.time.ZoneOffset
import java.util.UUID

/** One plain-text message; [unsubscribeUrl] adds RFC 8058 one-click headers (invites, digests, recurring reminders). */
data class Email(val subject: String, val text: String, val unsubscribeUrl: String? = null)

/** `EVENSIES_SMTP_HOST` is set (not blank). Not `spring.mail.host` / `@ConditionalOnProperty`: both treat an empty value as present. */
class SmtpConfigured : Condition {
    override fun matches(context: ConditionContext, metadata: AnnotatedTypeMetadata) =
        !context.environment.getProperty("evensies.email.smtp-host").isNullOrBlank()
}

@Configuration
class EmailConfig {
    @Bean
    fun clock(): Clock = Clock.systemUTC()

    /** Connect, read and write time out after 10 s; [AppProperties.Email.smtpTls] picks the transport security. */
    @Bean
    @Conditional(SmtpConfigured::class)
    fun javaMailSender(props: AppProperties): JavaMailSender = JavaMailSenderImpl().apply {
        val e = props.email
        host = e.smtpHost.trim()
        port = e.smtpPort
        if (e.smtpUser.isNotBlank()) {
            username = e.smtpUser
            password = e.smtpPassword
        }
        defaultEncoding = "UTF-8"
        val p = javaMailProperties
        p["mail.smtp.auth"] = e.smtpUser.isNotBlank().toString()
        for (k in listOf("connectiontimeout", "timeout", "writetimeout")) p["mail.smtp.$k"] = "10000"
        when (e.smtpTls) {
            "starttls" -> { p["mail.smtp.starttls.enable"] = "true"; p["mail.smtp.starttls.required"] = "true" }
            "ssl" -> p["mail.smtp.ssl.enable"] = "true"
            "none" -> Unit
            else -> throw IllegalArgumentException("EVENSIES_SMTP_TLS must be starttls, ssl or none, not ${e.smtpTls}")
        }
    }
}

/**
 * The only way out for email (docs/API.md "메일러"). [send] gates, in order: suppression (codes skip it), the daily budget,
 * an `email_log` row (hashed address), then the send. A synchronous 5xx (`SendFailedException.invalidAddresses`) adds a
 * `bounce` suppression and is 400 EMAIL_REJECTED; any other failure is 503 EMAIL_UNAVAILABLE.
 */
@Component
class Mailer(
    private val sender: ObjectProvider<JavaMailSender>,
    private val jdbc: JdbcClient,
    private val props: AppProperties,
    private val clock: Clock,
) {
    private val log = LoggerFactory.getLogger(javaClass)

    enum class Result { SENT, SUPPRESSED, OVER_BUDGET }

    val enabled: Boolean get() = props.email.smtpHost.isNotBlank() && sender.ifAvailable != null

    fun requireEnabled() {
        if (!enabled) throw ApiException.badRequest("EMAIL_NOT_CONFIGURED", "Email isn't set up on this server")
    }

    fun isSuppressed(email: String): Boolean =
        jdbc.sql("SELECT EXISTS (SELECT 1 FROM email_suppressions WHERE email_hash = :h)").param("h", EmailAddress.hash(email))
            .query(Boolean::class.java).single()

    fun isBounced(email: String): Boolean =
        jdbc.sql("SELECT EXISTS (SELECT 1 FROM email_suppressions WHERE email_hash = :h AND reason = 'bounce')").param("h", EmailAddress.hash(email))
            .query(Boolean::class.java).single()

    /** The first reason stays (an unsubscribe isn't turned into a bounce). */
    fun suppress(hash: String, reason: String) {
        jdbc.sql("INSERT INTO email_suppressions (email_hash, reason) VALUES (:h, :r) ON CONFLICT DO NOTHING").param("h", hash).param("r", reason).update()
    }

    /** A successful code check proves the address works again. */
    fun unsuppress(email: String) {
        jdbc.sql("DELETE FROM email_suppressions WHERE email_hash = :h").param("h", EmailAddress.hash(email)).update()
    }

    /** Rows in the last [window] for [kinds], to this address ([toHash]) or charged to [userId]. */
    fun count(kinds: Collection<String>, window: Duration, toHash: String? = null, userId: UUID? = null): Int = jdbc.sql(
        """
        SELECT count(*) FROM email_log WHERE kind IN (:kinds) AND sent_at > :since
          AND (CAST(:h AS text) IS NULL OR to_hash = :h) AND (CAST(:u AS uuid) IS NULL OR user_id = :u)
        """
    ).param("kinds", kinds).param("since", clock.instant().minus(window).atOffset(ZoneOffset.UTC)).param("h", toHash).param("u", userId)
        .query(Int::class.java).single()

    /**
     * `EVENSIES_EMAIL_DAILY_LIMIT` over a rolling 24 h (0 = none): digests and recurring reminders stop at 80%, invites
     * at 100%; codes are always sent.
     */
    fun withinBudget(kind: String): Boolean {
        val limit = props.email.dailyLimit
        if (limit <= 0 || kind in CODES) return true
        val used = jdbc.sql("SELECT count(*) FROM email_log WHERE sent_at > :since")
            .param("since", clock.instant().minus(Duration.ofDays(1)).atOffset(ZoneOffset.UTC)).query(Int::class.java).single()
        return used < if (kind in INVITES) limit.toDouble() else limit * 0.8
    }

    /**
     * [chargedUserId]: the inviter for invites, the recipient otherwise. [ref]: what the send was for, stored once it
     * succeeded ([sent]). An address our check passes but JavaMail can't parse (`a,b@x.y`) is 400 VALIDATION, unlogged.
     */
    fun send(kind: String, to: String, chargedUserId: UUID?, email: Email, ref: String? = null): Result {
        requireEnabled()
        val hash = EmailAddress.hash(to)
        if (kind !in CODES && isSuppressed(to)) return Result.SUPPRESSED
        if (!withinBudget(kind)) return Result.OVER_BUDGET
        val mail = sender.getObject()
        val message = mail.createMimeMessage()
        MimeMessageHelper(message, false, "UTF-8").apply {
            setFrom(InternetAddress(props.email.from))
            try {
                setTo(to)
            } catch (_: AddressException) {
                throw ApiException.badRequest("VALIDATION", "That isn't an email address we can send to")
            }
            setSubject(email.subject)
            setText(email.text, false)
        }
        message.setHeader("Auto-Submitted", "auto-generated")
        email.unsubscribeUrl?.let {
            message.setHeader("List-Unsubscribe", "<$it>")
            message.setHeader("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
        }
        val logId = jdbc.sql("INSERT INTO email_log (kind, to_hash, user_id, sent_at) VALUES (:k, :h, :u, :t) RETURNING id")
            .param("k", kind).param("h", hash).param("u", chargedUserId).param("t", clock.instant().atOffset(ZoneOffset.UTC))
            .query(Long::class.java).single()
        try {
            mail.send(message)
        } catch (e: MailException) {
            val rejected = (e as? MailSendException)?.failedMessages?.values.orEmpty()
                .any { generateSequence(it as Throwable?) { t -> t.cause }.any { t -> t is SendFailedException && !t.invalidAddresses.isNullOrEmpty() } }
            if (rejected) {
                suppress(hash, "bounce")
                throw ApiException.badRequest("EMAIL_REJECTED", "The mail server rejected this address")
            }
            log.warn("Sending {} failed: {}", kind, e.toString())
            throw ApiException(HttpStatus.SERVICE_UNAVAILABLE, "EMAIL_UNAVAILABLE", "Email can't be sent right now, try again later")
        }
        if (ref != null) jdbc.sql("UPDATE email_log SET ref = :r WHERE id = :id").param("r", ref).param("id", logId).update()
        return Result.SENT
    }

    /** A [kind] email for [ref] reached [userId] (within the log's 30 days). */
    fun sent(kind: String, userId: UUID, ref: String): Boolean =
        jdbc.sql("SELECT EXISTS (SELECT 1 FROM email_log WHERE kind = :k AND user_id = :u AND ref = :r)")
            .param("k", kind).param("u", userId).param("r", ref).query(Boolean::class.java).single()

    companion object {
        val CODES = setOf("login_code", "change_code")
        val INVITES = setOf("invite", "invite_reminder")
    }
}

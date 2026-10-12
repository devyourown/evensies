package dev.nariinfo.evensies

import jakarta.mail.SendFailedException
import jakarta.mail.internet.InternetAddress
import jakarta.mail.internet.MimeMessage
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Primary
import org.springframework.mail.MailSendException
import org.springframework.mail.javamail.JavaMailSenderImpl
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Replaces SMTP in tests: every message the mailer sends is recorded. An address in [reject] fails like a synchronous
 * 5xx (`SendFailedException.invalidAddresses`); [down] fails like a lost connection.
 */
class CapturingMailSender : JavaMailSenderImpl() {
    data class Mail(val to: String, val subject: String, val text: String, val message: MimeMessage) {
        fun header(name: String): String? = message.getHeader(name, ",")
    }

    val sent = CopyOnWriteArrayList<Mail>()
    val reject: MutableSet<String> = ConcurrentHashMap.newKeySet()
    @Volatile
    var down = false

    override fun doSend(mimeMessages: Array<out MimeMessage>, originalMessages: Array<out Any>?) {
        for (m in mimeMessages) {
            m.saveChanges()
            val to = (m.allRecipients.single() as InternetAddress).address
            if (down) throw MailSendException("Mail server connection failed")
            if (to in reject) throw MailSendException(mapOf<Any, Exception>(m to SendFailedException("550 No such user", null, null, null, arrayOf(InternetAddress(to)))))
            sent += Mail(to, m.subject, m.content as String, m)
        }
    }

    fun to(address: String): List<Mail> = sent.filter { it.to == address }

    /** The 6-digit code in the latest message to [address]. */
    fun code(address: String): String = Regex("\\b\\d{6}\\b").find(to(address).last().text)!!.value
}

/** A clock tests can move: [now] = system time + [offset]. Reset it after a test that moves it. */
class MutableClock : Clock() {
    @Volatile
    var offset: Duration = Duration.ZERO

    override fun instant(): Instant = Instant.now().plus(offset)
    override fun getZone(): ZoneId = ZoneOffset.UTC
    override fun withZone(zone: ZoneId?): Clock = this
}

@TestConfiguration(proxyBeanMethods = false)
class MailCaptureConfiguration {
    @Bean
    @Primary
    fun capturingMailSender() = CapturingMailSender()

    @Bean
    @Primary
    fun mutableClock() = MutableClock()
}

package dev.nariinfo.evensies

import dev.nariinfo.evensies.push.PushSender
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Primary
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

/** Replaces FCM in tests: every message the notifier sends is recorded; tokens in [dead] are reported as no longer valid. */
class CapturingPushSender : PushSender {
    data class Sent(val tokens: List<String>, val title: String?, val body: String?, val data: Map<String, String>)

    val sent = CopyOnWriteArrayList<Sent>()
    val dead: MutableSet<String> = ConcurrentHashMap.newKeySet()

    override fun send(tokens: List<String>, title: String?, body: String?, data: Map<String, String>): List<String> {
        check(tokens.size <= PushSender.MAX_TOKENS) { "FCM rejects multicasts of ${tokens.size} tokens" }
        sent += Sent(tokens, title, body, data)
        return tokens.filter { it in dead }
    }

    fun to(token: String): List<Sent> = sent.filter { token in it.tokens }
}

@TestConfiguration(proxyBeanMethods = false)
class PushCaptureConfiguration {
    @Bean
    @Primary
    fun capturingPushSender() = CapturingPushSender()
}

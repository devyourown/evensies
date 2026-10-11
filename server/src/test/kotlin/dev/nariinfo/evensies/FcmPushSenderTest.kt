package dev.nariinfo.evensies

import com.google.api.client.json.gson.GsonFactory
import com.google.firebase.messaging.MessagingErrorCode
import dev.nariinfo.evensies.push.FcmPushSender
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals

/** The FCM-specific parts that run without credentials: the APNs payload and which tokens count as dead. */
class FcmPushSenderTest {
    private fun json(visible: Boolean, badge: Int? = null) =
        SharedJson.mapper.readTree(GsonFactory.getDefaultInstance().toString(FcmPushSender.apns(visible, "g1", badge)))

    @Test
    fun apnsConfig() {
        assertEquals(
            SharedJson.canon(mapOf("payload" to mapOf("aps" to mapOf("sound" to "default", "thread-id" to "g1")))),
            SharedJson.canon(json(visible = true)),
        )
        // Phase 6: the recipient's unread total on visible pushes
        assertEquals(
            SharedJson.canon(mapOf("payload" to mapOf("aps" to mapOf("sound" to "default", "thread-id" to "g1", "badge" to 3)))),
            SharedJson.canon(json(visible = true, badge = 3)),
        )
        // a reminder: no group, so no thread-id, and no badge
        assertEquals(
            SharedJson.canon(mapOf("payload" to mapOf("aps" to mapOf("sound" to "default")))),
            SharedJson.canon(SharedJson.mapper.readTree(GsonFactory.getDefaultInstance().toString(FcmPushSender.apns(true, null)))),
        )
        assertEquals(
            SharedJson.canon(mapOf(
                "headers" to mapOf("apns-priority" to "5", "apns-push-type" to "background"),
                "payload" to mapOf("aps" to mapOf("content-available" to 1)),
            )),
            SharedJson.canon(json(visible = false)),
        )
    }

    @Test
    fun deadTokens() {
        val tokens = listOf("ok", "gone", "bad", "busy")
        val codes = listOf(null, MessagingErrorCode.UNREGISTERED, MessagingErrorCode.INVALID_ARGUMENT, MessagingErrorCode.UNAVAILABLE)
        assertEquals(listOf("gone", "bad"), FcmPushSender.deadTokens(tokens, codes, successCount = 1))
        // nothing went through: INVALID_ARGUMENT may be the message itself, so only UNREGISTERED is pruned
        assertEquals(listOf("gone"), FcmPushSender.deadTokens(tokens, codes, successCount = 0))
    }
}

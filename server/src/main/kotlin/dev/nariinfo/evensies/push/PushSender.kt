package dev.nariinfo.evensies.push

import com.google.auth.oauth2.GoogleCredentials
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.ApnsConfig
import com.google.firebase.messaging.Aps
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.MessagingErrorCode
import com.google.firebase.messaging.MulticastMessage
import com.google.firebase.messaging.Notification
import dev.nariinfo.evensies.config.AppProperties
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.io.FileInputStream

/** The seam between [PushNotifier] and FCM; tests replace it with a capturing bean. */
interface PushSender {
    /**
     * A visible notification with [data] when [title]/[body] are set, otherwise a data-only message, to at most
     * [MAX_TOKENS] tokens. Returns the tokens FCM reported as no longer valid (the caller deletes them).
     */
    fun send(tokens: List<String>, title: String?, body: String?, data: Map<String, String>): List<String>

    companion object {
        /** FCM's limit for one multicast. */
        const val MAX_TOKENS = 500
    }
}

/** No credentials file → no-op. */
@Component
class FcmPushSender(props: AppProperties) : PushSender {
    private val log = LoggerFactory.getLogger(javaClass)
    private val app: FirebaseApp? = props.fcm.credentialsFile.ifBlank { null }?.let { path ->
        FileInputStream(path).use {
            FirebaseApp.initializeApp(FirebaseOptions.builder().setCredentials(GoogleCredentials.fromStream(it)).build())
        }
    }

    init {
        if (app == null) log.info("FCM push disabled: EVENSIES_FCM_CREDENTIALS_FILE not set")
        else log.info("FCM push enabled with credentials {}", props.fcm.credentialsFile)
    }

    override fun send(tokens: List<String>, title: String?, body: String?, data: Map<String, String>): List<String> {
        val firebase = app ?: return emptyList()
        if (tokens.isEmpty()) return emptyList()
        return try {
            val visible = title != null && body != null
            val message = MulticastMessage.builder().addAllTokens(tokens).putAllData(data).setApnsConfig(apns(visible, data["groupId"]))
            if (visible) message.setNotification(Notification.builder().setTitle(title).setBody(body).build())
            val res = FirebaseMessaging.getInstance(firebase).sendEachForMulticast(message.build())
            val codes = res.responses.map { if (it.isSuccessful) null else it.exception?.messagingErrorCode }
            deadTokens(tokens, codes, res.successCount)
        } catch (e: Exception) {
            log.warn("FCM send failed for group {}: {}", data["groupId"], e.message)
            emptyList()
        }
    }

    companion object {
        /**
         * iOS: visible pushes play the default sound and stack per group; data-only ones are background pushes
         * (content-available, priority 5), without which iOS delivers them only while the app is open.
         */
        fun apns(visible: Boolean, groupId: String?): ApnsConfig =
            if (visible) ApnsConfig.builder().setAps(Aps.builder().setSound("default").setThreadId(groupId).build()).build()
            else ApnsConfig.builder().putHeader("apns-priority", "5").putHeader("apns-push-type", "background")
                .setAps(Aps.builder().setContentAvailable(true).build()).build()

        /**
         * Tokens to delete, given each token's error code (null = sent, or failed without one). UNREGISTERED always;
         * INVALID_ARGUMENT only when another token in the same multicast succeeded, because a bad message (not a bad
         * token) fails every token with INVALID_ARGUMENT and must not wipe all devices.
         */
        fun deadTokens(tokens: List<String>, codes: List<MessagingErrorCode?>, successCount: Int): List<String> =
            tokens.zip(codes).filter { (_, code) ->
                code == MessagingErrorCode.UNREGISTERED || (code == MessagingErrorCode.INVALID_ARGUMENT && successCount > 0)
            }.map { it.first }
    }
}

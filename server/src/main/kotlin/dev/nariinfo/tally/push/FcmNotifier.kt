package dev.nariinfo.tally.push

import com.google.auth.oauth2.GoogleCredentials
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.MulticastMessage
import dev.nariinfo.tally.auth.DeviceRepository
import dev.nariinfo.tally.config.AppProperties
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.io.FileInputStream
import java.util.UUID

/** Sends `{"type":"sync","groupId"}` data messages. No credentials file → no-op. */
@Component
class FcmNotifier(props: AppProperties, private val devices: DeviceRepository) {
    private val log = LoggerFactory.getLogger(javaClass)
    private val app: FirebaseApp? = props.fcm.credentialsFile.ifBlank { null }?.let { path ->
        FileInputStream(path).use {
            FirebaseApp.initializeApp(FirebaseOptions.builder().setCredentials(GoogleCredentials.fromStream(it)).build())
        }
    }

    init {
        if (app == null) log.info("FCM push disabled: TALLY_FCM_CREDENTIALS_FILE not set")
        else log.info("FCM push enabled with credentials {}", props.fcm.credentialsFile)
    }

    fun notifyGroup(groupId: UUID, excludeUserId: UUID) {
        val firebase = app ?: return
        val tokens = devices.fcmTokensForGroup(groupId, excludeUserId)
        if (tokens.isEmpty()) return
        try {
            val message = MulticastMessage.builder().addAllTokens(tokens)
                .putData("type", "sync").putData("groupId", groupId.toString()).build()
            FirebaseMessaging.getInstance(firebase).sendEachForMulticast(message)
        } catch (e: Exception) {
            log.warn("FCM send failed for group {}: {}", groupId, e.message)
        }
    }
}

package dev.nariinfo.evensies.config

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties("evensies")
data class AppProperties(
    val jwtSecret: String = "",
    val publicUrl: String = "http://localhost:8080",
    /** Invite preview/join/landing requests allowed per client IP per minute. */
    val inviteRatePerMinute: Double = 10.0,
    val auth: Auth = Auth(),
    val fcm: Fcm = Fcm(),
    val push: Push = Push(),
) {
    data class Auth(
        val devLogin: Boolean = false,
        val appleClientId: String = "",
        val googleClientIds: List<String> = emptyList(),
    )

    data class Fcm(val credentialsFile: String = "")

    /** [batchSeconds]: minimum gap between visible pushes per recipient and group; changes inside it are batched. */
    data class Push(val batchSeconds: Long = 30)

}

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
) {
    data class Auth(
        val devLogin: Boolean = false,
        val appleClientId: String = "",
        val googleClientIds: List<String> = emptyList(),
    )

    data class Fcm(val credentialsFile: String = "")

}

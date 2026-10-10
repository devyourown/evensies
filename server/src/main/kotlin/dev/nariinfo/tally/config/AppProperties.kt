package dev.nariinfo.tally.config

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties("tally")
data class AppProperties(
    val jwtSecret: String = "",
    val publicUrl: String = "http://localhost:8080",
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

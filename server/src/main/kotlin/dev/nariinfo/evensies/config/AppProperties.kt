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
    val fx: Fx = Fx(),
    /** Uploaded files (avatars; Phase 7 receipts, Phase 10 covers): `EVENSIES_STORAGE_DIR`, `/data` in Docker. */
    val storageDir: String = "./data",
    /** Exact origins allowed to call the API cross-origin (`EVENSIES_CORS_ORIGINS`, development only); empty = no CORS. */
    val corsOrigins: List<String> = emptyList(),
) {
    data class Auth(
        val devLogin: Boolean = false,
        /** iOS bundle id: the `aud` of the app's Apple id tokens. */
        val appleClientId: String = "",
        /** Phase 9: the Services ID web sign-in uses, also accepted as `aud` and shown by GET /info. */
        val appleServicesId: String = "",
        val googleClientIds: List<String> = emptyList(),
        /** Phase 9: the Google web OAuth client id, also accepted as `aud` and shown by GET /info. */
        val googleWebClientId: String = "",
    )

    data class Fcm(val credentialsFile: String = "")

    /** [batchSeconds]: minimum gap between visible pushes per recipient and group; changes inside it are batched. */
    data class Push(val batchSeconds: Long = 30)

    /** [url]: exchange-rate source in Frankfurter v2 shape (`{url}/rates?base=EUR&date=`); empty turns GET /fx off. */
    data class Fx(val url: String = "https://api.frankfurter.dev/v2")

}

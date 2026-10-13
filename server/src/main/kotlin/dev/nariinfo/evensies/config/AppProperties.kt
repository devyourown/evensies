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
    val email: Email = Email(),
    /** Phase 10: the operator's contact address for Help & feedback and Report (`EVENSIES_SUPPORT_EMAIL`); empty = none. */
    val supportEmail: String = "",
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
        /** Store review sign-in (docs/API.md "Review sign-in"): `EVENSIES_REVIEW_LOGIN_USERNAME` / `_PASSWORD`. */
        val reviewUsername: String = "",
        val reviewPassword: String = "",
    ) {
        /** POST /auth/review exists only with a username and a password of at least [REVIEW_PASSWORD_MIN] characters. */
        val reviewLogin: Boolean
            get() = reviewUsername.isNotBlank() && reviewPassword.codePointCount(0, reviewPassword.length) >= REVIEW_PASSWORD_MIN

        companion object {
            const val REVIEW_PASSWORD_MIN = 20
        }
    }

    data class Fcm(val credentialsFile: String = "")

    /** [batchSeconds]: minimum gap between visible pushes per recipient and group; changes inside it are batched. */
    data class Push(val batchSeconds: Long = 30)

    /** [url]: exchange-rate source in Frankfurter v2 shape (`{url}/rates?base=EUR&date=`); empty turns GET /fx off. */
    data class Fx(val url: String = "https://api.frankfurter.dev/v2")

    /**
     * Phase 10 (docs/API.md "Email and account"): [smtpHost] empty turns every email feature off. [smtpTls] `starttls` (required),
     * `ssl` (465) or `none` (Mailpit only). [dailyLimit]: rolling 24 h cap, 0 = none. [webhookSecret]: Resend's `whsec_…`,
     * empty turns POST /webhooks/email off. [authRatePerMinute]: email sign-in requests (start, verify) per client IP.
     */
    data class Email(
        val smtpHost: String = "",
        val smtpPort: Int = 587,
        val smtpUser: String = "",
        val smtpPassword: String = "",
        val smtpTls: String = "starttls",
        val from: String = "Evensies <no-reply@localhost>",
        val dailyLimit: Int = 0,
        val webhookSecret: String = "",
        val authRatePerMinute: Double = 10.0,
    )

}

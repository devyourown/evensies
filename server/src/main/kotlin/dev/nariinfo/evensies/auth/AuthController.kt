package dev.nariinfo.evensies.auth

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.config.userId
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import tools.jackson.databind.JsonNode

/** [displayName]: Apple sends the user's name only once, outside the id token, so the app forwards it. */
data class IdTokenRequest(val idToken: String, val displayName: String? = null)
data class RefreshRequest(val refreshToken: String)
data class DeviceRequest(val deviceId: String, val fcmToken: String)
data class ServerInfo(val appleServicesId: String?, val googleWebClientId: String?, val devLogin: Boolean)

@RestController
class AuthController(
    private val auth: AuthService,
    private val devices: DeviceRepository,
    private val props: AppProperties,
    @Qualifier("appleVerifier") private val apple: IdTokenVerifier,
    @Qualifier("googleVerifier") private val google: IdTokenVerifier,
) {
    @PostMapping("/auth/apple")
    fun apple(@RequestBody req: IdTokenRequest): AuthResponse =
        apple.verify(req.idToken).let { auth.login("apple", it.subject, it.displayName.ifBlank { req.displayName.orEmpty() }) }

    @PostMapping("/auth/google")
    fun google(@RequestBody req: IdTokenRequest): AuthResponse =
        google.verify(req.idToken).let { auth.login("google", it.subject, it.displayName.ifBlank { req.displayName.orEmpty() }) }

    @PostMapping("/auth/refresh")
    fun refresh(@RequestBody req: RefreshRequest): TokenPair = auth.refresh(req.refreshToken)

    @GetMapping("/me")
    fun me(authentication: Authentication): UserDto = auth.me(authentication.userId)

    /**
     * `{"displayName"?, "homeCurrency"?, "language"?}`: a null name or currency counts as absent, a null language clears
     * it (a missing one keeps it); anything else but a JSON string is VALIDATION.
     */
    @PatchMapping("/me")
    fun updateMe(authentication: Authentication, @RequestBody body: JsonNode): UserDto {
        fun text(key: String): String? = body.get(key)?.takeUnless { it.isNull }?.let {
            if (!it.isString) throw ApiException.badRequest("VALIDATION", "$key must be a string")
            it.asString()
        }
        return auth.updateMe(authentication.userId, text("displayName"), text("homeCurrency"), body.has("language"), text("language"))
    }

    /** Public (docs/API.md "인증"): which sign-in buttons a prebuilt web app shows on this server. */
    @GetMapping("/info")
    fun info() = ServerInfo(props.auth.appleServicesId.trim().ifEmpty { null }, props.auth.googleWebClientId.trim().ifEmpty { null }, props.auth.devLogin)

    @DeleteMapping("/me")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteMe(authentication: Authentication) = auth.deleteAccount(authentication.userId)

    @PostMapping("/devices")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun device(authentication: Authentication, @RequestBody req: DeviceRequest) =
        devices.upsert(req.deviceId, authentication.userId, req.fcmToken)

    /** Sign-out: this phone stops getting the user's pushes. 204 also when the row is gone already. */
    @DeleteMapping("/devices/{deviceId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteDevice(authentication: Authentication, @PathVariable deviceId: String) =
        devices.delete(deviceId, authentication.userId)
}

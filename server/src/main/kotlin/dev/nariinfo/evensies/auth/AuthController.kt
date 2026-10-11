package dev.nariinfo.evensies.auth

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

/** [displayName]: Apple sends the user's name only once, outside the id token, so the app forwards it. */
data class IdTokenRequest(val idToken: String, val displayName: String? = null)
data class UpdateMeRequest(val displayName: String)
data class RefreshRequest(val refreshToken: String)
data class DeviceRequest(val deviceId: String, val fcmToken: String)

@RestController
class AuthController(
    private val auth: AuthService,
    private val devices: DeviceRepository,
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

    @PatchMapping("/me")
    fun updateMe(authentication: Authentication, @RequestBody req: UpdateMeRequest): UserDto =
        auth.rename(authentication.userId, req.displayName)

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

package dev.nariinfo.evensies.auth

import dev.nariinfo.evensies.common.ApiException
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController

data class DevLoginRequest(val name: String)

/** Development-only login. The endpoint does not exist unless evensies.auth.dev-login=true. */
@RestController
@ConditionalOnProperty("evensies.auth.dev-login", havingValue = "true")
class DevLoginController(private val auth: AuthService) {
    @PostMapping("/auth/dev")
    fun dev(@RequestBody req: DevLoginRequest): AuthResponse {
        val name = req.name.trim()
        if (name.isEmpty()) throw ApiException.badRequest("VALIDATION", "name is required")
        return auth.login("dev", name, name)
    }
}

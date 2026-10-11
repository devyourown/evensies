package dev.nariinfo.evensies.config

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.HttpMethod
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.core.Authentication
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
import org.springframework.web.filter.OncePerRequestFilter
import java.util.UUID

/** The authenticated user's id; the JWT filter stores it as the principal name. */
val Authentication.userId: UUID get() = UUID.fromString(name)

@Configuration
class SecurityConfig {
    @Bean
    fun filterChain(http: HttpSecurity, jwt: JwtService): SecurityFilterChain = http
        .csrf { it.disable() }
        .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
        .authorizeHttpRequests {
            it.requestMatchers("/auth/**", "/actuator/health", "/j/*", "/f/*").permitAll()
                .requestMatchers(HttpMethod.GET, "/invites/*", "/friend-invites/*").permitAll()
                .anyRequest().authenticated()
        }
        .exceptionHandling {
            it.authenticationEntryPoint { _, res, _ ->
                res.status = 401
                res.contentType = "application/json"
                res.writer.write("""{"code":"UNAUTHORIZED","message":"Missing or invalid access token"}""")
            }
        }
        .addFilterBefore(JwtAuthFilter(jwt), UsernamePasswordAuthenticationFilter::class.java)
        .build()
}

class JwtAuthFilter(private val jwt: JwtService) : OncePerRequestFilter() {
    override fun doFilterInternal(request: HttpServletRequest, response: HttpServletResponse, chain: FilterChain) {
        val header = request.getHeader("Authorization")
        if (header != null && header.startsWith("Bearer ")) {
            jwt.verify(header.removePrefix("Bearer ").trim())?.let { userId ->
                SecurityContextHolder.getContext().authentication =
                    UsernamePasswordAuthenticationToken(userId.toString(), null, emptyList())
            }
        }
        chain.doFilter(request, response)
    }
}

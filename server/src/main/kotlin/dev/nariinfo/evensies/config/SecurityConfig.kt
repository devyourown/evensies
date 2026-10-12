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
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.UrlBasedCorsConfigurationSource
import org.springframework.web.filter.OncePerRequestFilter
import java.util.UUID

/** The authenticated user's id; the JWT filter stores it as the principal name. */
val Authentication.userId: UUID get() = UUID.fromString(name)

@Configuration
class SecurityConfig {
    @Bean
    fun filterChain(http: HttpSecurity, jwt: JwtService, props: AppProperties): SecurityFilterChain {
        val origins = props.corsOrigins.map(String::trim).filter(String::isNotEmpty)
        if (origins.isNotEmpty()) http.cors { it.configurationSource(cors(origins)) }
        return http
            .csrf { it.disable() }
            .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .headers { it.contentSecurityPolicy { csp -> csp.policyDirectives(CSP) } }
            .authorizeHttpRequests {
                it.requestMatchers("/auth/**", "/actuator/health", "/j/*", "/f/*", "/", "/app", "/app/**").permitAll()
                    .requestMatchers(HttpMethod.GET, "/invites/*", "/friend-invites/*", "/info").permitAll()
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

    /**
     * Development only (`flutter run -d chrome` on another port): exactly [origins], no credentials (the token is a
     * header). Any other origin's preflight gets Spring's 403.
     */
    private fun cors(origins: List<String>) = UrlBasedCorsConfigurationSource().apply {
        registerCorsConfiguration("/**", CorsConfiguration().apply {
            allowedOrigins = origins
            allowedMethods = listOf("GET", "POST", "PUT", "PATCH", "DELETE")
            allowedHeaders = listOf("Authorization", "Content-Type")
            maxAge = 3600
        })
    }

    companion object {
        /**
         * On every response (docs/API.md "웹 앱"): tokens live in the web app's IndexedDB, so no third-party script but
         * the Google and Apple sign-in ones may run on this origin. `connect-src blob:`: a picked photo or file is read
         * from its blob: URL (only this origin can mint one), which `'self'` doesn't cover.
         */
        const val CSP = "default-src 'self'; script-src 'self' 'wasm-unsafe-eval' https://accounts.google.com/gsi/client https://appleid.cdn-apple.com; " +
            "style-src 'self' 'unsafe-inline' https://accounts.google.com/gsi/style; img-src 'self' data: blob: https://*.googleusercontent.com; " +
            "font-src 'self' https://fonts.gstatic.com; connect-src 'self' blob: https://fonts.gstatic.com https://accounts.google.com/gsi/; " +
            "frame-src https://accounts.google.com/gsi/ https://appleid.apple.com; worker-src 'self' blob:; object-src 'none'; base-uri 'self'; " +
            "frame-ancestors 'none'"
    }
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

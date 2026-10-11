package dev.nariinfo.evensies.common

import org.springframework.http.HttpStatus

data class ApiError(val code: String, val message: String)

/** [retryAfter]: seconds for a `Retry-After` header (a 429 that knows when the next try works). */
class ApiException(val status: HttpStatus, val code: String, message: String, val retryAfter: Long? = null) : RuntimeException(message) {
    companion object {
        fun badRequest(code: String, message: String) = ApiException(HttpStatus.BAD_REQUEST, code, message)
        fun notFound(what: String) = ApiException(HttpStatus.NOT_FOUND, "NOT_FOUND", "$what not found")
        fun forbidden(message: String = "Not a member of this group") = ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", message)
        fun unauthorized(message: String) = ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", message)
        fun tooManyRequests(message: String) = ApiException(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMITED", message)
        fun limit(message: String) = ApiException(HttpStatus.CONFLICT, "LIMIT_EXCEEDED", message)
    }
}

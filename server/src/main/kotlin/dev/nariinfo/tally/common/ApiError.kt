package dev.nariinfo.tally.common

import org.springframework.http.HttpStatus

data class ApiError(val code: String, val message: String)

class ApiException(val status: HttpStatus, val code: String, message: String) : RuntimeException(message) {
    companion object {
        fun badRequest(code: String, message: String) = ApiException(HttpStatus.BAD_REQUEST, code, message)
        fun notFound(what: String) = ApiException(HttpStatus.NOT_FOUND, "NOT_FOUND", "$what not found")
        fun forbidden(message: String = "Not a member of this group") = ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", message)
        fun unauthorized(message: String) = ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", message)
        fun limit(message: String) = ApiException(HttpStatus.CONFLICT, "LIMIT_EXCEEDED", message)
    }
}

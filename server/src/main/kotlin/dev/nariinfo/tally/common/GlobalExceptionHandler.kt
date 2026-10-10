package dev.nariinfo.tally.common

import org.slf4j.LoggerFactory
import org.springframework.dao.DuplicateKeyException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.HttpRequestMethodNotSupportedException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.multipart.support.MissingServletRequestPartException
import org.springframework.web.servlet.resource.NoResourceFoundException

@RestControllerAdvice
class GlobalExceptionHandler {
    private val log = LoggerFactory.getLogger(javaClass)

    @ExceptionHandler(ApiException::class)
    fun api(e: ApiException): ResponseEntity<ApiError> =
        ResponseEntity.status(e.status).body(ApiError(e.code, e.message ?: e.code))

    @ExceptionHandler(
        HttpMessageNotReadableException::class,
        MethodArgumentTypeMismatchException::class,
        MissingServletRequestParameterException::class,
        MissingServletRequestPartException::class,
    )
    fun badRequest(e: Exception): ResponseEntity<ApiError> =
        ResponseEntity.badRequest().body(ApiError("VALIDATION", e.message?.lineSequence()?.first() ?: "Malformed request"))

    @ExceptionHandler(NoResourceFoundException::class)
    fun notFound(e: NoResourceFoundException): ResponseEntity<ApiError> =
        ResponseEntity.status(HttpStatus.NOT_FOUND).body(ApiError("NOT_FOUND", "No such endpoint"))

    @ExceptionHandler(HttpRequestMethodNotSupportedException::class)
    fun methodNotAllowed(e: HttpRequestMethodNotSupportedException): ResponseEntity<ApiError> =
        ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(ApiError("METHOD_NOT_ALLOWED", e.message ?: ""))

    @ExceptionHandler(DuplicateKeyException::class)
    fun duplicate(e: DuplicateKeyException): ResponseEntity<ApiError> =
        ResponseEntity.status(HttpStatus.CONFLICT).body(ApiError("DUPLICATE", "Already exists"))

    @ExceptionHandler(Exception::class)
    fun other(e: Exception): ResponseEntity<ApiError> {
        log.error("Unhandled exception", e)
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ApiError("INTERNAL", "Internal server error"))
    }
}

package dev.nariinfo.evensies.common

import org.slf4j.LoggerFactory
import org.springframework.boot.tomcat.TomcatContextCustomizer
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.dao.DuplicateKeyException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.web.HttpRequestMethodNotSupportedException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.multipart.MaxUploadSizeExceededException
import org.springframework.web.multipart.support.MissingServletRequestPartException
import org.springframework.web.servlet.resource.NoResourceFoundException

/**
 * Tomcat closes the connection when a multipart upload goes over the cap, so the client never reads the 413 from
 * [GlobalExceptionHandler.tooLarge]. Swallowing the rest of the body (up to `server.tomcat.max-swallow-size`) lets it.
 */
@Configuration
class UploadConfig {
    @Bean
    fun swallowAbortedUploads() = TomcatContextCustomizer { it.swallowAbortedUploads = true }
}

@RestControllerAdvice
class GlobalExceptionHandler {
    private val log = LoggerFactory.getLogger(javaClass)

    @ExceptionHandler(ApiException::class)
    fun api(e: ApiException): ResponseEntity<ApiError> = ResponseEntity.status(e.status)
        .apply { e.retryAfter?.let { header("Retry-After", it.toString()) } }.body(ApiError(e.code, e.message ?: e.code))

    @ExceptionHandler(
        HttpMessageNotReadableException::class,
        MethodArgumentTypeMismatchException::class,
        MissingServletRequestParameterException::class,
        MissingServletRequestPartException::class,
    )
    fun badRequest(e: Exception): ResponseEntity<ApiError> =
        ResponseEntity.badRequest().body(ApiError("VALIDATION", e.message?.lineSequence()?.first() ?: "Malformed request"))

    /** Over the multipart cap (`spring.servlet.multipart.max-file-size`): 413 like an upload over its own limit. */
    @ExceptionHandler(MaxUploadSizeExceededException::class)
    fun tooLarge(e: MaxUploadSizeExceededException): ResponseEntity<ApiError> =
        ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).body(ApiError("TOO_LARGE", "The file is too large"))

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

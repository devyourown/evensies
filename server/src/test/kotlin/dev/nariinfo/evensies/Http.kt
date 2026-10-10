package dev.nariinfo.evensies

import org.springframework.core.io.ByteArrayResource
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.util.LinkedMultiValueMap
import org.springframework.web.client.RestClient
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper

/** Thin real-HTTP client for tests: never throws on 4xx/5xx, returns status + parsed body. */
class Http(port: Int, private val mapper: ObjectMapper) {
    data class Resp(val status: Int, val text: String) {
        lateinit var mapper: ObjectMapper
        val body: JsonNode get() = mapper.readTree(text)
        fun code(): String? = if (text.startsWith("{")) body.get("code")?.asString() else null
    }

    private val client = RestClient.builder().baseUrl("http://localhost:$port").build()

    fun send(method: HttpMethod, path: String, body: Any? = null, token: String? = null): Resp {
        val spec = client.method(method).uri(path).headers { h -> token?.let { h.setBearerAuth(it) } }
        if (body != null) spec.contentType(MediaType.APPLICATION_JSON).body(mapper.writeValueAsString(body))
        return exchange(spec)
    }

    fun upload(path: String, field: String, filename: String, bytes: ByteArray, token: String): Resp {
        val form = LinkedMultiValueMap<String, Any>()
        form.add(field, object : ByteArrayResource(bytes) { override fun getFilename() = filename })
        val spec = client.post().uri(path).headers { it.setBearerAuth(token) }.contentType(MediaType.MULTIPART_FORM_DATA).body(form)
        return exchange(spec)
    }

    private fun exchange(spec: RestClient.RequestBodySpec): Resp = spec.exchange { _, res ->
        Resp(res.statusCode.value(), res.body.readAllBytes().decodeToString()).also { it.mapper = mapper }
    }

    fun get(path: String, token: String? = null) = send(HttpMethod.GET, path, null, token)
    fun post(path: String, body: Any?, token: String? = null) = send(HttpMethod.POST, path, body, token)
    fun delete(path: String, token: String? = null) = send(HttpMethod.DELETE, path, null, token)
}

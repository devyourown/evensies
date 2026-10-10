package dev.nariinfo.evensies

import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import tools.jackson.databind.SerializationFeature
import tools.jackson.databind.json.JsonMapper
import java.nio.file.Files
import java.nio.file.Paths

/** Loads ../shared/<name> (the fixtures shared with the Flutter app). Fails loudly if missing. */
object SharedJson {
    val mapper: ObjectMapper = JsonMapper.builder().build()

    fun path(name: String) = Paths.get("..", "shared", name).toAbsolutePath().normalize()

    fun load(name: String): JsonNode {
        val p = path(name)
        check(Files.exists(p)) { "Shared fixture missing: $p (run tests from the server/ directory)" }
        return mapper.readTree(Files.readString(p))
    }

    /** Canonical JSON (sorted keys, numbers as text) so Int/Long and map ordering do not matter in comparisons. */
    fun canon(value: Any?): String = mapper.writer().with(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS)
        .writeValueAsString(mapper.convertValue(value, Any::class.java))
}

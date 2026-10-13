package dev.nariinfo.evensies.common

import tools.jackson.databind.JsonNode
import tools.jackson.databind.json.JsonMapper

/**
 * Text the server renders per language (push, reminders, landing pages, money), from resources/strings.json, a copy of
 * shared/strings.json (docs/API.md "Languages and web"). A language without strings is English, and so is every key a language
 * lacks (leaf by leaf).
 */
object Strings {
    private val json: JsonNode = Strings::class.java.getResourceAsStream("/strings.json")!!.use { JsonMapper.shared().readTree(it) }
    private val placeholder = Regex("\\{([A-Za-z]+)\\}")
    private val leading = Regex("^\\{([A-Za-z]+)\\}")

    /** The languages strings.json has, `en` first. */
    val languages: List<String> = json.propertyNames().filter { it != "_doc" }

    /** [code] when strings.json has it, else `en` (null, `xx`). */
    fun lang(code: String?): String = code?.takeIf { it in languages } ?: "en"

    private fun node(lang: String, path: Array<out String>): JsonNode? = path.fold(json[lang] as JsonNode?) { n, k -> n?.get(k) }

    /** The string at [path] in [lang], else in `en`; null when `en` has none either. */
    fun get(lang: String, vararg path: String): String? =
        (node(lang, path)?.takeIf { it.isString } ?: node("en", path)?.takeIf { it.isString })?.asString()

    /** A string map at [path] in [lang] only (`money.symbols`), empty when missing. */
    fun map(lang: String, vararg path: String): Map<String, String> =
        node(lang, path)?.properties()?.associate { (k, v) -> k to v.asString() } ?: emptyMap()

    /**
     * [template] with each `{name}` replaced in one left-to-right pass, so a value is inserted as is (a `{A}` typed in a
     * description stays); unknown names stay. When the template starts with a placeholder named in [words] (its value
     * is `words.you` / `words.someone`), the first char is upper-cased; member names never change.
     */
    fun fill(template: String, values: Map<String, String>, words: Set<String> = emptySet()): String {
        val text = placeholder.replace(template) { values[it.groupValues[1]] ?: it.value }
        val first = leading.find(template)?.groupValues?.get(1)
        return if (first != null && first in words && text.isNotEmpty()) text[0].uppercase() + text.substring(1) else text
    }
}

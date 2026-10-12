package dev.nariinfo.evensies

import dev.nariinfo.evensies.common.Strings
import dev.nariinfo.evensies.money.Money
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory
import tools.jackson.databind.JsonNode
import java.nio.file.Files
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Server side of docs/API.md "`shared/strings.json`": the resource copy, completeness per language and the renderer's rules. */
class StringsTest {
    private val shared = SharedJson.load("strings.json")
    private val placeholder = Regex("\\{[A-Za-z]+\\}")

    @Test
    fun resourceMatchesShared() {
        val resource = javaClass.getResourceAsStream("/strings.json")!!.readAllBytes().decodeToString()
        assertEquals(Files.readString(SharedJson.path("strings.json")), resource, "copy shared/strings.json to server/src/main/resources/strings.json (and app/assets/)")
    }

    @Test
    fun theThirteenLanguages() {
        assertEquals(listOf("en", "ko", "nl", "fr", "de", "id", "it", "ja", "pl", "pt", "es", "sv", "th"), Strings.languages)
        assertEquals("en", Strings.lang(null))
        assertEquals("en", Strings.lang("xx"))
        assertEquals("ko", Strings.lang("ko"))
    }

    /** Leaf path → text; `money.symbols` is per language (sv `SEK` → `kr`) and not compared. */
    private fun leaves(node: JsonNode, prefix: String = ""): Map<String, String> =
        node.properties().flatMap { (k, v) ->
            val path = if (prefix.isEmpty()) k else "$prefix.$k"
            when {
                path == "money.symbols" -> emptyList()
                v.isObject -> leaves(v, path).toList()
                else -> listOf(path to v.asString())
            }
        }.toMap()

    /** Every language has every key and variant of `en`, nothing else, non-empty, with the same placeholders. */
    @TestFactory
    fun everyLanguageIsComplete(): List<DynamicTest> {
        val en = leaves(shared["en"])
        return Strings.languages.drop(1).map { lang ->
            dynamicTest(lang) {
                val l = leaves(shared[lang])
                assertEquals(emptySet(), en.keys - l.keys, "$lang lacks these keys")
                assertEquals(emptySet(), l.keys - en.keys, "$lang has keys en doesn't")
                for ((path, text) in l) {
                    assertTrue(text.isNotBlank() || path == "money.group", "$lang $path is empty") // fr groups with U+202F
                    assertEquals(placeholder.findAll(en.getValue(path)).map { it.value }.toSet(), placeholder.findAll(text).map { it.value }.toSet(), "$lang $path: $text")
                }
                for ((code, symbol) in shared[lang]["money"]["symbols"].properties()) {
                    assertTrue(Money.isKnown(code) && symbol.asString().isNotBlank(), "$lang money.symbols.$code")
                }
            }
        }
    }

    /** docs/API.md "카테고리": the `en` names are categories.json's labels (parents and categories). */
    @Test
    fun englishCategoriesAreTheLabels() {
        val json = SharedJson.load("categories.json")
        val labels = (json["parents"].values() + json["categories"].values()).associate { it["key"].asString() to it["label"].asString() }
        assertEquals(labels, shared["en"]["categories"].properties().associate { (k, v) -> k to v.asString() })
    }

    @Test
    fun everyCurrencyRendersInEveryLanguage() {
        for (lang in Strings.languages) for (code in Money.decimals.keys) {
            val text = Money.display(123456789, code, lang)
            assertTrue(text.contains(Regex("\\d")) && text.length > 5 && !text.contains("{"), "$lang $code: $text")
        }
        assertEquals("−€48.00", Money.display(-4800, "EUR"))
        assertEquals("−48,00 €", Money.display(-4800, "EUR", "de"))
        assertEquals("€0.05", Money.display(5, "EUR", "xx"), "an unknown language is English")
    }

    /** One left-to-right pass (a typed `{A}` stays), unknown names stay, and only a leading word is upper-cased. */
    @Test
    fun fill() {
        assertEquals("{text} said {A}", Strings.fill("{A} said {text}", mapOf("A" to "{text}", "text" to "{A}")))
        assertEquals("Anna {unknown}", Strings.fill("{A} {unknown}", mapOf("A" to "Anna")))
        assertEquals("Someone paid someone", Strings.fill("{from} paid {to}", mapOf("from" to "someone", "to" to "someone"), setOf("from", "to")))
        assertEquals("someone paid", Strings.fill("{from} paid", mapOf("from" to "someone")), "a member named someone stays")
        assertEquals("Du hast", Strings.fill("{A} hast", mapOf("A" to "du"), setOf("A")))
        assertEquals("“x” · y", Strings.fill("“{d}” · {a}", mapOf("d" to "x", "a" to "y"), setOf("d")), "only when the template starts with it")
    }
}

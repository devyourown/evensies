package dev.nariinfo.evensies

import dev.nariinfo.evensies.export.Categories
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory
import java.nio.file.Files
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Server side of docs/API.md "카테고리": the resource copy and `Categories.keyForLabel` / `label`. */
class CategoriesTest {
    @Test
    fun categoriesResourceMatchesShared() {
        val resource = javaClass.getResourceAsStream("/categories.json")!!.readAllBytes().decodeToString()
        assertEquals(Files.readString(SharedJson.path("categories.json")), resource, "copy shared/categories.json to server/src/main/resources/categories.json")
    }

    /** keyForLabel is the app's resolveCategory with null in place of the General fallback. */
    @TestFactory
    fun sharedResolveCases(): List<DynamicTest> = SharedJson.load("category-cases.json")["resolve"].values().map { c ->
        val raw = c["raw"].takeUnless { it.isNull }?.asString()
        dynamicTest("resolve '$raw'") { assertEquals(c["expected"].asString(), Categories.keyForLabel(raw) ?: "uncategorized.general") }
    }

    @Test
    fun keyForLabelLeavesUnknownTextAlone() {
        assertEquals("uncategorized.general", Categories.keyForLabel("General"))
        assertEquals("transportation.bus_train", Categories.keyForLabel(" bus/TRAIN "))
        for (raw in listOf("Other", "Food", "food", "Food and drink", "Transportation", "Payment", "FOOD.DINING_OUT", "", "  ", null)) {
            assertNull(Categories.keyForLabel(raw), "'$raw'")
        }
    }

    @Test
    fun labelOnlyForCategoryKeys() {
        assertEquals("Dining out", Categories.label("food.dining_out"))
        assertEquals("Home - Other", Categories.label("home.other"))
        assertEquals("General", Categories.label("uncategorized.general"))
        for (raw in listOf("food", "Dining out", " food.dining_out", null)) assertNull(Categories.label(raw), "'$raw'")
    }

    /** The six `*.other` export as `{parent label} - Other` so a spreadsheet tells them apart, and read back as keys. */
    @Test
    fun everyLabelIsDistinctAndReadsBack() {
        assertEquals("Entertainment - Other", Categories.label("entertainment.other"))
        assertEquals("food.other", Categories.keyForLabel(" food and DRINK - other "))
        val keys = SharedJson.load("categories.json")["categories"].values().map { it["key"].asString() }
        for (k in keys) assertEquals(k, Categories.keyForLabel(Categories.label(k)), k)
        assertEquals(keys.size, keys.map { Categories.label(it) }.toSet().size)
    }
}

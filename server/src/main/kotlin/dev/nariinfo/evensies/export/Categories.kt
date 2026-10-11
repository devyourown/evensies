package dev.nariinfo.evensies.export

import tools.jackson.databind.json.JsonMapper

/** Expense categories from resources/categories.json (a copy of shared/categories.json, docs/API.md "카테고리"). */
object Categories {
    private val json = Categories::class.java.getResourceAsStream("/categories.json")!!.use { JsonMapper.shared().readTree(it) }
    private val parents = json["parents"].values().associate { it["key"].asString() to it["label"].asString() }

    /** key → English label, but the six `*.other` are `{parent label} - Other` (`Entertainment - Other`) to tell them apart. */
    private val labels: Map<String, String> = json["categories"].values().associate { c ->
        val key = c["key"].asString()
        key to c["label"].asString().let { if (key.endsWith(".other")) "${parents.getValue(key.substringBefore('.'))} - $it" else it }
    }

    /** Lowercased [labels] that appear once → key (a bare "Other" is none of them). */
    private val byLabel: Map<String, String> = labels.entries.groupBy { it.value.lowercase() }
        .filterValues { it.size == 1 }.mapValues { it.value.single().key }

    /** The CSV label of a category key ([labels]), else null (null, legacy text, parent keys). */
    fun label(key: String?): String? = labels[key]

    /**
     * App `resolveCategory` without the General fallback: a key (exact) or a label used once (any case), else null.
     * Server only: it also reads back the `{parent label} - Other` form [label] writes, so `keyForLabel(label(k)) == k`.
     */
    fun keyForLabel(raw: String?): String? {
        val t = raw?.trim() ?: return null
        return t.takeIf { it in labels } ?: byLabel[t.lowercase()]
    }
}

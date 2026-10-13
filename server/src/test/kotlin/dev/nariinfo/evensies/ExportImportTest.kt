package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ExportImportTest : IntegrationTestBase() {
    @Test
    fun csvExportAndSplitwiseImport() {
        val token = login("Csv")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        push(token, id, expenseCreated(me, 1234, mapOf(me to 1234), description = "Pizza"))
        val csv = http.get("/groups/$id/export?format=csv", token)
        assertEquals(200, csv.status)
        assertTrue(csv.text.startsWith("\"date\",\"description\",\"category\",\"amount\",\"currency\",\"fxRateToDefault\",\"paidBy\",\"Me\""), csv.text)
        assertTrue(csv.text.contains("\"2026-10-10\",\"Pizza\",\"General\",\"12.34\",\"EUR\",\"\",\"Me\",\"12.34\""), csv.text)

        val splitwise = """
            Date,Description,Category,Cost,Currency,Me,Carla
            2024-03-15,Taxi,Transportation,20.00,EUR,10.00,-10.00
            2024-03-16,Coffee,Food and drink,6.00,EUR,-3.00,3.00
            ,Total balance,,,EUR,7.00,-7.00

        """.trimIndent()
        val res = http.upload("/groups/$id/import/splitwise", "file", "sw.csv", splitwise.toByteArray(), token)
        assertEquals(200, res.status, res.text)
        assertEquals(2, res.body["imported"].asInt())
        val snap = snapshot(token, id)
        assertEquals(listOf("Me", "Carla"), snap["members"].values().map { it["name"].asString() })
        val carla = snap["members"][1]["id"].asString()
        val coffee = snap["expenses"].values().first { it["description"].asString() == "Coffee" }
        assertEquals(carla, coffee["paidBy"].asString())
        assertEquals(600, coffee["amount"].asLong())
        assertEquals(SharedJson.canon(listOf(mapOf("memberId" to me, "amount" to 300), mapOf("memberId" to carla, "amount" to 300))),
            SharedJson.canon(coffee["shares"]))
        assertEquals(res.body["latestSeq"].asLong(), snap["latestSeq"].asLong())
        assertEquals("Food and drink", coffee["category"].asString(), "a parent label is not a category: kept as text")
    }

    /** Phase 3 CSV: several payers in one cell (payers order, positive), refund rows negative; JSON export = snapshot. */
    @Test
    fun csvShowsPayersAndRefunds() {
        val token = login("Csv3")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val ben = java.util.UUID.randomUUID().toString()
        assertEquals(200, push(token, id, memberAdded("Ben", ben),
            expenseCreated(me, 10000, mapOf(me to 5000, ben to 5000), description = "Hotel",
                extra = mapOf("payers" to lines(mapOf(ben to 4000, me to 6000)))),
            expenseCreated(me, 6000, mapOf(me to 3000, ben to 3000), description = "Hotel refund",
                extra = mapOf("payers" to lines(mapOf(me to 6000)), "refund" to true, "split" to mapOf("mode" to "equal"))),
        ).status)
        val csv = http.get("/groups/$id/export?format=csv", token).text
        assertTrue(csv.contains("\"Hotel\",\"General\",\"100.00\",\"EUR\",\"\",\"Ben 40.00; Me 60.00\",\"50.00\",\"50.00\""), csv)
        assertTrue(csv.contains("\"Hotel refund\",\"General\",\"-60.00\",\"EUR\",\"\",\"Me\",\"-30.00\",\"-30.00\""), csv)

        val json = http.get("/groups/$id/export?format=json", token).body
        assertEquals(SharedJson.canon(snapshot(token, id)), SharedJson.canon(json))
        assertEquals(true, json["expenses"].values().first { it["description"].asString() == "Hotel refund" }["refund"].asBoolean())
        assertEquals(true, json["group"]["simplifyDebts"].asBoolean())
    }

    /**
     * Phase 4: the fxRateToDefault column after currency holds the stored rate as a plain decimal (no exponent, no
     * trailing zeros), empty when null; 0 and a leftover rate on a group-currency expense are written as stored.
     * Amounts stay in the expense currency, with its own decimals (OMR has 3, a new code from the 155 list).
     */
    @Test
    fun csvHasTheRateColumn() {
        val token = login("Csv4")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        fun expense(description: String, amount: Long, currency: String, rate: Any?) =
            expenseCreated(me, amount, mapOf(me to amount), description = description, currency = currency, extra = mapOf("fxRateToDefault" to rate))
        val res = push(token, id,
            expense("Sushi", 1000, "JPY", 0.00616),
            expense("Tiny", 300000, "USD", 7e-7),
            expense("Unconverted", 500, "JPY", 0),
            expense("Leftover", 1250, "EUR", 1.0),
            expense("Plain", 1250, "EUR", null),
            expense("Muscat", 1234567, "OMR", 2.38),
        )
        assertEquals(200, res.status, res.text)
        val csv = http.get("/groups/$id/export?format=csv", token).text
        for (row in listOf(
            "\"Sushi\",\"General\",\"1000\",\"JPY\",\"0.00616\",\"Me\",\"1000\"",
            "\"Tiny\",\"General\",\"3000.00\",\"USD\",\"0.0000007\",\"Me\"",
            "\"Unconverted\",\"General\",\"500\",\"JPY\",\"0\",\"Me\"",
            "\"Leftover\",\"General\",\"12.50\",\"EUR\",\"1\",\"Me\"",
            "\"Plain\",\"General\",\"12.50\",\"EUR\",\"\",\"Me\"",
            "\"Muscat\",\"General\",\"1234.567\",\"OMR\",\"2.38\",\"Me\",\"1234.567\"",
        )) assertTrue(csv.contains(row), "$row in\n$csv")
    }

    /**
     * Splitwise rows with several positive nets: everyone positive pays their net, the largest also pays the slack and
     * owes Cost − what the others owe (docs/API.md "Export and import"). The design's example imports with exact balances; a row
     * whose positive nets exceed the cost, or whose negative nets exceed it, is refused.
     */
    @Test
    fun splitwiseRowWithTwoPayers() {
        val token = login("Sw3")
        val group = createGroup(token)
        val id = group["id"].asString()
        val splitwise = """
            Date,Description,Category,Cost,Currency,Anna,Ben,Cara
            2024-03-15,Dinner,Food and drink,100.00,EUR,26.66,6.67,-33.33
            2024-03-16,Taxi,Transportation,30.00,EUR,20.00,-10.00,-10.00
            2024-03-17,Gift,General,100.00,EUR,50.00,-30.00,0.00

        """.trimIndent()
        val res = http.upload("/groups/$id/import/splitwise", "file", "sw.csv", splitwise.toByteArray(), token)
        assertEquals(200, res.status, res.text)
        val snap = snapshot(token, id)
        val ids = snap["members"].values().associate { it["name"].asString() to it["id"].asString() }
        val dinner = snap["expenses"].values().first { it["description"].asString() == "Dinner" }
        assertEquals(SharedJson.canon(lines(mapOf(ids.getValue("Anna") to 9333, ids.getValue("Ben") to 667))), SharedJson.canon(dinner["payers"]))
        assertEquals(ids.getValue("Anna"), dinner["paidBy"].asString())
        assertEquals(SharedJson.canon(lines(mapOf(ids.getValue("Cara") to 3333, ids.getValue("Anna") to 6667))), SharedJson.canon(dinner["shares"]))
        // balance per row = paid − owed = the row's nets
        fun net(e: tools.jackson.databind.JsonNode, m: String) =
            e["payers"].values().filter { it["memberId"].asString() == m }.sumOf { it["amount"].asLong() } -
                e["shares"].values().filter { it["memberId"].asString() == m }.sumOf { it["amount"].asLong() }
        assertEquals(listOf(2666L, 667, -3333), listOf("Anna", "Ben", "Cara").map { net(dinner, ids.getValue(it)) })
        val taxi = snap["expenses"].values().first { it["description"].asString() == "Taxi" }
        assertEquals(SharedJson.canon(lines(mapOf(ids.getValue("Anna") to 3000))), SharedJson.canon(taxi["payers"]), "one positive net: as before")
        // nets that don't add up to 0: the largest net owes Cost − what the others owe, so the shares still sum to Cost
        val gift = snap["expenses"].values().first { it["description"].asString() == "Gift" }
        assertEquals(SharedJson.canon(lines(mapOf(ids.getValue("Anna") to 10000))), SharedJson.canon(gift["payers"]))
        assertEquals(SharedJson.canon(lines(mapOf(ids.getValue("Ben") to 3000, ids.getValue("Anna") to 7000))), SharedJson.canon(gift["shares"]))

        val tooMuch = """
            Date,Description,Category,Cost,Currency,Anna,Ben
            2024-03-17,Odd,General,10.00,EUR,8.00,5.00

        """.trimIndent()
        val bad = http.upload("/groups/$id/import/splitwise", "file", "sw.csv", tooMuch.toByteArray(), token)
        assertEquals(400 to "IMPORT_FAILED", bad.status to bad.code(), bad.text)
        val othersOweTooMuch = """
            Date,Description,Category,Cost,Currency,Anna,Ben
            2024-03-18,Odd,General,10.00,EUR,5.00,-30.00

        """.trimIndent()
        val bad2 = http.upload("/groups/$id/import/splitwise", "file", "sw.csv", othersOweTooMuch.toByteArray(), token)
        assertEquals(400 to "IMPORT_FAILED", bad2.status to bad2.code(), bad2.text)
    }

    /**
     * Phase 5 CSV `category` column: a key's English label, `General` for null, blank or a missing key (an old client's
     * event), legacy text as stored. The server stores every value as sent (no validation, no mapping).
     */
    @Test
    fun csvCategoryColumn() {
        val token = login("Csv5")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        fun expense(description: String, category: String?, expenseId: String = java.util.UUID.randomUUID().toString()) =
            expenseCreated(me, 100, mapOf(me to 100), expenseId = expenseId, description = description, extra = mapOf("category" to category))
        val retagged = java.util.UUID.randomUUID().toString()
        val cleared = java.util.UUID.randomUUID().toString()
        @Suppress("UNCHECKED_CAST")
        val old = expenseCreated(me, 100, mapOf(me to 100), description = "Old").let { e ->
            e + ("payload" to (e["payload"] as Map<String, Any?>).minus("category"))
        }
        val res = push(token, id,
            expense("Pizza", "food.dining_out"), expense("Gen", "uncategorized.general"), expense("Snacks", "Food"),
            expense("Lower", "dining out"), expense("Parent", "food"), expense("Blank", "  "), expense("None", null), old,
            expense("Retagged", null, retagged), expenseUpdated(retagged, "category" to "transportation.taxi"),
            expense("Cleared", "home.rent", cleared), expenseUpdated(cleared, "category" to null),
            expense("Museum", "entertainment.other"),
        )
        assertEquals(200, res.status, res.text)
        val csv = http.get("/groups/$id/export?format=csv", token).text
        for ((description, cell) in listOf(
            "Pizza" to "Dining out", "Gen" to "General", "Snacks" to "Food", "Lower" to "dining out", "Parent" to "food",
            "Blank" to "General", "None" to "General", "Old" to "General", "Retagged" to "Taxi", "Cleared" to "General",
            "Museum" to "Entertainment - Other",
        )) {
            val row = "\"$description\",\"$cell\",\"1.00\",\"EUR\""
            assertTrue(csv.contains(row), "$row in\n$csv")
        }
        val stored = snapshot(token, id)["expenses"].values().associate { it["description"].asString() to it["category"] }
        assertEquals("Food", stored.getValue("Snacks").asString(), "legacy text is stored as sent")
        assertEquals("dining out", stored.getValue("Lower").asString(), "not mapped to a key")
        assertEquals("  ", stored.getValue("Blank").asString())
        assertEquals("transportation.taxi", stored.getValue("Retagged").asString())
        assertTrue(stored.getValue("Old").isNull && stored.getValue("Cleared").isNull)
    }

    /** CSV injection: text cells (names, description, category, paidBy) starting with = + - @ tab or CR get a leading '. */
    @Test
    fun csvDefusesFormulas() {
        val token = login("Csv5f")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val bob = java.util.UUID.randomUUID().toString()
        val res = push(token, id, memberAdded("@Bob", bob),
            expenseCreated(bob, 100, mapOf(me to 50, bob to 50), description = "=HYPERLINK(\"https://evil.example\",\"Open\")",
                extra = mapOf("category" to "+cmd", "refund" to true)),
            expenseCreated(me, 100, mapOf(me to 100), description = "\tTab", extra = mapOf("category" to "-x")),
        )
        assertEquals(200, res.status, res.text)
        val csv = http.get("/groups/$id/export?format=csv", token).text
        for (row in listOf(
            "\"paidBy\",\"Me\",\"'@Bob\"",
            // amounts keep their minus sign
            "\"'=HYPERLINK(\"\"https://evil.example\"\",\"\"Open\"\")\",\"'+cmd\",\"-1.00\",\"EUR\",\"\",\"'@Bob\",\"-0.50\",\"-0.50\"",
            "\"'\tTab\",\"'-x\",\"1.00\",\"EUR\",\"\",\"Me\",\"1.00\"",
        )) assertTrue(csv.contains(row), "$row in\n$csv")
    }

    /**
     * Phase 5 import: `Category` becomes a key when keyForLabel knows the text (else the trimmed text, blank = null);
     * a Payment row with two nets of ±Cost becomes a confirmed payment.created from +Cost to −Cost, any other Payment
     * row an expense. Balances per currency equal the CSV's nets either way, and `imported` counts expenses + payments.
     */
    @Test
    fun splitwiseCategoriesAndPayments() {
        val token = login("Sw5")
        val group = createGroup(token)
        val id = group["id"].asString()
        val splitwise = """
            Date,Description,Category,Cost,Currency,Me,Carla,Dan
            2024-03-15,Pizza,Dining out,30.00,EUR,20.00,-10.00,-10.00
            2024-03-15,Snacks,Food,6.00,EUR,4.00,-2.00,-2.00
            2024-03-15,Misc,Other,3.00,EUR,2.00,-1.00,-1.00
            2024-03-15,Gift, general ,3.00,EUR,2.00,-1.00,-1.00
            2024-03-15,Bits,,3.00,EUR,2.00,-1.00,-1.00
            2024-03-16,Carla paid Me,Payment,10.00,EUR,-10.00,10.00,0.00
            2024-03-16,Dan paid Carla,payment,5.00,USD,0.00,-5.00,5.00
            2024-03-17,Three people,Payment,9.00,EUR,6.00,-3.00,-3.00
            2024-03-17,Not the cost,Payment,8.00,EUR,4.00,-4.00,0.00
            ,Total balance,,,EUR,30.00,-12.00,-18.00

        """.trimIndent()
        val res = http.upload("/groups/$id/import/splitwise", "file", "sw.csv", splitwise.toByteArray(), token)
        assertEquals(200, res.status, res.text)
        assertEquals(9, res.body["imported"].asInt(), "7 expenses + 2 payments, members not counted")
        val snap = snapshot(token, id)
        assertEquals(res.body["latestSeq"].asLong(), snap["latestSeq"].asLong())
        val ids = snap["members"].values().associate { it["name"].asString() to it["id"].asString() }
        val categories = snap["expenses"].values().associate { it["description"].asString() to it["category"].takeUnless { c -> c.isNull }?.asString() }
        assertEquals(
            mapOf("Pizza" to "food.dining_out", "Snacks" to "Food", "Misc" to "Other", "Gift" to "uncategorized.general", "Bits" to null,
                "Three people" to "Payment", "Not the cost" to "Payment"),
            categories,
        )
        val payments = snap["payments"].values().map {
            listOf(it["fromMember"].asString(), it["toMember"].asString(), it["amount"].asLong(), it["currency"].asString(), it["date"].asString(), it["status"].asString())
        }.toSet()
        assertEquals(
            setOf(listOf(ids["Carla"], ids["Me"], 1000L, "EUR", "2024-03-16", "confirmed"), listOf(ids["Dan"], ids["Carla"], 500L, "USD", "2024-03-16", "confirmed")),
            payments,
        )
        // balance = paid − owed + sent − received, per currency: the same as the CSV's nets
        val balance = HashMap<Pair<String, String>, Long>()
        fun add(name: String, currency: String, amount: Long) = balance.merge(name to currency, amount, Long::plus)
        val names = ids.entries.associate { it.value to it.key }
        for (e in snap["expenses"].values()) {
            val cur = e["currency"].asString()
            for (p in e["payers"].values()) add(names.getValue(p["memberId"].asString()), cur, p["amount"].asLong())
            for (sh in e["shares"].values()) add(names.getValue(sh["memberId"].asString()), cur, -sh["amount"].asLong())
        }
        for (p in snap["payments"].values()) {
            add(names.getValue(p["fromMember"].asString()), p["currency"].asString(), p["amount"].asLong())
            add(names.getValue(p["toMember"].asString()), p["currency"].asString(), -p["amount"].asLong())
        }
        assertEquals(mapOf(("Me" to "EUR") to 3000L, ("Carla" to "EUR") to -1200L, ("Dan" to "EUR") to -1800L,
            ("Carla" to "USD") to -500L, ("Dan" to "USD") to 500L), balance.filterValues { it != 0L })
        // the CSV export shows the labels again
        val csv = http.get("/groups/$id/export?format=csv", token).text
        assertTrue(csv.contains("\"Pizza\",\"Dining out\",\"30.00\""), csv)
        assertTrue(csv.contains("\"Bits\",\"General\",\"3.00\""), csv)

        // only members import or export; an unknown group is 404
        val stranger = login("Sw5-stranger")
        assertEquals(403, http.upload("/groups/$id/import/splitwise", "file", "sw.csv", splitwise.toByteArray(), stranger).status)
        assertEquals(403, http.get("/groups/$id/export?format=csv", stranger).status)
        assertEquals(404, http.upload("/groups/${java.util.UUID.randomUUID()}/import/splitwise", "file", "sw.csv", splitwise.toByteArray(), token).status)
        assertEquals(9, snapshot(token, id)["expenses"].size() + snapshot(token, id)["payments"].size(), "the refused uploads stored nothing")
    }
}

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
        assertTrue(csv.text.startsWith("\"date\",\"description\",\"amount\",\"currency\",\"fxRateToDefault\",\"paidBy\",\"Me\""), csv.text)
        assertTrue(csv.text.contains("\"2026-10-10\",\"Pizza\",\"12.34\",\"EUR\",\"\",\"Me\",\"12.34\""), csv.text)

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
        assertTrue(csv.contains("\"Hotel\",\"100.00\",\"EUR\",\"\",\"Ben 40.00; Me 60.00\",\"50.00\",\"50.00\""), csv)
        assertTrue(csv.contains("\"Hotel refund\",\"-60.00\",\"EUR\",\"\",\"Me\",\"-30.00\",\"-30.00\""), csv)

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
            "\"Sushi\",\"1000\",\"JPY\",\"0.00616\",\"Me\",\"1000\"",
            "\"Tiny\",\"3000.00\",\"USD\",\"0.0000007\",\"Me\"",
            "\"Unconverted\",\"500\",\"JPY\",\"0\",\"Me\"",
            "\"Leftover\",\"12.50\",\"EUR\",\"1\",\"Me\"",
            "\"Plain\",\"12.50\",\"EUR\",\"\",\"Me\"",
            "\"Muscat\",\"1234.567\",\"OMR\",\"2.38\",\"Me\",\"1234.567\"",
        )) assertTrue(csv.contains(row), "$row in\n$csv")
    }

    /**
     * Splitwise rows with several positive nets: everyone positive pays their net, the largest also pays the slack and
     * owes Cost − what the others owe (docs/API.md "가져오기"). The design's example imports with exact balances; a row
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
}

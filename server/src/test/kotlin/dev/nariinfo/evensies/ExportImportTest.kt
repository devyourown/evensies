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
        assertTrue(csv.text.startsWith("\"date\",\"description\",\"amount\",\"currency\",\"paidBy\",\"Me\""), csv.text)
        assertTrue(csv.text.contains("\"2026-10-10\",\"Pizza\",\"12.34\",\"EUR\",\"Me\",\"12.34\""), csv.text)

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
}

package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AccountDeletionTest : IntegrationTestBase() {
    @Test
    fun deletedUserBecomesPlaceholderAndExpensesRemain() {
        val anna = login("Anna-del")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val annaMember = group["myMemberId"].asString()
        val ben = login("Ben-del")
        val benMember = UUID.randomUUID().toString()
        http.post("/invites/${group["inviteCode"].asString()}/join", mapOf("newMemberId" to benMember, "name" to "Ben"), ben)
        assertEquals(200, push(ben, id, expenseCreated(benMember, 900, mapOf(annaMember to 450, benMember to 450))).status)

        assertEquals(204, http.delete("/me", ben).status)

        val snap = snapshot(anna, id)
        val benRow = snap["members"].values().first { it["id"].asString() == benMember }
        assertTrue(benRow["userId"].isNull)
        assertEquals("Ben", benRow["name"].asString())
        assertEquals(false, benRow["removed"].asBoolean())
        assertEquals(1, snap["expenses"].size())
        assertEquals(benMember, snap["expenses"][0]["paidBy"].asString())
        assertEquals(1, http.get("/invites/${group["inviteCode"].asString()}").body["members"].values().count { it["linked"].asBoolean() })
    }
}

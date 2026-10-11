package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import tools.jackson.databind.JsonNode
import java.util.UUID
import kotlin.test.assertEquals

class PaymentConfirmTest : IntegrationTestBase() {
    private class Setup(val id: String, val anna: String, val ben: String, val annaMember: String, val benMember: String)

    private fun setup(tag: String): Setup {
        val anna = login("Pc-anna-$tag")
        val ben = login("Pc-ben-$tag")
        val group = createGroup(anna)
        val benMember = UUID.randomUUID().toString()
        http.post("/invites/${group["inviteCode"].asString()}/join", mapOf("newMemberId" to benMember, "name" to "Ben"), ben)
        return Setup(group["id"].asString(), anna, ben, group["myMemberId"].asString(), benMember)
    }

    private fun paymentCreated(paymentId: String, from: String, to: String, status: String?) = event(
        "payment.created",
        mapOf("paymentId" to paymentId, "fromMember" to from, "toMember" to to, "amount" to 500, "currency" to "EUR", "date" to "2026-10-11")
            + (if (status != null) mapOf("status" to status) else emptyMap()),
    )

    private fun payment(token: String, groupId: String, paymentId: String): JsonNode =
        snapshot(token, groupId)["payments"].values().first { it["id"].asString() == paymentId }

    private fun storedPayload(token: String, groupId: String, paymentId: String): JsonNode =
        http.get("/groups/$groupId/events?after=0", token).body["events"].values()
            .first { it["type"].asString() == "payment.created" && it["payload"]["paymentId"].asString() == paymentId }["payload"]

    @Test
    fun sentThenReceiverConfirms() {
        val s = setup("ok")
        val p = UUID.randomUUID().toString()
        assertEquals(200, push(s.ben, s.id, paymentCreated(p, s.benMember, s.annaMember, "sent")).status)
        assertEquals("sent", payment(s.anna, s.id, p)["status"].asString())

        val payerConfirm = push(s.ben, s.id, event("payment.confirmed", mapOf("paymentId" to p)))
        assertEquals(403, payerConfirm.status)
        val stranger = login("Pc-stranger")
        assertEquals(403, push(stranger, s.id, event("payment.confirmed", mapOf("paymentId" to p))).status)

        assertEquals(200, push(s.anna, s.id, event("payment.confirmed", mapOf("paymentId" to p))).status)
        assertEquals("confirmed", payment(s.ben, s.id, p)["status"].asString())
        assertEquals("confirmed", http.get("/groups/${s.id}/export?format=json", s.ben).body["payments"][0]["status"].asString())
    }

    @Test
    fun thirdMemberCannotConfirmOrDelete() {
        val s = setup("third")
        val carl = login("Pc-carl-third")
        val code = http.get("/groups/${s.id}", s.anna).body["inviteCode"].asString()
        http.post("/invites/$code/join", mapOf("newMemberId" to UUID.randomUUID().toString(), "name" to "Carl"), carl)
        val p = UUID.randomUUID().toString()
        push(s.ben, s.id, paymentCreated(p, s.benMember, s.annaMember, "sent"))
        assertEquals(403, push(carl, s.id, event("payment.confirmed", mapOf("paymentId" to p))).status)
        assertEquals(403, push(carl, s.id, event("payment.deleted", mapOf("paymentId" to p))).status)
    }

    @Test
    fun unknownPaymentAndBadStatus() {
        val s = setup("bad")
        val confirm = push(s.anna, s.id, event("payment.confirmed", mapOf("paymentId" to UUID.randomUUID().toString())))
        assertEquals(400, confirm.status)
        assertEquals("VALIDATION", confirm.code())
        val bad = push(s.ben, s.id, paymentCreated(UUID.randomUUID().toString(), s.benMember, s.annaMember, "pending"))
        assertEquals(400, bad.status)
        assertEquals("VALIDATION", bad.code())
    }

    @Test
    fun placeholderReceiverAndSelfReceiverAreStoredConfirmed() {
        val s = setup("ph")
        val placeholder = UUID.randomUUID().toString()
        assertEquals(200, push(s.anna, s.id, memberAdded("Zoe", placeholder)).status)
        val p1 = UUID.randomUUID().toString()
        // the placeholder is added in the same batch as the payment to it
        val newPh = UUID.randomUUID().toString()
        val p2 = UUID.randomUUID().toString()
        val p3 = UUID.randomUUID().toString()
        assertEquals(200, push(s.ben, s.id, paymentCreated(p1, s.benMember, placeholder, "sent")).status)
        assertEquals(200, push(s.ben, s.id, memberAdded("Yan", newPh), paymentCreated(p2, s.benMember, newPh, "sent")).status)
        // Anna records a payment from the placeholder to herself
        assertEquals(200, push(s.anna, s.id, paymentCreated(p3, placeholder, s.annaMember, "sent")).status)
        for (p in listOf(p1, p2, p3)) {
            assertEquals("confirmed", payment(s.anna, s.id, p)["status"].asString())
            assertEquals("confirmed", storedPayload(s.anna, s.id, p)["status"].asString(), "event payload is normalized")
        }
    }

    @Test
    fun receiverDeclinesAndPayerDeletes() {
        val s = setup("del")
        val p1 = UUID.randomUUID().toString()
        val p2 = UUID.randomUUID().toString()
        push(s.ben, s.id, paymentCreated(p1, s.benMember, s.annaMember, "sent"), paymentCreated(p2, s.benMember, s.annaMember, "sent"))
        assertEquals(200, push(s.anna, s.id, event("payment.deleted", mapOf("paymentId" to p1))).status) // "not received"
        assertEquals(200, push(s.ben, s.id, event("payment.deleted", mapOf("paymentId" to p2))).status)
        assertEquals(true, payment(s.anna, s.id, p1)["deleted"].asBoolean())
        assertEquals(true, payment(s.anna, s.id, p2)["deleted"].asBoolean())
        // confirm after delete is accepted and ignored
        assertEquals(200, push(s.anna, s.id, event("payment.confirmed", mapOf("paymentId" to p1))).status)
        assertEquals("sent", payment(s.anna, s.id, p1)["status"].asString())
    }

    @Test
    fun creatorMayDeleteAndLegacyPayloadIsConfirmed() {
        val s = setup("legacy")
        val zoe = UUID.randomUUID().toString()
        val yan = UUID.randomUUID().toString()
        val p = UUID.randomUUID().toString()
        // Anna records a payment between two placeholders, without status (old client)
        assertEquals(200, push(s.anna, s.id, memberAdded("Zoe", zoe), memberAdded("Yan", yan), paymentCreated(p, zoe, yan, null)).status)
        assertEquals("confirmed", payment(s.ben, s.id, p)["status"].asString())
        assertEquals(403, push(s.ben, s.id, event("payment.deleted", mapOf("paymentId" to p))).status)
        assertEquals(200, push(s.anna, s.id, event("payment.deleted", mapOf("paymentId" to p))).status)
    }
}

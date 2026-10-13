package dev.nariinfo.evensies

import dev.nariinfo.evensies.email.EmailAddress
import dev.nariinfo.evensies.email.EmailJobs
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.time.Instant
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Invite a placeholder by email (docs/API.md "Email invites"): one invite, one reminder after 3 days, gone after 14. */
class InviteEmailTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var jobs: EmailJobs

    private fun tag() = UUID.randomUUID().toString().take(6)

    private fun assertError(status: Int, code: String, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        assertEquals(code, res.code(), res.text)
    }

    private fun invite(token: String, groupId: String, memberId: String, email: String) =
        http.post("/groups/$groupId/members/$memberId/invite-email", mapOf("email" to email), token)

    /** A placeholder in [groupId]; returns its member id. */
    private fun placeholder(token: String, groupId: String, name: String = "Cara"): String {
        val id = UUID.randomUUID().toString()
        assertEquals(200, push(token, groupId, memberAdded(name, id)).status)
        return id
    }

    private fun backdate(memberId: String, days: Long) {
        jdbc.sql("UPDATE email_invites SET sent_at = sent_at - make_interval(days => :d) WHERE member_id = :m")
            .param("d", days.toInt()).param("m", UUID.fromString(memberId)).update()
    }

    @Test
    fun inviteThenOneReminderAfterThreeDaysAndThePlaceholderIsPreselected() {
        val anna = login("Inv-anna-${tag()}")
        val group = createGroup(anna, name = "Rome trip")
        val id = group["id"].asString()
        val cara = placeholder(anna, id)
        val email = address("Cara")
        assertEquals(204, invite(anna, id, cara, email).status)
        val sent = mail.to(email).single()
        assertTrue(sent.subject.endsWith(" invited you to “Rome trip” on Evensies"), sent.subject)
        val code = group["inviteCode"].asString()
        assertTrue("Hi Cara,\n\n" in sent.text, sent.text)
        assertTrue("/j/$code?m=$cara" in sent.text, sent.text)
        assertTrue(code.chunked(3).joinToString("-") in sent.text)
        assertTrue("open source" !in sent.text, "no marketing text in invite emails")
        val unsubscribe = sent.header("List-Unsubscribe")!!
        assertTrue(unsubscribe.startsWith("<http://localhost:8080/email/unsubscribe?t=") && unsubscribe.endsWith(">"), unsubscribe)
        assertEquals("List-Unsubscribe=One-Click", sent.header("List-Unsubscribe-Post"))
        assertTrue(unsubscribe.removeSurrounding("<", ">") in sent.text)

        assertEquals(204, invite(anna, id, cara, email).status)
        assertEquals(1, mail.to(email).size, "a second invite to the same member is a no-op")

        jobs.inviteReminders(Instant.now(), force = false)
        assertEquals(1, mail.to(email).size, "not before 3 days")
        backdate(cara, 4)
        jobs.inviteReminders(Instant.now(), force = false)
        assertEquals(2, mail.to(email).size)
        assertTrue(mail.to(email).last().subject.startsWith("Reminder: "))
        jobs.inviteReminders(Instant.now(), force = false)
        assertEquals(2, mail.to(email).size, "one reminder only")

        // The landing page passes the placeholder on; a non-UUID is dropped.
        val page = http.get("/j/$code?m=$cara").text
        assertTrue("evensies://join/$code?m=$cara" in page && "/app/#/join/$code?m=$cara" in page, page)
        val bad = http.get("/j/$code?m=..%2F..%2Fx").text
        assertTrue("evensies://join/$code\"" in bad && "?m=" !in bad, bad)
    }

    @Test
    fun noReminderAfterLinkingAndTheAddressIsPurgedAfter14Days() {
        val anna = login("Inv2-anna-${tag()}")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val cara = placeholder(anna, id)
        val dan = placeholder(anna, id, "Dan")
        val caraEmail = address("Cara")
        val danEmail = address("Dan")
        assertEquals(204, invite(anna, id, cara, caraEmail).status)
        assertEquals(204, invite(anna, id, dan, danEmail).status)
        val caraUser = login("Inv2-cara-${tag()}")
        assertEquals(200, http.post("/invites/${group["inviteCode"].asString()}/join", mapOf("memberId" to cara), caraUser).status)
        backdate(cara, 4)
        jobs.inviteReminders(Instant.now(), force = false)
        assertEquals(1, mail.to(caraEmail).size, "no reminder once the placeholder is claimed")

        backdate(dan, 15)
        jobs.purge(Instant.now())
        assertEquals(0, jdbc.sql("SELECT count(*) FROM email_invites WHERE member_id = :m").param("m", UUID.fromString(dan)).query(Int::class.java).single())
    }

    @Test
    fun capsAndSilentSkips() {
        val anna = login("Inv3-anna-${tag()}")
        val id = createGroup(anna)["id"].asString()
        val shared = address("Shared")
        // The same address: 3 invites in 7 days, the 4th is silent.
        repeat(4) { assertEquals(204, invite(anna, id, placeholder(anna, id, "P$it"), shared).status) }
        assertEquals(3, mail.to(shared).size)
        // A suppressed address: 204, nothing sent.
        val unsubscribed = address("Nope")
        jdbc.sql("INSERT INTO email_suppressions (email_hash, reason) VALUES (:h, 'unsubscribe')").param("h", EmailAddress.hash(unsubscribed)).update()
        assertEquals(204, invite(anna, id, placeholder(anna, id), unsubscribed).status)
        assertEquals(0, mail.to(unsubscribed).size)
        // The inviter: 20 per 24 hours (3 sent so far), then 429.
        repeat(17) { assertEquals(204, invite(anna, id, placeholder(anna, id, "Q$it"), address("Q$it")).status) }
        assertError(429, "RATE_LIMITED", invite(anna, id, placeholder(anna, id), address("TooMany")))
    }

    @Test
    fun permissionsAndValidation() {
        val t = tag()
        val anna = login("Inv4-anna-$t")
        val ben = login("Inv4-ben-$t")
        val stranger = login("Inv4-stranger-$t")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val benMember = join(ben, group, "Ben")
        val cara = placeholder(anna, id)
        val email = address("Cara")
        assertEquals(403, invite(stranger, id, cara, email).status)
        assertEquals(401, http.post("/groups/$id/members/$cara/invite-email", mapOf("email" to email)).status)
        assertError(400, "VALIDATION", invite(anna, id, cara, "not an address"))
        assertError(409, "MEMBER_TAKEN", invite(anna, id, benMember, email))
        assertEquals(404, invite(anna, id, UUID.randomUUID().toString(), email).status)
        // A member of another group (IDOR): 404, nothing sent.
        val other = createGroup(stranger)
        val foreign = placeholder(stranger, other["id"].asString())
        assertEquals(404, invite(anna, id, foreign, email).status)
        // Removed: 404.
        val gone = placeholder(anna, id, "Gone")
        assertEquals(200, push(anna, id, event("member.removed", mapOf("memberId" to gone))).status)
        assertEquals(404, invite(anna, id, gone, email).status)
        // A deleted group: 404; and its reminders wait.
        assertEquals(204, invite(ben, id, cara, email).status, "any member may invite")
        assertEquals(200, push(ben, id, event("group.deleted", emptyMap())).status)
        assertEquals(404, invite(anna, id, placeholder(anna, id, "Late"), address("Late")).status)
        backdate(cara, 4)
        jobs.inviteReminders(Instant.now(), force = false)
        assertEquals(1, mail.to(email).size, "no reminder for a deleted group")
    }

    @Test
    fun aNonUserGetsTheInvitersLanguageAndAUserTheirOwn() {
        val anna = login("Inv5-anna-${tag()}")
        assertEquals(200, http.patch("/me", mapOf("language" to "de"), anna).status)
        val id = createGroup(anna, name = "WG")["id"].asString()
        val stranger = address("Fremd")
        assertEquals(204, invite(anna, id, placeholder(anna, id), stranger).status)
        assertTrue(mail.to(stranger).single().subject.endsWith("hat dich zu „WG“ auf Evensies eingeladen"), mail.to(stranger).single().subject)
        val (ko, koEmail) = emailUser("Kim")
        assertEquals(200, http.patch("/me", mapOf("language" to "ko"), ko).status)
        assertEquals(204, invite(anna, id, placeholder(anna, id, "Kim"), koEmail).status)
        assertTrue("초대했어요" in mail.to(koEmail).last().subject, mail.to(koEmail).last().subject)
        // Never linked automatically: the placeholder stays a placeholder.
        assertTrue(snapshot(anna, id)["members"].values().none { it["name"].asString() == "Kim" && !it["userId"].isNull })
    }
}

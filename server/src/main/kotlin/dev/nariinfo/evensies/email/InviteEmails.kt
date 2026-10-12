package dev.nariinfo.evensies.email

import dev.nariinfo.evensies.auth.AuthService
import dev.nariinfo.evensies.auth.UserRepository
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.group.Group
import dev.nariinfo.evensies.group.GroupService
import dev.nariinfo.evensies.group.InviteCodes
import dev.nariinfo.evensies.group.MemberRepository
import org.springframework.http.HttpStatus
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.security.core.Authentication
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import java.time.Clock
import java.time.Duration
import java.time.ZoneOffset
import java.util.UUID

/**
 * Invite a placeholder by email (docs/API.md "이메일 초대"): one invite plus one reminder after 3 days ([EmailJobs]),
 * the address deleted after 14 days. Existing users are never linked automatically; the link preselects the placeholder.
 */
@Service
class InviteEmails(
    private val mailer: Mailer,
    private val tokens: EmailTokens,
    private val groups: GroupService,
    private val members: MemberRepository,
    private val users: UserRepository,
    private val auth: AuthService,
    private val jdbc: JdbcClient,
    private val clock: Clock,
    private val props: AppProperties,
) {
    /**
     * 204 also when skipped without sending, which reveals nothing: the address is suppressed, the member already has
     * an invite, or the address got [PER_ADDRESS] in 7 days.
     */
    fun invite(groupId: UUID, memberId: UUID, inviterId: UUID, raw: String?) {
        mailer.requireEnabled()
        val (group, _) = groups.requireMember(groupId, inviterId)
        val email = EmailAddress.normalize(raw) ?: throw ApiException.badRequest("VALIDATION", "That isn't an email address we can send to")
        if (group.deleted) throw ApiException.notFound("Group")
        val member = members.find(memberId)?.takeIf { it.groupId == groupId && !it.removed } ?: throw ApiException.notFound("Member")
        if (member.userId != null) throw ApiException(HttpStatus.CONFLICT, "MEMBER_TAKEN", "That member is already linked to a user")
        if (mailer.count(Mailer.INVITES, Duration.ofDays(1), userId = inviterId) >= PER_INVITER) {
            throw ApiException.tooManyRequests("Too many email invites today, share the link instead")
        }
        val exists = jdbc.sql("SELECT EXISTS (SELECT 1 FROM email_invites WHERE member_id = :m)").param("m", memberId).query(Boolean::class.java).single()
        if (exists || mailer.isSuppressed(email) || mailer.count(Mailer.INVITES, Duration.ofDays(7), toHash = EmailAddress.hash(email)) >= PER_ADDRESS) return
        val inviter = auth.user(inviterId)
        val sent = mailer.send("invite", email, inviterId, message(group, memberId, member.name, inviter.displayName, inviter.language, email, reminder = false))
        if (sent == Mailer.Result.OVER_BUDGET) throw ApiException.tooManyRequests("Email limit reached for today — share the link instead")
        if (sent == Mailer.Result.SENT) {
            jdbc.sql("INSERT INTO email_invites (member_id, group_id, email, invited_by, sent_at) VALUES (:m, :g, :e, :u, :t) ON CONFLICT DO NOTHING")
                .param("m", memberId).param("g", groupId).param("e", email).param("u", inviterId).param("t", clock.instant().atOffset(ZoneOffset.UTC)).update()
        }
    }

    /** The invite or its reminder, in the language of the account holding [email], else the inviter's. */
    fun message(group: Group, memberId: UUID, placeholder: String, inviter: String, inviterLanguage: String?, email: String, reminder: Boolean): Email {
        val lang = users.findActiveByEmail(email)?.language ?: inviterLanguage ?: "en"
        val code = InviteCodes.normalize(group.inviteCode).let { if (it.length == InviteCodes.LENGTH) it.chunked(3).joinToString("-") else it }
        val base = props.publicUrl.trimEnd('/')
        val link = "$base/j/${group.inviteCode}?m=$memberId"
        val unsubscribe = "$base/email/unsubscribe?t=" + tokens.unsubscribe(EmailTokens.INVITES, EmailAddress.hash(email))
        return EmailTemplates.invite(lang, reminder, inviter, group.name, placeholder, link, code, unsubscribe)
    }

    companion object {
        /** Abuse caps (docs/API.md "속도 제한"). */
        const val PER_INVITER = 20
        const val PER_ADDRESS = 3
    }
}

data class InviteEmailRequest(val email: String? = null)

@RestController
class InviteEmailController(private val invites: InviteEmails) {
    @PostMapping("/groups/{id}/members/{memberId}/invite-email")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun invite(auth: Authentication, @PathVariable id: UUID, @PathVariable memberId: UUID, @RequestBody req: InviteEmailRequest) =
        invites.invite(id, memberId, auth.userId, req.email)
}

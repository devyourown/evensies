package dev.nariinfo.evensies.auth

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.userId
import org.springframework.http.HttpStatus
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.security.core.Authentication
import org.springframework.stereotype.Repository
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

data class BlockedUserDto(val userId: UUID, val displayName: String)

/**
 * `user_blocks` (docs/API.md "차단"): a block mutes the blocked person for the blocker (no friend adds, reminders, visible
 * pushes, digest lines or recurring reminders from them). Money stays visible: shared groups and balances don't change.
 */
@Repository
class BlockRepository(private val jdbc: JdbcClient) {
    fun isBlocked(blocker: UUID, blocked: UUID): Boolean =
        jdbc.sql("SELECT EXISTS (SELECT 1 FROM user_blocks WHERE blocker = :a AND blocked = :b)").param("a", blocker).param("b", blocked)
            .query(Boolean::class.java).single()

    fun block(blocker: UUID, blocked: UUID) {
        jdbc.sql("INSERT INTO user_blocks (blocker, blocked) VALUES (:a, :b) ON CONFLICT DO NOTHING").param("a", blocker).param("b", blocked).update()
    }

    fun unblock(blocker: UUID, blocked: UUID) {
        jdbc.sql("DELETE FROM user_blocks WHERE blocker = :a AND blocked = :b").param("a", blocker).param("b", blocked).update()
    }

    /** Oldest block first; a deleted account shows with its cleared name. */
    fun list(blocker: UUID): List<BlockedUserDto> = jdbc.sql(
        "SELECT u.id, u.display_name FROM user_blocks b JOIN users u ON u.id = b.blocked WHERE b.blocker = :a ORDER BY b.created_at, u.id"
    ).param("a", blocker).query { rs, _ -> BlockedUserDto(rs.getObject("id", UUID::class.java), rs.getString("display_name")) }.list()

    /** Account deletion: both directions. */
    fun deleteByUser(userId: UUID) {
        jdbc.sql("DELETE FROM user_blocks WHERE blocker = :u OR blocked = :u").param("u", userId).update()
    }
}

@RestController
class BlockController(private val blocks: BlockRepository, private val users: UserRepository, private val auth: AuthService) {
    @GetMapping("/me/blocks")
    fun list(authentication: Authentication): List<BlockedUserDto> = blocks.list(authentication.userId)

    @PutMapping("/me/blocks/{userId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun block(authentication: Authentication, @PathVariable userId: UUID) = blocks.block(target(authentication, userId), userId)

    @DeleteMapping("/me/blocks/{userId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun unblock(authentication: Authentication, @PathVariable userId: UUID) = blocks.unblock(target(authentication, userId), userId)

    /** The caller (401 when deleted); 400 for themselves, 404 for an unknown or deleted user. */
    private fun target(authentication: Authentication, userId: UUID): UUID {
        val me = auth.me(authentication.userId).id
        if (me == userId) throw ApiException.badRequest("VALIDATION", "You can't block yourself")
        if (users.find(userId)?.deleted != false) throw ApiException.notFound("User")
        return me
    }
}

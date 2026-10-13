package dev.nariinfo.evensies.storage

import org.slf4j.LoggerFactory
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import java.nio.file.Files
import java.time.Duration
import java.time.Instant
import java.util.UUID

/**
 * Daily clean-up of receipt files (docs/API.md "Recurring expenses", daily clean-up; Phase 7 leftovers): uploads never attached to an
 * expense within 7 days go (rows first, so nothing can attach them meanwhile), and the files of deleted receipts are
 * removed again in case a crash came between the commit and the file deletion.
 * ponytail: reads every deleted row daily; limit to the last 7 days past a few hundred thousand rows.
 */
@Component
class Sweep(private val jdbc: JdbcClient, private val files: FileStore) {
    private val log = LoggerFactory.getLogger(javaClass)

    @Scheduled(cron = "0 30 3 * * *")
    fun run() {
        val unattached = jdbc.sql(
            "DELETE FROM attachments WHERE expense_id IS NULL AND created_at < now() - interval '7 days' RETURNING group_id, id"
        ).query { rs, _ -> rs.getObject("group_id", UUID::class.java) to rs.getObject("id", UUID::class.java) }.list()
        val deleted = jdbc.sql("SELECT group_id, id FROM attachments WHERE deleted_at IS NOT NULL")
            .query { rs, _ -> rs.getObject("group_id", UUID::class.java) to rs.getObject("id", UUID::class.java) }.list()
        for ((groupId, id) in unattached + deleted) {
            for (key in AttachmentController.keys(groupId, id).toList()) {
                try {
                    files.delete(key)
                } catch (e: Exception) {
                    log.warn("Couldn't delete {}: {}", key, e.toString()) // ponytail: an unattached upload's file stays; scan the directory if that matters
                }
            }
        }
        if (unattached.isNotEmpty()) log.info("Sweep: removed {} unattached receipt uploads", unattached.size)
        sweepCovers()
    }

    /**
     * Phase 10: every cover file that isn't its group's current one (a crash after commit, or an upload whose push failed).
     * Files younger than an hour stay: an upload writes its file before its `group.updated` commits.
     */
    fun sweepCovers() {
        val cutoff = Instant.now().minus(Duration.ofHours(1))
        for (dir in files.children("covers")) {
            val groupId = runCatching { UUID.fromString(dir) }.getOrNull() ?: continue
            val current = jdbc.sql("SELECT cover_image_id FROM groups WHERE id = :g").param("g", groupId).query(UUID::class.java).optional().orElse(null)
            for (name in files.children("covers/$groupId")) {
                if (name == "$current.jpg") continue
                val modified = files.path("covers/$groupId/$name")?.let { Files.getLastModifiedTime(it).toInstant() } ?: continue
                if (modified > cutoff) continue
                try {
                    files.delete("covers/$groupId/$name")
                } catch (e: Exception) {
                    log.warn("Couldn't delete cover {}/{}: {}", groupId, name, e.toString())
                }
            }
        }
    }
}

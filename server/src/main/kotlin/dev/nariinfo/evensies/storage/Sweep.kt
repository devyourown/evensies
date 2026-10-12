package dev.nariinfo.evensies.storage

import org.slf4j.LoggerFactory
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import java.util.UUID

/**
 * Daily clean-up of receipt files (docs/API.md "반복 지출" → "하루 정리", Phase 7 leftovers): uploads never attached to an
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
    }
}

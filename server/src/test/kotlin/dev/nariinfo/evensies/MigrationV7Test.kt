package dev.nariinfo.evensies

import org.flywaydb.core.Flyway
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.util.UUID
import javax.sql.DataSource
import kotlin.test.assertEquals

/** V7 on data written before Phase 6: normal groups, expense comments, prefs with reminders on, old history seen. */
class MigrationV7Test : IntegrationTestBase() {
    @Autowired
    private lateinit var dataSource: DataSource

    @Autowired
    private lateinit var jdbc: JdbcClient

    @Test
    fun v7KeepsOldRowsValidAndMarksOldHistorySeen() {
        val schema = "v7_check"
        fun migrateTo(version: String) = Flyway.configure().dataSource(dataSource).schemas(schema).target(version).load().migrate()
        fun one(sql: String) = jdbc.sql(sql).query { rs, _ -> (1..rs.metaData.columnCount).map { rs.getObject(it)?.toString() } }.list()
        try {
            migrateTo("6")
            val ids = List(7) { UUID.randomUUID() }
            val (u, v, g, a, b) = ids
            val x = ids[5]
            val c = ids[6]
            for (sql in listOf(
                "INSERT INTO $schema.users (id, provider, subject, display_name) VALUES (:u, 'dev', :u, 'Anna'), (:v, 'dev', :v, 'Ben')",
                "INSERT INTO $schema.groups (id, name, default_currency, invite_code, created_by) VALUES (:g, 'Trip', 'EUR', 'ABC234', :u)",
                "INSERT INTO $schema.members (id, group_id, user_id, name) VALUES (:a, :g, :u, 'Anna'), (:b, :g, :v, 'Ben')",
                "INSERT INTO $schema.expenses (id, group_id, description, amount, currency, paid_by, date) VALUES (:x, :g, 'Taxi', 1234, 'EUR', :b, '2026-10-01')",
                "INSERT INTO $schema.comments (id, group_id, expense_id, author_member_id, text, created_at) VALUES (:c, :g, :x, :a, 'Hi', now())",
                "INSERT INTO $schema.notification_prefs (user_id, expenses, comments, members) VALUES (:u, false, true, true)",
                "INSERT INTO $schema.events (group_id, seq, client_id, type, payload, actor_user_id, created_at) VALUES " +
                    "(:g, 1, :x, 'group.created', '{}', :u, now()), (:g, 2, :c, 'member.added', '{}', :u, now())",
            )) {
                jdbc.sql(sql).param("u", u).param("v", v).param("g", g).param("a", a).param("b", b).param("x", x).param("c", c).update()
            }
            migrateTo("7")
            assertEquals(listOf(listOf("group")), one("SELECT kind FROM $schema.groups"))
            assertEquals(listOf(listOf(x.toString(), null)), one("SELECT expense_id, payment_id FROM $schema.comments"))
            assertEquals(listOf(listOf("false", "true")), one("SELECT expenses, reminders FROM $schema.notification_prefs"))
            assertEquals(listOf(listOf(null)), one("SELECT friend_code FROM $schema.users WHERE id = '$u'"))
            val maxFeed = one("SELECT max(feed_id) FROM $schema.events").single().single()
            assertEquals(setOf(listOf(u.toString(), maxFeed), listOf(v.toString(), maxFeed)), one("SELECT user_id, feed_id FROM $schema.activity_seen").toSet())
        } finally {
            jdbc.sql("DROP SCHEMA IF EXISTS $schema CASCADE").update()
        }
    }
}

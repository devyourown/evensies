package dev.nariinfo.evensies

import org.flywaydb.core.Flyway
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.util.UUID
import javax.sql.DataSource
import kotlin.test.assertEquals

/** V12 on data stored before it: groups become live "other" groups without a cover, prefs "auto" without a clock. */
class MigrationV12Test : IntegrationTestBase() {
    @Autowired
    private lateinit var dataSource: DataSource

    @Autowired
    private lateinit var jdbc: JdbcClient

    @Test
    fun v12KeepsRowsAndAddsTheDefaults() {
        val schema = "v12_check"
        fun migrateTo(version: String) = Flyway.configure().dataSource(dataSource).schemas(schema).target(version).load().migrate()
        try {
            migrateTo("11")
            val (u, g) = List(2) { UUID.randomUUID() }
            fun sql(s: String) = jdbc.sql(s).param("u", u).param("g", g).update()
            sql("INSERT INTO $schema.users (id, provider, subject, display_name) VALUES (:u, 'apple', 'sub', 'Anna')")
            sql("INSERT INTO $schema.groups (id, name, default_currency, invite_code, created_by) VALUES (:g, 'Trip', 'EUR', 'ABC234', :u)")
            sql("INSERT INTO $schema.notification_prefs (user_id, expenses) VALUES (:u, false)")
            sql("INSERT INTO $schema.devices (id, user_id, fcm_token) VALUES ('d1', :u, 'tok')")
            migrateTo("12")
            val group = jdbc.sql("SELECT type, cover_image_id, deleted_at FROM $schema.groups").query { rs, _ ->
                Triple(rs.getString(1), rs.getString(2), rs.getObject(3))
            }.single()
            assertEquals(Triple("other", null, null), group)
            val prefs = jdbc.sql("SELECT email_digest, last_digest_at, last_digest_feed_id, expenses FROM $schema.notification_prefs").query { rs, _ ->
                listOf(rs.getString(1), rs.getObject(2), rs.getLong(3), rs.getBoolean(4))
            }.single()
            assertEquals(listOf("auto", null, 0L, false), prefs)
            assertEquals(true, jdbc.sql("SELECT notifications_allowed FROM $schema.devices").query(Boolean::class.java).single())
            assertEquals(null, jdbc.sql("SELECT email FROM $schema.users").query(String::class.java).optional().orElse(null))
        } finally {
            jdbc.sql("DROP SCHEMA IF EXISTS $schema CASCADE").update()
        }
    }
}

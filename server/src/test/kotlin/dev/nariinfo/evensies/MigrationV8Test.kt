package dev.nariinfo.evensies

import org.flywaydb.core.Flyway
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.util.UUID
import javax.sql.DataSource
import kotlin.test.assertEquals

/** V8 on moves stored before it: a moved expense (restored afterwards or not) ends moved and deleted, like a replay. */
class MigrationV8Test : IntegrationTestBase() {
    @Autowired
    private lateinit var dataSource: DataSource

    @Autowired
    private lateinit var jdbc: JdbcClient

    @Test
    fun v8MarksStoredMovesLikeAReplay() {
        val schema = "v8_check"
        fun migrateTo(version: String) = Flyway.configure().dataSource(dataSource).schemas(schema).target(version).load().migrate()
        try {
            migrateTo("7")
            val (u, g, a) = List(3) { UUID.randomUUID() }
            // moved (then restored), moved, plain delete, live, and one moved by an event of another group's log
            val xs = List(5) { UUID.randomUUID() }
            val other = UUID.randomUUID()
            fun sql(s: String) = jdbc.sql(s).param("u", u).param("g", g).param("a", a).param("o", other).update()
            sql("INSERT INTO $schema.users (id, provider, subject, display_name) VALUES (:u, 'dev', :u, 'Anna')")
            sql("INSERT INTO $schema.groups (id, name, default_currency, invite_code, created_by) VALUES (:g, 'Trip', 'EUR', 'ABC234', :u), (:o, 'Other', 'EUR', 'ABC235', :u)")
            sql("INSERT INTO $schema.members (id, group_id, user_id, name) VALUES (:a, :g, :u, 'Anna')")
            for ((i, x) in xs.withIndex()) {
                sql("INSERT INTO $schema.expenses (id, group_id, description, amount, currency, paid_by, date, deleted_at) " +
                    "VALUES ('$x', :g, 'E$i', 100, 'EUR', :a, '2026-10-01', ${if (i in 1..2) "now()" else "NULL"})")
            }
            val moved = """{"groupId": "$other", "expenseId": "${UUID.randomUUID()}"}"""
            fun ev(group: String, seq: Int, type: String, payload: String) =
                "($group, $seq, '${UUID.randomUUID()}', '$type', '$payload', :u, now())"
            sql("INSERT INTO $schema.events (group_id, seq, client_id, type, payload, actor_user_id, created_at) VALUES " + listOf(
                ev(":g", 1, "expense.deleted", """{"expenseId": "${xs[0]}", "movedTo": $moved}"""),
                ev(":g", 2, "expense.restored", """{"expenseId": "${xs[0]}"}"""),
                ev(":g", 3, "expense.deleted", """{"expenseId": "${xs[1]}", "movedTo": $moved}"""),
                ev(":g", 4, "expense.deleted", """{"expenseId": "${xs[2]}", "movedTo": null}"""),
                ev(":o", 1, "expense.deleted", """{"expenseId": "${xs[4]}", "movedTo": $moved}"""),
            ).joinToString())
            migrateTo("8")
            val rows = jdbc.sql("SELECT description, moved, deleted_at IS NOT NULL FROM $schema.expenses ORDER BY description")
                .query { rs, _ -> Triple(rs.getString(1), rs.getBoolean(2), rs.getBoolean(3)) }.list()
            assertEquals(
                listOf(Triple("E0", true, true), Triple("E1", true, true), Triple("E2", false, true), Triple("E3", false, false), Triple("E4", false, false)),
                rows,
            )
        } finally {
            jdbc.sql("DROP SCHEMA IF EXISTS $schema CASCADE").update()
        }
    }
}

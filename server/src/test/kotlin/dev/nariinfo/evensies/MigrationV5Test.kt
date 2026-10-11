package dev.nariinfo.evensies

import org.flywaydb.core.Flyway
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.util.UUID
import javax.sql.DataSource
import kotlin.test.assertEquals

/** V5 on data written before Phase 3: every expense gets one payer (paid_by, amount), the new columns get defaults. */
class MigrationV5Test : IntegrationTestBase() {
    @Autowired
    private lateinit var dataSource: DataSource

    @Autowired
    private lateinit var jdbc: JdbcClient

    @Test
    fun v5BackfillsOnePayerPerExpense() {
        val schema = "v5_check"
        fun migrateTo(version: String) = Flyway.configure().dataSource(dataSource).schemas(schema).target(version).load().migrate()
        try {
            migrateTo("4")
            val user = UUID.randomUUID()
            val group = UUID.randomUUID()
            val anna = UUID.randomUUID()
            val ben = UUID.randomUUID()
            val x = UUID.randomUUID()
            for (sql in listOf(
                "INSERT INTO $schema.users (id, provider, subject, display_name) VALUES (:u, 'dev', :u, 'Anna')",
                "INSERT INTO $schema.groups (id, name, default_currency, invite_code, created_by) VALUES (:g, 'Trip', 'EUR', 'ABC234', :u)",
                "INSERT INTO $schema.members (id, group_id, user_id, name) VALUES (:a, :g, :u, 'Anna'), (:b, :g, NULL, 'Ben')",
                "INSERT INTO $schema.expenses (id, group_id, description, amount, currency, paid_by, date) VALUES (:x, :g, 'Taxi', 1234, 'EUR', :b, '2026-10-01')",
            )) {
                jdbc.sql(sql).param("u", user).param("g", group).param("a", anna).param("b", ben).param("x", x).update()
            }
            migrateTo("5")

            val payers = jdbc.sql("SELECT expense_id, member_id, amount, position FROM $schema.expense_payers")
                .query { rs, _ -> listOf(rs.getString(1), rs.getString(2), rs.getLong(3), rs.getInt(4)) }.list()
            assertEquals(listOf(listOf(x.toString(), ben.toString(), 1234L, 0)), payers)
            val expense = jdbc.sql("SELECT refund, split FROM $schema.expenses").query { rs, _ -> rs.getBoolean(1) to rs.getString(2) }.single()
            assertEquals(false to null, expense)
            val settings = jdbc.sql("SELECT simplify_debts, default_split FROM $schema.groups").query { rs, _ -> rs.getBoolean(1) to rs.getString(2) }.single()
            assertEquals(true to null, settings)
        } finally {
            jdbc.sql("DROP SCHEMA IF EXISTS $schema CASCADE").update()
        }
    }
}

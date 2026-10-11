package dev.nariinfo.evensies.payment

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import java.sql.ResultSet
import java.util.UUID

@Repository
class PaymentMethodRepository(private val jdbc: JdbcClient) {
    private val mapper = { rs: ResultSet, _: Int ->
        PaymentMethod(rs.getString("type"), rs.getString("value"), rs.getString("holder"), rs.getString("bank"), rs.getString("bic"))
    }

    fun list(userId: UUID): List<PaymentMethod> =
        jdbc.sql("SELECT * FROM payment_methods WHERE user_id = :u ORDER BY position").param("u", userId).query(mapper).list()

    /** Call inside a transaction. */
    fun replace(userId: UUID, methods: List<PaymentMethod>) {
        deleteByUser(userId)
        for ((i, m) in methods.withIndex()) {
            jdbc.sql("INSERT INTO payment_methods (user_id, position, type, value, holder, bank, bic) VALUES (:u, :pos, :type, :value, :holder, :bank, :bic)")
                .param("u", userId).param("pos", i).param("type", m.type).param("value", m.value)
                .param("holder", m.holder).param("bank", m.bank).param("bic", m.bic).update()
        }
    }

    fun deleteByUser(userId: UUID) {
        jdbc.sql("DELETE FROM payment_methods WHERE user_id = :u").param("u", userId).update()
    }

    /** Methods of the group's linked, non-removed members, keyed by member id (members without methods are absent). */
    fun listForGroup(groupId: UUID): Map<String, List<PaymentMethod>> = jdbc.sql(
        """
        SELECT m.id AS member_id, pm.* FROM members m JOIN payment_methods pm ON pm.user_id = m.user_id
        WHERE m.group_id = :g AND m.removed = false ORDER BY m.created_at, m.id, pm.position
        """
    ).param("g", groupId).query { rs, i -> rs.getString("member_id") to mapper(rs, i) }.list().groupBy({ it.first }, { it.second })
}

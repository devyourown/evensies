package dev.nariinfo.evensies.payment

import dev.nariinfo.evensies.auth.AuthService
import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.group.GroupService
import org.springframework.security.core.Authentication
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
class PaymentMethodController(
    private val repo: PaymentMethodRepository,
    private val auth: AuthService,
    private val groups: GroupService,
) {
    @GetMapping("/me/payment-methods")
    fun mine(authentication: Authentication): List<PaymentMethod> = repo.list(authentication.userId)

    @PutMapping("/me/payment-methods")
    @Transactional
    fun replace(authentication: Authentication, @RequestBody body: List<PaymentMethod>): List<PaymentMethod> {
        val userId = authentication.userId
        auth.me(userId) // 401 for deleted accounts
        val methods = PaymentMethods.validate(body)
        repo.replace(userId, methods)
        return methods
    }

    @GetMapping("/groups/{id}/payment-methods")
    fun group(authentication: Authentication, @PathVariable id: UUID): Map<String, List<PaymentMethod>> {
        groups.requireMember(id, authentication.userId)
        return repo.listForGroup(id)
    }
}

package dev.nariinfo.evensies.group

import dev.nariinfo.evensies.config.userId
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
@RequestMapping("/groups")
class GroupController(private val groups: GroupService) {
    @PostMapping
    fun create(auth: Authentication, @RequestBody req: CreateGroupRequest): GroupDto = groups.create(auth.userId, req)

    @GetMapping
    fun list(auth: Authentication): List<GroupSummaryDto> = groups.list(auth.userId)

    @GetMapping("/{id}")
    fun get(auth: Authentication, @PathVariable id: UUID): GroupDto = groups.get(id, auth.userId)

    @PostMapping("/{id}/invite/rotate")
    fun rotate(auth: Authentication, @PathVariable id: UUID): InviteCodeDto = groups.rotateInvite(id, auth.userId)
}

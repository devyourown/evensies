package dev.nariinfo.tally.export

import dev.nariinfo.tally.common.ApiException
import dev.nariinfo.tally.config.userId
import dev.nariinfo.tally.group.GroupService
import dev.nariinfo.tally.sync.GroupStateStore
import dev.nariinfo.tally.sync.SnapshotService
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.multipart.MultipartFile
import java.util.UUID

@RestController
@RequestMapping("/groups/{id}")
class ExportController(
    private val groups: GroupService,
    private val snapshots: SnapshotService,
    private val stateStore: GroupStateStore,
    private val importer: SplitwiseImporter,
) {
    @GetMapping("/export")
    fun export(auth: Authentication, @PathVariable id: UUID, @RequestParam(defaultValue = "json") format: String): ResponseEntity<Any> =
        when (format) {
            "json" -> ResponseEntity.ok(snapshots.snapshot(id, auth.userId))
            "csv" -> {
                groups.requireMember(id, auth.userId)
                ResponseEntity.ok().contentType(MediaType.parseMediaType("text/csv; charset=utf-8"))
                    .header("Content-Disposition", "attachment; filename=\"tally-$id.csv\"")
                    .body(CsvExporter.export(stateStore.load(id)))
            }
            else -> throw ApiException.badRequest("VALIDATION", "format must be json or csv")
        }

    @PostMapping("/import/splitwise", consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    fun importSplitwise(auth: Authentication, @PathVariable id: UUID, @RequestParam file: MultipartFile): ImportResult {
        groups.requireMember(id, auth.userId)
        return importer.import(id, auth.userId, file.bytes)
    }
}

package dev.nariinfo.evensies.export

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.group.GroupService
import dev.nariinfo.evensies.storage.AttachmentController
import dev.nariinfo.evensies.storage.FileStore
import dev.nariinfo.evensies.sync.GroupStateStore
import dev.nariinfo.evensies.sync.SnapshotService
import jakarta.servlet.http.HttpServletResponse
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
import tools.jackson.databind.ObjectMapper
import java.nio.file.Files
import java.util.UUID
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

@RestController
@RequestMapping("/groups/{id}")
class ExportController(
    private val groups: GroupService,
    private val snapshots: SnapshotService,
    private val stateStore: GroupStateStore,
    private val importer: SplitwiseImporter,
    private val files: FileStore,
    private val mapper: ObjectMapper,
) {
    @GetMapping("/export")
    fun export(auth: Authentication, @PathVariable id: UUID, @RequestParam(defaultValue = "json") format: String): ResponseEntity<Any> =
        when (format) {
            "json" -> ResponseEntity.ok(snapshots.snapshot(id, auth.userId))
            "csv" -> {
                groups.requireMember(id, auth.userId)
                ResponseEntity.ok().contentType(MediaType.parseMediaType("text/csv; charset=utf-8"))
                    .header("Content-Disposition", "attachment; filename=\"evensies-$id.csv\"")
                    .body(CsvExporter.export(stateStore.load(id)))
            }
            else -> throw ApiException.badRequest("VALIDATION", "format must be json, csv or zip")
        }

    /**
     * Phase 7 "ZIP with receipts": `group.json` (the format=json body) plus `receipts/{id}.jpg` for every receipt not
     * deleted, also on deleted expenses; a missing file is skipped. The member check runs before anything is written,
     * then the ZIP streams straight into the response (on this request thread: an async StreamingResponseBody dispatch
     * would not be authenticated again by the stateless JWT filter).
     */
    @GetMapping("/export", params = ["format=zip"])
    fun zip(auth: Authentication, @PathVariable id: UUID, response: HttpServletResponse) {
        val snapshot = snapshots.snapshot(id, auth.userId)
        response.contentType = "application/zip"
        response.setHeader("Content-Disposition", "attachment; filename=\"evensies-$id.zip\"")
        val zip = ZipOutputStream(response.outputStream)
        zip.putNextEntry(ZipEntry("group.json"))
        zip.write(mapper.writeValueAsBytes(snapshot))
        for (a in snapshot.attachments.filterNot { it.deleted }) {
            val path = files.path(AttachmentController.keys(id, UUID.fromString(a.id)).first) ?: continue
            zip.putNextEntry(ZipEntry("receipts/${a.id}.jpg"))
            Files.copy(path, zip)
        }
        zip.finish()
    }

    @PostMapping("/import/splitwise", consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    fun importSplitwise(auth: Authentication, @PathVariable id: UUID, @RequestParam file: MultipartFile): ImportResult {
        groups.requireMember(id, auth.userId)
        return importer.import(id, auth.userId, file.bytes)
    }
}

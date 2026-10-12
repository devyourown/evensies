package dev.nariinfo.evensies.storage

import dev.nariinfo.evensies.config.AppProperties
import org.springframework.stereotype.Component
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption.ATOMIC_MOVE
import java.nio.file.StandardCopyOption.REPLACE_EXISTING

/**
 * Uploaded files under `EVENSIES_STORAGE_DIR` (docs/API.md "프로필 사진"). Keys are built only from UUIDs Spring has
 * already parsed (`avatars/{userId}.jpg`; Phase 7 `attachments/…`, Phase 10 `covers/…`), so no path traversal.
 * ponytail: local disk only; move to S3-compatible storage (proposed with its cost) when the disk passes about 70%.
 */
@Component
class FileStore(props: AppProperties) {
    private val root: Path = Path.of(props.storageDir).toAbsolutePath().normalize()

    /** A reader never sees half a file: temp file in the same directory, then an atomic rename over the old one. */
    fun write(key: String, bytes: ByteArray) {
        val target = root.resolve(key)
        Files.createDirectories(target.parent)
        val tmp = Files.createTempFile(target.parent, ".upload", ".tmp")
        try {
            Files.write(tmp, bytes)
            Files.move(tmp, target, ATOMIC_MOVE, REPLACE_EXISTING)
        } finally {
            Files.deleteIfExists(tmp)
        }
    }

    fun path(key: String): Path? = root.resolve(key).takeIf(Files::isRegularFile)

    fun delete(key: String) {
        Files.deleteIfExists(root.resolve(key))
    }

    /** Names of the entries directly in [dir] (empty when it doesn't exist); the daily sweep of covers. */
    fun children(dir: String): List<String> =
        root.resolve(dir).takeIf(Files::isDirectory)?.let { d -> Files.list(d).use { s -> s.map { it.fileName.toString() }.toList() } } ?: emptyList()
}

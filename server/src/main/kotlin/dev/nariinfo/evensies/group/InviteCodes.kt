package dev.nariinfo.evensies.group

import java.security.SecureRandom

/**
 * Invite codes are 6 characters from an alphabet without look-alikes (no 0/O, 1/I/L), so they can be read aloud
 * and typed by hand. 31^6 ≈ 887 million codes; together with the per-IP rate limit on the invite endpoints this
 * makes guessing a group's code impractical. Older 10-character codes stay valid.
 */
object InviteCodes {
    const val ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"
    const val LENGTH = 6
    private val random = SecureRandom()

    fun generate(): String = buildString(LENGTH) { repeat(LENGTH) { append(ALPHABET[random.nextInt(ALPHABET.length)]) } }

    /** What users type or paste: any case, with spaces or hyphens ("k7p-4qx " → "K7P4QX"). */
    fun normalize(input: String): String = input.uppercase().filter { it in 'A'..'Z' || it in '0'..'9' }
}

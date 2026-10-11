package dev.nariinfo.evensies

import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.group.InviteCodes
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class InviteCodesTest {
    @Test
    fun generatedCodesUseTheUnambiguousAlphabet() {
        val codes = List(2_000) { InviteCodes.generate() }
        assertTrue(codes.all { c -> c.length == 6 && c.all { it in InviteCodes.ALPHABET } })
        assertFalse(codes.any { c -> c.any { it in "01ILO" } })
        assertTrue(codes.toSet().size > 1_990, "codes should practically never repeat")
    }

    @Test
    fun normalizeAcceptsWhatPeopleType() {
        assertEquals("K7P4QX", InviteCodes.normalize(" k7p-4qx "))
        assertEquals("K7P4QX", InviteCodes.normalize("K7P 4QX"))
        assertEquals("5C934X86YE", InviteCodes.normalize("5c934x86ye")) // legacy 10-char codes still work
    }

    @Test
    fun rateLimiterBlocksAfterCapacityPerKey() {
        val limiter = RateLimiter(capacity = 3.0, refillPerSecond = 0.0)
        assertTrue((1..3).all { limiter.tryConsume("1.2.3.4") })
        assertFalse(limiter.tryConsume("1.2.3.4"))
        assertTrue(limiter.tryConsume("5.6.7.8"), "other keys are not affected")
    }
}

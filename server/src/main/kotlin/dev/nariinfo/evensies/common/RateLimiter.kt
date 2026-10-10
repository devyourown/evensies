package dev.nariinfo.evensies.common

import org.springframework.stereotype.Component
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/** Token bucket per user: 120 events/minute. In-memory, so per server instance. */
@Component
class RateLimiter(private val capacity: Double = 120.0, private val refillPerSecond: Double = 2.0) {
    private class Bucket(var tokens: Double, var lastNanos: Long)

    private val buckets = ConcurrentHashMap<UUID, Bucket>()

    fun tryConsume(userId: UUID, n: Int): Boolean {
        val bucket = buckets.computeIfAbsent(userId) { Bucket(capacity, System.nanoTime()) }
        synchronized(bucket) {
            val now = System.nanoTime()
            bucket.tokens = minOf(capacity, bucket.tokens + (now - bucket.lastNanos) / 1e9 * refillPerSecond)
            bucket.lastNanos = now
            if (bucket.tokens < n) return false
            bucket.tokens -= n
            return true
        }
    }
}

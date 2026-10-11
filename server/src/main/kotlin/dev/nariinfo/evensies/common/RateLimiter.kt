package dev.nariinfo.evensies.common

import org.springframework.stereotype.Component
import java.util.concurrent.ConcurrentHashMap

/**
 * Token bucket per key (user id for event pushes, client IP for invite lookups). Default: 120 per minute.
 * ponytail: in-memory and never evicted, so per instance and grows with distinct keys; move to Redis or add
 * eviction if the server is scaled out or sees many distinct IPs.
 */
@Component
class RateLimiter(private val capacity: Double = 120.0, private val refillPerSecond: Double = 2.0) {
    private class Bucket(var tokens: Double, var lastNanos: Long)

    private val buckets = ConcurrentHashMap<Any, Bucket>()

    fun tryConsume(key: Any, n: Int = 1): Boolean {
        val bucket = buckets.computeIfAbsent(key) { Bucket(capacity, System.nanoTime()) }
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

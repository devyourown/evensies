package dev.nariinfo.evensies

import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors

/**
 * Stand-in for Frankfurter v2 (`GET /v2/rates?base=EUR&date=`). IntegrationTestBase points `evensies.fx.url` here, so
 * no test reaches the network. [respond] maps the asked date to (status, body); [delayMillis] simulates a slow source.
 */
object FxStub {
    @Volatile var respond: (String) -> Pair<Int, String> = { 200 to table(it) }
    @Volatile var delayMillis = 0L
    /** The `date` of every request, in order. */
    val requests = CopyOnWriteArrayList<String>()

    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0).apply {
        executor = Executors.newCachedThreadPool { r -> Thread(r).apply { isDaemon = true } }
        createContext("/v2/rates") { ex ->
            val date = Regex("(?:^|&)date=([^&]*)").find(ex.requestURI.query.orEmpty())?.groupValues?.get(1).orEmpty()
            requests += date
            Thread.sleep(delayMillis)
            val (status, body) = respond(date)
            val bytes = body.toByteArray()
            ex.responseHeaders.add("Content-Type", "application/json")
            ex.sendResponseHeaders(status, bytes.size.toLong())
            ex.responseBody.use { it.write(bytes) }
        }
        start()
    }

    /** With a trailing `/`, which FxService must trim. */
    val url get() = "http://127.0.0.1:${server.address.port}/v2/"

    fun reset() {
        respond = { 200 to table(it) }
        delayMillis = 0
        requests.clear()
    }

    /**
     * Frankfurter's shape: per-quote dates differ (JPY a day older), EUR→EUR is included, and codes we don't list (XAU,
     * CNH) or a 0 rate must be dropped. USD carries the asked day so tests can tell rows apart.
     */
    fun table(date: String, usd: Double = 1.1217): String = """
        [{"date":"$date","base":"EUR","quote":"EUR","rate":1.0},
         {"date":"$date","base":"EUR","quote":"USD","rate":$usd},
         {"date":"${java.time.LocalDate.parse(date).minusDays(1)}","base":"EUR","quote":"JPY","rate":177.51},
         {"date":"$date","base":"EUR","quote":"KWD","rate":0.34691},
         {"date":"$date","base":"EUR","quote":"XAU","rate":0.00028},
         {"date":"$date","base":"EUR","quote":"CNH","rate":8.3},
         {"date":"$date","base":"EUR","quote":"ZAR","rate":0}]
    """.trimIndent()
}

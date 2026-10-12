package dev.nariinfo.evensies

import org.springframework.boot.test.context.TestConfiguration
import org.springframework.boot.testcontainers.service.connection.ServiceConnection
import org.springframework.context.annotation.Bean
import org.testcontainers.postgresql.PostgreSQLContainer
import org.testcontainers.utility.DockerImageName

@TestConfiguration(proxyBeanMethods = false)
class TestcontainersConfiguration {
    @Bean
    @ServiceConnection
    fun postgresContainer(): PostgreSQLContainer =
        // Data in memory: several test servers (contexts) run at once, and a near-full Docker disk then broke them.
        PostgreSQLContainer(DockerImageName.parse("postgres:16-alpine")).withTmpFs(mapOf("/var/lib/postgresql/data" to "rw"))
}

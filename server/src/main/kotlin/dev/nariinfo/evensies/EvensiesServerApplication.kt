package dev.nariinfo.evensies

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.ConfigurationPropertiesScan
import org.springframework.boot.runApplication
import org.springframework.boot.security.autoconfigure.UserDetailsServiceAutoConfiguration
import org.springframework.scheduling.annotation.EnableScheduling

// Bearer tokens only: no in-memory user, so no "Using generated security password" line at startup.
@SpringBootApplication(exclude = [UserDetailsServiceAutoConfiguration::class])
@ConfigurationPropertiesScan
@EnableScheduling
class EvensiesServerApplication

fun main(args: Array<String>) {
	runApplication<EvensiesServerApplication>(*args)
}

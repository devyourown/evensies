package dev.nariinfo.evensies

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.ConfigurationPropertiesScan
import org.springframework.boot.runApplication

@SpringBootApplication
@ConfigurationPropertiesScan
class EvensiesServerApplication

fun main(args: Array<String>) {
	runApplication<EvensiesServerApplication>(*args)
}

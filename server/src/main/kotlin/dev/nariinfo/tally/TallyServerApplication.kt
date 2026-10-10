package dev.nariinfo.tally

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.ConfigurationPropertiesScan
import org.springframework.boot.runApplication

@SpringBootApplication
@ConfigurationPropertiesScan
class TallyServerApplication

fun main(args: Array<String>) {
	runApplication<TallyServerApplication>(*args)
}

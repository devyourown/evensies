package dev.nariinfo.tally

import org.springframework.boot.fromApplication
import org.springframework.boot.with


fun main(args: Array<String>) {
	fromApplication<TallyServerApplication>().with(TestcontainersConfiguration::class).run(*args)
}

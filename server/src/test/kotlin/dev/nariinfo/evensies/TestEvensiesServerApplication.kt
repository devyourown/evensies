package dev.nariinfo.evensies

import org.springframework.boot.fromApplication
import org.springframework.boot.with


fun main(args: Array<String>) {
	fromApplication<EvensiesServerApplication>().with(TestcontainersConfiguration::class).run(*args)
}

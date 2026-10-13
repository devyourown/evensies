plugins {
	// Downloads JDK 21 for the toolchain (build.gradle.kts) when none is installed.
	id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "evensies-server"

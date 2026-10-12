package dev.nariinfo.evensies.config

import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

/**
 * The web app (docs/API.md "웹 앱"): the Flutter build sits in `static/app/` (put there by the Docker image), served by
 * Spring's static handler with `Cache-Control: no-cache` (application.yml). Its routes are hash URLs, so only the
 * entry points need mapping.
 */
@Configuration
class WebConfig : WebMvcConfigurer {
    override fun addViewControllers(registry: ViewControllerRegistry) {
        registry.addRedirectViewController("/", "/app/")
        registry.addRedirectViewController("/app", "/app/")
        registry.addViewController("/app/").setViewName("forward:/app/index.html")
    }
}

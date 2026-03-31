#' Construct a shiny.webawesome page
#'
#' Creates a minimal full-page HTML scaffold for Shiny applications that use
#' Web Awesome components. `wa_page()` attaches the package dependency once at
#' page level and temporarily suppresses duplicate wrapper-level attachment
#' while evaluating its children.
#'
#' This is a package-level Shiny helper, NOT a wrapper for the upstream
#' Web Awesome Pro `wa-page` component. It is an explicit exception to the
#' usual upstream-mirroring rule because it follows Shiny's page-helper model
#' (`fluidPage()`, etc.) for dependency attachment and full-page scaffolding.
#'
#' @param ... UI content to place in the page body.
#' @param title Optional page title.
#' @param lang Optional HTML `lang` attribute for the page.
#' @param body_class Optional CSS class string for the page body.
#'
#' @return An HTML page scaffold with the shiny.webawesome dependency attached.
#'
#' @export
#'
#' @examples
#' if (interactive()) {
#'   wa_page(
#'     title = "shiny.webawesome",
#'     wa_card("Hello from Web Awesome")
#'   )
#' }
# nolint start: object_usage_linter.
wa_page <- function(...,
                    title = NULL,
                    lang = NULL,
                    body_class = NULL) {
  content <- .wa_without_dependency(htmltools::tagList(...))

  head_children <- list()
  if (!is.null(title)) {
    head_children <- c(head_children, list(htmltools::tags$title(title)))
  }

  head_tag <- do.call(htmltools::tags$head, head_children)

  page <- htmltools::tags$html(
    lang = lang,
    head_tag,
    htmltools::tags$body(
      class = body_class,
      content
    )
  )

  htmltools::attachDependencies(page, .wa_dependency())
}
# nolint end

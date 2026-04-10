#' Construct a shiny.webawesome page
#'
#' Creates a minimal full-page HTML scaffold for Shiny applications that use
#' Web Awesome components. `webawesomePage()` attaches the package dependency
#' once at page level and temporarily suppresses duplicate wrapper-level
#' attachment while evaluating its children. This function serves an entirely
#' different role from the upstream component `wa_page()`.
#'
#' This is a package-level Shiny helper that follows Shiny's page-helper model
#' ([`fluidPage()`](https://rdrr.io/cran/shiny/man/fluidPage.html), etc.) for
#' dependency attachment and full-page scaffolding.
#' It is intentionally separate from the upstream `wa-page` component wrapper.
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
#'   webawesomePage(
#'     title = "shiny.webawesome",
#'     wa_card("Hello from Web Awesome")
#'   )
#' }
# nolint start: object_usage_linter.
# nolint start: object_name_linter.
webawesomePage <- function(...,
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
# nolint end: object_name_linter.
# nolint end

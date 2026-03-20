#' Construct a shiny.webawesome page
#'
#' Creates a minimal full-page HTML scaffold for Shiny applications that use
#' Web Awesome components. `wa_page()` attaches the package dependency once at
#' page level and temporarily suppresses duplicate wrapper-level attachment
#' while evaluating its children.
#'
#' This is a package-level Shiny helper, not a wrapper for the upstream
#' Web Awesome Pro `wa-page` component.
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
#'     htmltools::tags$`wa-card`("Hello")
#'   )
#' }
# nolint start: object_usage_linter.
wa_page <- function(...,
                    title = NULL,
                    lang = NULL,
                    body_class = NULL) {
  .wa_page_impl(
    ...,
    title = title,
    lang = lang,
    body_class = body_class
  )
}
# nolint end

#' Construct a shiny.webawesome container
#'
#' Creates a convenience `<div>` container for layouts and utility-class usage
#' within the shiny.webawesome package API. `wa_container()` is complementary
#' to `htmltools::tags$div()` and is not a wrapper for an upstream Web Awesome
#' component.
#'
#' The helper attaches the shiny.webawesome dependency so Web Awesome utility
#' classes can be used even when no generated component wrappers appear in the
#' same UI subtree.
#'
#' @param ... UI children and additional HTML attributes for the container.
#' @param id Optional DOM `id` attribute.
#' @param class Optional CSS class string.
#' @param style Optional inline CSS style string.
#'
#' @return A `<div>` tag with the shiny.webawesome dependency attached.
#'
#' @export
#'
#' @examples
#' wa_container(
#'   class = "wa-stack",
#'   wa_card("Hello")
#' )
# nolint start: object_usage_linter.
wa_container <- function(...,
                         id = NULL,
                         class = NULL,
                         style = NULL) {
  tag <- htmltools::tags$div(
    ...,
    id = id,
    class = class,
    style = style
  )

  .wa_attach_dependency(tag)
}
# nolint end

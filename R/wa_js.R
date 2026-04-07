#' Register a small JavaScript snippet with the page
#'
#' Adds one inline JavaScript snippet to the page and attaches the
#' shiny.webawesome dependency.
#'
#' `wa_js()` is a small package-level helper for app-local browser glue that
#' should remain easy to see from the surrounding Shiny code. Typical uses
#' include listening for browser-side events, reading live component
#' properties, and publishing values back to Shiny with
#' `Shiny.setInputValue()`.
#'
#' A typical property-read pattern is:
#'
#' 1. find the browser element by DOM `id`
#' 2. read the live property in JavaScript
#' 3. publish the value with `Shiny.setInputValue()`
#' 4. consume the published value in Shiny as an ordinary input
#'
#' This helper is intentionally narrow. It accepts a scalar JavaScript string
#' and injects it into the rendered page. For larger or shared scripts, prefer
#' standard Shiny asset patterns such as `www/` files and `tags$script()`.
#'
#' @param code One non-missing JavaScript string to inject into the page.
#'
#' @return A `<script>` tag with the shiny.webawesome dependency attached.
#'
#' @export
#'
#' @examples
#' if (interactive()) {
#'   ui <- webawesomePage(
#'     wa_js("
#'       function publishDetailsOpen() {
#'         const details = document.getElementById('details');
#'
#'         if (!details ||
#'             !window.Shiny ||
#'             typeof window.Shiny.setInputValue !== 'function') {
#'           return;
#'         }
#'
#'         window.Shiny.setInputValue(
#'           'details_open_state',
#'           details.open,
#'           { priority: 'event' }
#'         );
#'       }
#'
#'       document.addEventListener('shiny:connected', publishDetailsOpen, {
#'         once: true
#'       });
#'
#'       document.addEventListener('wa-show', function(event) {
#'         if (event.target.id === 'details') {
#'           publishDetailsOpen();
#'         }
#'       });
#'
#'       document.addEventListener('wa-hide', function(event) {
#'         if (event.target.id === 'details') {
#'           publishDetailsOpen();
#'         }
#'       });
#'     "),
#'     wa_details(
#'       input_id = "details",
#'       summary = "More information",
#'       "Details body"
#'     ),
#'     shiny::verbatimTextOutput("details_state")
#'   )
#'
#'   server <- function(input, output, session) {
#'     output$details_state <- shiny::renderPrint({
#'       input$details_open_state
#'     })
#'   }
#'
#'   shiny::shinyApp(ui, server)
#' }
#'
#' if (interactive()) {
#'   js_file <- tempfile(fileext = ".js")
#'   writeLines(
#'     c(
#'       "document.addEventListener('wa-show', function(event) {",
#'       "  if (event.target.id !== 'details') {",
#'       "    return;",
#'       "  }",
#'       "",
#'       "  if (window.Shiny &&",
#'       "      typeof window.Shiny.setInputValue === 'function') {",
#'       "    window.Shiny.setInputValue(",
#'       "      'details_open_state',",
#'       "      event.target.open,",
#'       "      { priority: 'event' }",
#'       "    );",
#'       "  }",
#'       "});"
#'     ),
#'     js_file
#'   )
#'
#'   js_code <- paste(readLines(js_file, warn = FALSE), collapse = "\n")
#'
#'   ui <- webawesomePage(
#'     wa_js(js_code),
#'     wa_details(
#'       input_id = "details",
#'       summary = "More information",
#'       "Details body"
#'     )
#'   )
#' }
# nolint start: object_usage_linter.
wa_js <- function(code) {
  valid_code <- is.character(code) &&
    length(code) == 1L &&
    !is.na(code) &&
    nzchar(code)
  if (!valid_code) {
    stop("`code` must be one non-missing string.", call. = FALSE)
  }

  tag <- htmltools::tags$script(htmltools::HTML(code))

  .wa_attach_dependency(tag)
}
# nolint end

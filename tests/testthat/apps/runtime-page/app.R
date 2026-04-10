library(shiny)
# Runtime harness apps load the local package in a way static linting cannot
# fully resolve outside an installed-package context.
# nolint next: object_usage_linter
library(shiny.webawesome)
source(file.path("..", "harness_helpers.R"))

ui <- webawesomePage(
  title = "wa_page Runtime Harness",
  tags$style(HTML("
    .runtime-shell {
      margin: 0 auto;
      max-width: 1100px;
      padding: 2rem 1.25rem 3rem;
    }

    .runtime-title {
      margin-bottom: 0.5rem;
      text-align: center;
    }

    .runtime-intro {
      margin: 0 auto 1.75rem;
      max-width: 52rem;
      text-align: center;
    }

    .runtime-page-state {
      background: #ffffff;
      border: 1px solid #d7dee7;
      border-radius: 1rem;
      margin-top: 1.5rem;
      padding: 1rem;
    }
  ")),
  tags$main(
    id = "runtime-top",
    class = "runtime-shell",
    tags$h1(class = "runtime-title", "wa_page Runtime Harness"),
    tags$p(
      class = "runtime-intro",
      paste(
        "This harness supports both manual browser inspection and automated",
        "shinytest2 coverage for the structural page wrapper component",
        "`wa_page()`."
      )
    ),
    wa_page(
      id = "page_component",
      navigation_placement = "end",
      header = tags$div(id = "page_header", "Page header"),
      navigation = tags$nav(id = "page_navigation", "Page navigation"),
      main_header = tags$div(id = "page_main_header", "Main header"),
      tags$div(id = "page_main_content", "Main content"),
      footer = tags$div(id = "page_footer", "Page footer")
    ),
    tags$section(
      class = "runtime-page-state",
      tags$h2("Observed Shiny State"),
      verbatimTextOutput("page_state")
    )
  )
)

server <- function(input, output, session) {
  # This helper is sourced from ../harness_helpers.R for reuse across runtime
  # harness apps, so static linting cannot resolve it here.
  # nolint start: object_usage_linter
  output$page_state <- renderText({
    format_runtime_state("component", "#page_component")
  })
  # nolint end
}

shinyApp(ui, server)

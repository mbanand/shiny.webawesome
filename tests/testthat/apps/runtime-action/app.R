library(htmltools)
library(shiny)
# Runtime harness apps load the local package in a way static linting cannot
# fully resolve outside an installed-package context.
# nolint next: object_usage_linter
library(shiny.webawesome)
source(file.path("..", "harness_helpers.R"))

sections <- list(
  list(
    title = "wa_dropdown",
    section_id = "wa_dropdown-section"
  )
)

ui <- wa_page(
  title = "Action Runtime Harness",
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
      max-width: 48rem;
      text-align: center;
    }

    .component-index-nav {
      background: #f8fafc;
      border: 1px solid #d7dee7;
      border-radius: 1rem;
      margin-bottom: 2rem;
      padding: 1.25rem;
    }

    .component-index-grid {
      display: grid;
      gap: 0.75rem;
      grid-template-columns: repeat(auto-fit, minmax(13rem, 1fr));
    }

    .component-index-link {
      background: white;
      border: 1px solid #d7dee7;
      border-radius: 0.75rem;
      color: #0f172a;
      display: block;
      font-weight: 600;
      padding: 0.75rem 0.9rem;
      text-decoration: none;
    }

    .component-index-link:hover {
      border-color: #94a3b8;
      text-decoration: underline;
    }

    .component-section {
      border-top: 1px solid #d7dee7;
      padding: 2rem 0;
      scroll-margin-top: 1.5rem;
    }

    .component-section-heading {
      align-items: baseline;
      display: flex;
      gap: 1rem;
      justify-content: space-between;
    }

    .back-to-top {
      font-size: 0.95rem;
      white-space: nowrap;
    }

    .component-description,
    .component-notes {
      max-width: 56rem;
    }

    .component-body {
      display: grid;
      gap: 1rem;
      grid-template-columns: repeat(auto-fit, minmax(20rem, 1fr));
    }

    .component-demo-panel,
    .component-state-panel {
      background: #ffffff;
      border: 1px solid #d7dee7;
      border-radius: 1rem;
      padding: 1rem;
    }
  ")),
  tags$main(
    id = "runtime-top",
    class = "runtime-shell",
    tags$h1(class = "runtime-title", "Action Runtime Harness"),
    tags$p(
      class = "runtime-intro",
      paste(
        "This harness supports both manual browser inspection and automated",
        "shinytest2 coverage for action-style and action-with-payload",
        "Web Awesome inputs."
      )
    ),
    component_index(sections),
    component_section(
      section_id = "wa_dropdown-section",
      title = "wa_dropdown",
      description = paste(
        "Select dropdown items and observe that the main Shiny input behaves",
        "like an action counter while a separate companion input tracks the",
        "latest selected value payload."
      ),
      component_tag = wa_dropdown(
        input_id = "dropdown",
        wa_dropdown_item("Alpha", id = "dropdown_item_alpha", value = "alpha"),
        wa_dropdown_item("No value", id = "dropdown_item_missing"),
        wa_dropdown_item("Empty value", id = "dropdown_item_empty", value = ""),
        trigger = wa_button("Menu", with_caret = TRUE)
      ),
      observed_output = "dropdown_state",
      notes = paste(
        "Repeated same-item selections should increment the action counter.",
        paste(
          "Missing values map to NULL, while an explicit empty string",
          "remains \"\"."
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # These helpers are sourced from ../harness_helpers.R for reuse across
  # runtime harness apps, so static linting cannot resolve them here.
  # nolint start: object_usage_linter
  output$dropdown_state <- renderText({
    paste(
      format_runtime_state("input$dropdown", input$dropdown),
      format_runtime_state("input$dropdown_value", input$dropdown_value),
      sep = "\n"
    )
  })

  observeEvent(
    list(input$dropdown, input$dropdown_value),
    ignoreInit = FALSE,
    {
      log_runtime_state(
        "dropdown",
        paste(
          format_runtime_state("input$dropdown", input$dropdown),
          format_runtime_state("input$dropdown_value", input$dropdown_value),
          sep = " | "
        )
      )
    }
  )
  # nolint end
}

shinyApp(ui, server)

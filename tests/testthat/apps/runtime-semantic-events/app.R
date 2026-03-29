library(htmltools)
library(shiny)
# Runtime harness apps load the local package in a way static linting cannot
# fully resolve outside an installed-package context.
# nolint next: object_usage_linter
library(shiny.webawesome)
source(file.path("..", "harness_helpers.R"))

make_wa_tab <- function(panel, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-tab", label),
    panel = panel
  )
}

make_wa_tab_panel <- function(name, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-tab-panel", label),
    name = name
  )
}

sections <- list(
  list(title = "wa_carousel", section_id = "wa_carousel-section"),
  list(title = "wa_details", section_id = "wa_details-section"),
  list(title = "wa_dialog", section_id = "wa_dialog-section"),
  list(title = "wa_drawer", section_id = "wa_drawer-section"),
  list(title = "wa_tab_group", section_id = "wa_tab_group-section")
)

ui <- wa_page(
  title = "Semantic Event Runtime Harness",
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
    tags$h1(class = "runtime-title", "Semantic Event Runtime Harness"),
    tags$p(
      class = "runtime-intro",
      paste(
        "This harness supports both manual browser inspection and automated",
        "shinytest2 coverage for durable semantic state driven by custom or",
        "lifecycle events."
      )
    ),
    component_index(sections),
    component_section(
      section_id = "wa_carousel-section",
      title = "wa_carousel",
      description = paste(
        "Advance the active slide and observe that the Shiny value tracks the",
        "current active slide index."
      ),
      component_tag = wa_carousel(
        input_id = "carousel",
        htmltools::tag("wa-carousel-item", "Slide 1"),
        htmltools::tag("wa-carousel-item", "Slide 2")
      ),
      observed_output = "carousel_state",
      notes = paste(
        "The current semantic contract uses the component's native 0-based",
        "active slide index."
      )
    ),
    component_section(
      section_id = "wa_details-section",
      title = "wa_details",
      description = paste(
        "Open and close the disclosure to observe that the Shiny value",
        "reflects",
        "the durable boolean open state."
      ),
      component_tag = wa_details(
        input_id = "details",
        "Details body",
        summary = "More"
      ),
      observed_output = "details_state"
    ),
    component_section(
      section_id = "wa_dialog-section",
      title = "wa_dialog",
      description = paste(
        "Show and hide the dialog to observe that the Shiny value reflects the",
        "durable boolean open state committed by the relevant lifecycle events."
      ),
      component_tag = wa_dialog(
        input_id = "dialog",
        "Dialog body",
        label = "Dialog title"
      ),
      observed_output = "dialog_state"
    ),
    component_section(
      section_id = "wa_drawer-section",
      title = "wa_drawer",
      description = paste(
        "Show and hide the drawer to observe that the Shiny value reflects the",
        "durable boolean open state committed by the relevant lifecycle events."
      ),
      component_tag = wa_drawer(
        input_id = "drawer",
        "Drawer body",
        label = "Drawer title"
      ),
      observed_output = "drawer_state"
    ),
    component_section(
      section_id = "wa_tab_group-section",
      title = "wa_tab_group",
      description = paste(
        "Switch tabs and observe that the Shiny value tracks the active tab",
        "name committed by the tab-show lifecycle event."
      ),
      component_tag = wa_tab_group(
        input_id = "tab_group",
        make_wa_tab_panel("first", "First panel"),
        make_wa_tab_panel("second", "Second panel"),
        nav = htmltools::tagList(
          make_wa_tab("first", "First"),
          make_wa_tab("second", "Second")
        )
      ),
      observed_output = "tab_group_state"
    )
  )
)

server <- function(input, output, session) {
  # These helpers are sourced from ../harness_helpers.R for reuse across
  # runtime harness apps, so static linting cannot resolve them here.
  # nolint start: object_usage_linter
  bind_runtime_state <- function(output_id, input_id) {
    output[[output_id]] <- renderText({
      format_runtime_state(
        sprintf("input$%s", input_id),
        input[[input_id]]
      )
    })

    observeEvent(input[[input_id]], ignoreInit = FALSE, {
      log_runtime_state(
        input_id,
        format_runtime_state(
          sprintf("input$%s", input_id),
          input[[input_id]]
        )
      )
    })
  }

  bind_runtime_state("carousel_state", "carousel")
  bind_runtime_state("details_state", "details")
  bind_runtime_state("dialog_state", "dialog")
  bind_runtime_state("drawer_state", "drawer")
  bind_runtime_state("tab_group_state", "tab_group")
  # nolint end
}

shinyApp(ui, server)

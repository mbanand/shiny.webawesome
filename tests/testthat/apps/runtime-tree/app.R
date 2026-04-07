library(htmltools)
library(shiny)
# Runtime harness apps load the local package in a way static linting cannot
# fully resolve outside an installed-package context.
# nolint next: object_usage_linter
library(shiny.webawesome)
source(file.path("..", "harness_helpers.R"))

sections <- list(
  list(
    title = "wa_tree",
    section_id = "wa_tree-section"
  )
)

ui <- webawesomePage(
  title = "Tree Runtime Harness",
  tags$script(HTML("
    (function() {
      const originalWarn = console.warn.bind(console);

      console.warn = function(...args) {
        originalWarn(...args);

        const message = args.map((arg) => String(arg)).join(' ');
        if (!message.includes('wa-tree')) {
          return;
        }

        window.__treeWarningCount = (window.__treeWarningCount || 0) + 1;

        if (window.Shiny && typeof window.Shiny.setInputValue === 'function') {
          window.Shiny.setInputValue(
            'tree_warning_count',
            window.__treeWarningCount,
            { priority: 'event' }
          );
          window.Shiny.setInputValue(
            'tree_warning_log',
            message,
            { priority: 'event' }
          );
        }
      };
    })();
  ")),
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

    .tree-demo-grid {
      display: grid;
      gap: 1rem;
      grid-template-columns: repeat(auto-fit, minmax(16rem, 1fr));
    }

    .tree-demo-block {
      border: 1px dashed #cbd5e1;
      border-radius: 0.75rem;
      padding: 0.9rem;
    }

    .tree-demo-block h4 {
      margin-top: 0;
    }
  ")),
  tags$main(
    id = "runtime-top",
    class = "runtime-shell",
    tags$h1(class = "runtime-title", "Tree Runtime Harness"),
    tags$p(
      class = "runtime-intro",
      paste(
        "This harness supports both manual browser inspection and automated",
        "shinytest2 coverage for the wa_tree selected-id contract and its",
        "missing-id warning behavior."
      )
    ),
    component_index(sections),
    component_section(
      section_id = "wa_tree-section",
      title = "wa_tree",
      description = paste(
        "Use the stable tree to observe selected descendant ids flowing into",
        "Shiny. Use the warning tree to observe that selected items without",
        "DOM ids are omitted from the Shiny value and trigger the warning",
        "path once."
      ),
      component_tag = tags$div(
        class = "tree-demo-grid",
        tags$div(
          class = "tree-demo-block",
          tags$h4("Stable selected-id contract"),
          wa_tree(
            input_id = "tree",
            selection = "multiple",
            wa_tree_item("Node A", id = "tree_item_a"),
            wa_tree_item("Node B", id = "tree_item_b")
          )
        ),
        tags$div(
          class = "tree-demo-block",
          tags$h4("Missing-id warning contract"),
          wa_tree(
            input_id = "tree_warning",
            selection = "multiple",
            wa_tree_item("Missing id"),
            wa_tree_item("Present id", id = "tree_warning_present")
          )
        )
      ),
      observed_output = "tree_contract_state",
      notes = paste(
        "The Shiny value is the vector of selected descendant tree-item DOM",
        "ids. Selected items without ids are omitted and trigger a warning",
        "once per input id."
      )
    )
  )
)

server <- function(input, output, session) {
  # These helpers are sourced from ../harness_helpers.R for reuse across
  # runtime harness apps, so static linting cannot resolve them here.
  # nolint start: object_usage_linter
  output$tree_contract_state <- renderText({
    paste(
      format_runtime_state("input$tree", input$tree),
      format_runtime_state("input$tree_warning", input$tree_warning),
      format_runtime_state("input$tree_warning_count", input$tree_warning_count),
      format_runtime_state("input$tree_warning_log", input$tree_warning_log),
      sep = "\n"
    )
  })

  observeEvent(
    list(
      input$tree,
      input$tree_warning,
      input$tree_warning_count,
      input$tree_warning_log
    ),
    ignoreInit = FALSE,
    {
      log_runtime_state(
        "tree",
        paste(
          format_runtime_state("input$tree", input$tree),
          format_runtime_state("input$tree_warning", input$tree_warning),
          format_runtime_state("input$tree_warning_count", input$tree_warning_count),
          format_runtime_state("input$tree_warning_log", input$tree_warning_log),
          sep = " | "
        )
      )
    }
  )
  # nolint end
}

shinyApp(ui, server)

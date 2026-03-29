# Harness helper files are sourced into runtime harness apps, so static linting
# does not see the tag helpers and output constructors in the final app scope.
# nolint start: object_usage_linter
# Format visible harness state with stable human-readable scalar and vector text.
format_runtime_state <- function(input_name, value) {
  format_runtime_value <- function(x) {
    if (is.null(x)) {
      return("NULL")
    }

    if (is.character(x) && length(x) == 1L) {
      return(sprintf('"%s"', x))
    }

    if (is.logical(x) && length(x) == 1L) {
      return(if (isTRUE(x)) "TRUE" else "FALSE")
    }

    if (length(x) == 1L) {
      return(as.character(x))
    }

    paste0(
      "c(",
      paste(vapply(x, format_runtime_value, character(1)), collapse = ", "),
      ")"
    )
  }

  sprintf("%s = %s", input_name, format_runtime_value(value))
}
# nolint end

# Emit optional server-side harness logs outside the test contract.
log_runtime_state <- function(component_name, state_text) {
  if (!isTRUE(getOption("shiny.webawesome.runtime_harness.log", FALSE))) {
    return(invisible(NULL))
  }

  message(sprintf("[%s] %s", component_name, state_text))
  invisible(NULL)
}

# Harness helper files are sourced into runtime harness apps, so static linting
# does not see the tag helpers and output constructors in the final app scope.
# nolint start: object_usage_linter
# Render the shared top-of-page component index from the ordered section list.
component_index <- function(items) {
  tags$nav(
    class = "component-index-nav",
    tags$h2("Components"),
    tags$div(
      class = "component-index-grid",
      lapply(items, function(item) {
        tags$a(
          class = "component-index-link",
          href = paste0("#", item$section_id),
          item$title
        )
      })
    )
  )
}

# Build one consistent human-usable harness section around a component contract.
component_section <- function(
  section_id,
  title,
  description,
  component_tag,
  observed_output,
  controls = NULL,
  notes = NULL
) {
  tags$section(
    id = section_id,
    class = "component-section",
    tags$div(
      class = "component-section-heading",
      tags$h2(title),
      tags$a(href = "#runtime-top", class = "back-to-top", "Back to top")
    ),
    tags$p(class = "component-description", description),
    tags$div(
      class = "component-body",
      tags$div(
        class = "component-demo-panel",
        tags$h3("Component"),
        component_tag,
        if (!is.null(controls)) {
          tags$div(class = "component-controls", controls)
        }
      ),
      tags$div(
        class = "component-state-panel",
        tags$h3("Observed Shiny State"),
        verbatimTextOutput(observed_output)
      )
    ),
    if (!is.null(notes)) {
      tags$p(class = "component-notes", tags$strong("Notes: "), notes)
    }
  )
}
# nolint end

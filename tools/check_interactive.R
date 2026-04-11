#!/usr/bin/env Rscript

# Interactive visual review helper for the shiny.webawesome finalize workflow.
#
# This file is sourceable by tests and directly executable as a top-level tool.

# nolint start: object_usage_linter.
# Return base directories inferred from the current script-loading context.
.script_base_dirs <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  command_file <- if (length(file_arg) > 0L) {
    sub("^--file=", "", tail(file_arg, 1))
  } else {
    ""
  }

  ofiles <- vapply(
    sys.frames(),
    function(frame) if (is.null(frame$ofile)) "" else frame$ofile,
    character(1)
  )
  source_file <- tail(ofiles[nzchar(ofiles)], 1)
  known_files <- c(command_file, source_file)
  known_files <- known_files[nzchar(known_files) & known_files != "-"]

  unique(c(
    vapply(
      known_files,
      function(path) {
        dirname(normalizePath(path, winslash = "/", mustWork = FALSE))
      },
      character(1)
    ),
    "."
  ))
}

.interactive_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .interactive_tool_base_dirs
  candidates <- c(
    unlist(lapply(base_dirs, function(dir) file.path(dir, "cli_ui.R"))),
    unlist(
      lapply(base_dirs, function(dir) file.path(dir, "tools", "cli_ui.R"))
    ),
    unlist(lapply(base_dirs, function(dir) file.path(dir, "..", "cli_ui.R"))),
    file.path("tools", "cli_ui.R"),
    "cli_ui.R"
  )
  existing <- unique(candidates[file.exists(candidates)])

  if (length(existing) > 0L) {
    source(existing[[1]])
  }
}

.bootstrap_cli_ui()
rm(.bootstrap_cli_ui)

# Return the CLI usage string for the interactive review tool.
.check_interactive_usage <- function() {
  paste(
    "Usage: ./tools/check_interactive.R",
    "[--root <path>] [--host <address>] [--port <integer>] [--help]"
  )
}

# Return the short CLI description for the interactive review tool.
.check_interactive_description <- function() {
  paste(
    "Launch the representative Shiny app used for the manual visual",
    "review gate before strict finalize."
  )
}

# List supported CLI options for the interactive review tool.
.check_interactive_options <- function() {
  c(
    paste(
      "--root <path>     Repository root.",
      "Defaults to the current directory."
    ),
    "--host <address>   Listen host passed to shiny::runApp().",
    paste(
      "--port <integer>  Optional listen port.",
      "When omitted, Shiny chooses its usual default."
    ),
    "--help, -h         Print this help text."
  )
}

# Print the CLI help text for the interactive review tool.
.print_check_interactive_help <- function() {
  writeLines(
    c(
      .check_interactive_description(),
      "",
      .check_interactive_usage(),
      "",
      "Options:",
      .check_interactive_options()
    )
  )
}

# Define default CLI option values for the interactive review tool.
.check_interactive_defaults <- function() {
  list(
    root = ".",
    host = "127.0.0.1",
    port = NA_integer_,
    help = FALSE
  )
}

# Parse command-line arguments for the interactive review tool.
.parse_check_interactive_args <- function(args) {
  options <- .check_interactive_defaults()
  skip_next <- FALSE

  for (i in seq_along(args)) {
    if (skip_next) {
      skip_next <- FALSE
      next
    }

    arg <- args[[i]]

    if (arg %in% c("--help", "-h")) {
      options$help <- TRUE
      next
    }

    if (arg %in% c("--root", "--host", "--port")) {
      if (i == length(args)) {
        stop(sprintf("Missing value for %s.", arg), call. = FALSE)
      }

      value <- args[[i + 1L]]

      if (identical(arg, "--root")) {
        options$root <- value
      } else if (identical(arg, "--host")) {
        options$host <- value
      } else {
        port <- suppressWarnings(as.integer(value))
        if (is.na(port) || port < 1L) {
          stop("`--port` must be a positive integer.", call. = FALSE)
        }
        options$port <- port
      }

      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--root=")) {
      options$root <- sub("^--root=", "", arg)
      next
    }

    if (startsWith(arg, "--host=")) {
      options$host <- sub("^--host=", "", arg)
      next
    }

    if (startsWith(arg, "--port=")) {
      port <- suppressWarnings(as.integer(sub("^--port=", "", arg)))
      if (is.na(port) || port < 1L) {
        stop("`--port` must be a positive integer.", call. = FALSE)
      }
      options$port <- port
      next
    }

    stop(
      paste0(
        "Unknown argument: ",
        arg,
        "\n",
        .check_interactive_usage()
      ),
      call. = FALSE
    )
  }

  options
}

# Check whether a path looks like the repository root.
.is_repo_root <- function(root) {
  required_paths <- c("DESCRIPTION", "projectdocs", "tools")
  all(file.exists(file.path(root, required_paths)))
}

# Load the local package and required tool-time dependencies.
.load_review_packages <- function(root) {
  packages <- c("devtools", "htmltools", "shiny")
  missing <- packages[
    !vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  ]

  if (length(missing) > 0L) {
    stop(
      paste(
        "The interactive review tool requires:",
        paste(sprintf("`%s`", missing), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  devtools::load_all(root, quiet = TRUE, export_all = FALSE)
  invisible(TRUE)
}

# Return one exported function from the loaded shiny.webawesome namespace.
.wa_export <- function(name) {
  getExportedValue("shiny.webawesome", name)
}

# Format one visible runtime-state line.
.format_runtime_state <- function(input_name, value) {
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

# Emit one server-side log line for interactive review activity.
.log_review_state <- function(component_name, state_text) {
  message(sprintf("[interactive:%s] %s", component_name, state_text))
  invisible(NULL)
}

# Return the supported visual-review themes and their root HTML classes.
.interactive_theme_specs <- function() {
  list(
    default = list(
      label = "Default",
      class = "wa-theme-default wa-palette-default wa-brand-blue"
    ),
    awesome = list(
      label = "Awesome",
      class = "wa-theme-awesome wa-palette-bright wa-brand-blue"
    ),
    shoelace = list(
      label = "Shoelace",
      class = "wa-theme-shoelace wa-palette-shoelace wa-brand-blue"
    )
  )
}

# Return the requested visual-review theme name with fallback to default.
.interactive_theme_name <- function(request = NULL) {
  specs <- .interactive_theme_specs()
  default_theme <- "default"

  if (is.null(request) || is.null(request$QUERY_STRING)) {
    return(default_theme)
  }

  query <- shiny::parseQueryString(request$QUERY_STRING)
  theme <- query[["theme"]]

  if (!is.character(theme) || length(theme) != 1L || !nzchar(theme)) {
    return(default_theme)
  }

  if (!(theme %in% names(specs))) {
    return(default_theme)
  }

  theme
}

# Build the theme-switch links for the interactive review header.
.interactive_theme_links <- function(current_theme) {
  specs <- .interactive_theme_specs()

  htmltools::tags$nav(
    class = "interactive-review-themes",
    htmltools::tags$span("Review themes:"),
    htmltools::HTML("&nbsp;"),
    htmltools::tagList(lapply(
      names(specs),
      function(theme_name) {
        label <- specs[[theme_name]]$label
        if (identical(theme_name, current_theme)) {
          return(htmltools::tags$strong(label))
        }

        htmltools::tags$a(
          href = paste0("?theme=", theme_name),
          label
        )
      }
    ))
  )
}

# Build one simple review-app section.
.review_section <- function(title,
                            description,
                            component_tag,
                            observed_output = NULL,
                            controls = NULL,
                            notes = NULL) {
  htmltools::tags$section(
    class = "interactive-review-section",
    htmltools::tags$h2(title),
    htmltools::tags$p(class = "interactive-review-description", description),
    htmltools::tags$div(
      class = "interactive-review-grid",
      htmltools::tags$div(
        class = "interactive-review-panel",
        htmltools::tags$h3("Component"),
        component_tag,
        if (!is.null(controls)) {
          htmltools::tags$div(
            class = "interactive-review-controls",
            controls
          )
        }
      ),
      htmltools::tags$div(
        class = "interactive-review-panel",
        htmltools::tags$h3("Observed Shiny State"),
        if (is.null(observed_output)) {
          htmltools::tags$p("No default Shiny input contract for this sample.")
        } else {
          shiny::verbatimTextOutput(observed_output)
        }
      )
    ),
    if (!is.null(notes)) {
      htmltools::tags$p(
        class = "interactive-review-notes",
        htmltools::tags$strong("Notes: "),
        notes
      )
    }
  )
}

# Return the browser-side console bridge used by the review app.
.interactive_console_bridge <- function() {
  paste(
    "(function() {",
    "  if (window.__shinyWebawesomeReviewConsoleInstalled) {",
    "    return;",
    "  }",
    "  window.__shinyWebawesomeReviewConsoleInstalled = true;",
    "  function shouldForward(message) {",
    "    return message.indexOf('[shiny.webawesome]') !== -1 ||",
    "      message.indexOf('wa-tree') !== -1;",
    "  }",
    "  function forward(level, args) {",
    "    const message = args.map(function(arg) {",
    "      return String(arg);",
    "    }).join(' ');",
    "    if (!shouldForward(message)) {",
    "      return;",
    "    }",
    paste(
      "    if (window.Shiny &&",
      "typeof window.Shiny.setInputValue === 'function') {"
    ),
    "      window.Shiny.setInputValue(",
    "        'browser_diagnostic',",
    "        {",
    "          nonce: Date.now() + Math.random(),",
    "          level: level,",
    "          message: message",
    "        },",
    "        { priority: 'event' }",
    "      );",
    "    }",
    "  }",
    "  ['debug', 'warn', 'error'].forEach(function(level) {",
    "    const original = console[level].bind(console);",
    "    console[level] = function(...args) {",
    "      original(...args);",
    "      forward(level, args);",
    "    };",
    "  });",
    "})();",
    sep = "\n"
  )
}

# Build the representative interactive review app.
.build_interactive_review_app <- function() {
  webawesome_page <- .wa_export("webawesomePage")
  wa_button <- .wa_export("wa_button")
  wa_card <- .wa_export("wa_card")
  wa_checkbox <- .wa_export("wa_checkbox")
  wa_copy_button <- .wa_export("wa_copy_button")
  wa_details <- .wa_export("wa_details")
  wa_dialog <- .wa_export("wa_dialog")
  wa_dropdown <- .wa_export("wa_dropdown")
  wa_dropdown_item <- .wa_export("wa_dropdown_item")
  wa_input <- .wa_export("wa_input")
  wa_js <- .wa_export("wa_js")
  wa_option <- .wa_export("wa_option")
  wa_select <- .wa_export("wa_select")
  wa_set_property <- .wa_export("wa_set_property")
  wa_call_method <- .wa_export("wa_call_method")
  wa_tree <- .wa_export("wa_tree")
  wa_tree_item <- .wa_export("wa_tree_item")

  ui <- function(request) {
    theme_name <- .interactive_theme_name(request)
    theme_specs <- .interactive_theme_specs()
    theme_class <- theme_specs[[theme_name]]$class
    theme_label <- theme_specs[[theme_name]]$label

    webawesome_page(
      title = "shiny.webawesome Interactive Review",
      class = theme_class,
      wa_js(
        paste(
          "(function() {",
          "  var copyEventCount = 0;",
          "  function publishCopyEvent(event) {",
          "    if (!window.Shiny ||",
          "        typeof window.Shiny.setInputValue !== 'function') {",
          "      return;",
          "    }",
          paste(
            "    if (!event.target ||",
            "event.target.id !== 'review_copy_button') {"
          ),
          "      return;",
          "    }",
          "    copyEventCount += 1;",
          "    window.Shiny.setInputValue(",
          "      'copy_button_js_event',",
          "      [",
          "        event.type,",
          "        'target=' + event.target.id,",
          "        'count=' + copyEventCount",
          "      ].join(' | '),",
          "      { priority: 'event' }",
          "    );",
          "  }",
          "  document.addEventListener('wa-copy', publishCopyEvent);",
          "  document.addEventListener('wa-error', publishCopyEvent);",
          "})();",
          sep = "\n"
        )
      ),
      htmltools::tags$style(htmltools::HTML("
        body {
          background: #f5f7fb;
          color: #0f172a;
          font-family: Georgia, 'Times New Roman', serif;
          margin: 0;
        }

        .interactive-review-shell {
          margin: 0 auto;
          max-width: 1100px;
          padding: 2rem 1.25rem 3rem;
        }

        .interactive-review-header {
          margin-bottom: 1.5rem;
        }

        .interactive-review-header h1 {
          margin-bottom: 0.5rem;
        }

        .interactive-review-theme-state,
        .interactive-review-themes {
          margin-top: 0.75rem;
        }

        .interactive-review-themes a {
          margin-right: 0.75rem;
        }

        .interactive-review-grid {
          display: grid;
          gap: 1rem;
          grid-template-columns: repeat(auto-fit, minmax(20rem, 1fr));
        }

        .interactive-review-section {
          border-top: 1px solid #d7dee7;
          padding: 1.75rem 0;
        }

        .interactive-review-panel,
        .interactive-review-summary {
          background: #ffffff;
          border: 1px solid #d7dee7;
          border-radius: 1rem;
          padding: 1rem;
        }

        .interactive-review-panel pre,
        .interactive-review-summary pre {
          overflow-wrap: anywhere;
          white-space: pre-wrap;
          word-break: break-word;
        }

        .interactive-review-controls {
          display: flex;
          flex-wrap: wrap;
          gap: 0.75rem;
          margin-top: 1rem;
        }

        .interactive-review-notes,
        .interactive-review-description {
          max-width: 60rem;
        }

        .tree-review-grid {
          display: grid;
          gap: 1rem;
          grid-template-columns: repeat(auto-fit, minmax(16rem, 1fr));
        }

        .tree-review-block {
          border: 1px dashed #cbd5e1;
          border-radius: 0.75rem;
          padding: 0.9rem;
        }

        .tree-review-block h4 {
          margin-top: 0;
        }
      ")),
      htmltools::tags$script(htmltools::HTML(.interactive_console_bridge())),
      htmltools::tags$main(
        class = "interactive-review-shell",
        htmltools::tags$header(
          class = "interactive-review-header",
          htmltools::tags$h1("Interactive Finalize Review"),
          htmltools::tags$p(
            paste(
              "Use this app for the manual visual review before a strict",
              "finalize run. Open the local URL printed by Shiny,",
              "exercise each category once, inspect the rendered component",
              "state in the browser, and confirm that browser diagnostics and",
              "server-side logs look sane."
            )
          ),
          htmltools::tags$p(
            class = "interactive-review-theme-state",
            htmltools::tags$strong("Current theme: "),
            theme_label
          ),
          htmltools::tags$p(
            "Switch themes with the links below. Each selection reloads the",
            "page so the root HTML classes and bundled theme stylesheet are",
            "rebuilt normally."
          ),
          .interactive_theme_links(theme_name)
        ),
        htmltools::tags$div(
          class = "interactive-review-grid",
          htmltools::tags$section(
            class = "interactive-review-summary",
            htmltools::tags$h2("Review Checklist"),
            htmltools::tags$ul(
              htmltools::tags$li(
                "Presentational rendering and upgraded elements"
              ),
              htmltools::tags$li("Durable-value input binding"),
              htmltools::tags$li("Semantic event-driven binding"),
              htmltools::tags$li("Action and payload binding"),
              htmltools::tags$li("App-local wa_js() browser glue"),
              htmltools::tags$li("Command-layer debug and warning paths"),
              htmltools::tags$li("Tree selected-id and warning contract"),
              htmltools::tags$li(
                "Repeat a quick visual pass for Default, Awesome, and Shoelace"
              )
            )
          ),
          htmltools::tags$section(
            class = "interactive-review-summary",
            htmltools::tags$h2("Browser Diagnostics"),
            shiny::verbatimTextOutput("browser_diagnostics")
          )
        ),
        .review_section(
          title = "Presentational Category",
          description = paste(
            "Confirm that a representative non-input component renders",
            "cleanly and upgrades in the browser without console noise."
          ),
          component_tag = htmltools::tagAppendAttributes(
            wa_card(
              "Inspect this card for basic presentational rendering.",
              header = "Presentational sample"
            ),
            id = "presentational_card"
          ),
          observed_output = "presentational_state",
          notes = "Representative category: runtime-presentational."
        ),
        .review_section(
          title = "Semantic Durable-Value Category",
          description = paste(
            "Choose a different option and verify that the Shiny input",
            "reflects the durable selected value."
          ),
          component_tag = wa_select(
            input_id = "semantic_select",
            wa_option("Alpha", value = "alpha"),
            wa_option("Beta", value = "beta"),
            wa_option("Gamma", value = "gamma"),
            label = "Favorite value",
            hint = "Choose one"
          ),
          observed_output = "semantic_select_state",
          notes = "Representative category: runtime-semantic."
        ),
        .review_section(
          title = "Semantic Event Category",
          description = paste(
            "Open and close the disclosure directly in the browser and",
            "verify that the committed semantic state reaches Shiny."
          ),
          component_tag = wa_details(
            input_id = "semantic_details",
            "Semantic event body",
            summary = "Toggle details"
          ),
          observed_output = "semantic_details_state",
          notes = "Representative category: runtime-semantic-events."
        ),
        .review_section(
          title = "Action Category",
          description = paste(
            "Pick menu items and confirm that the main input behaves like",
            "an action counter while the companion payload input tracks",
            "the latest selected value."
          ),
          component_tag = wa_dropdown(
            input_id = "action_dropdown",
            wa_dropdown_item(
              "Alpha",
              id = "action_item_alpha",
              value = "alpha"
            ),
            wa_dropdown_item("No value", id = "action_item_missing"),
            wa_dropdown_item(
              "Empty value",
              id = "action_item_empty",
              value = ""
            ),
            trigger = wa_button(
              "action_dropdown_trigger",
              "Action menu",
              with_caret = TRUE
            )
          ),
          observed_output = "action_dropdown_state",
          notes = "Representative category: runtime-action."
        ),
        .review_section(
          title = "App-local JS Category",
          description = paste(
            "Click the copy button and confirm that the unbound browser",
            "event is bridged back to Shiny through a small `wa_js()`",
            "snippet."
          ),
          component_tag = htmltools::tagList(
            htmltools::tags$p(
              "This button copies a fixed value and publishes its browser",
              "event to Shiny with `Shiny.setInputValue()`."
            ),
            wa_copy_button(
              id = "review_copy_button",
              value = "copied-from-wa-js"
            )
          ),
          observed_output = "copy_button_js_state",
          notes = paste(
            "Representative category: app-local browser glue.",
            "`wa_js()` listens for `wa-copy` and `wa-error` on an",
            "otherwise unbound component and publishes a small event",
            "payload to Shiny."
          )
        ),
        .review_section(
          title = "Command Layer Category",
          description = paste(
            "Type in the text input and toggle the checkbox to confirm",
            "their ordinary bound Shiny state. Then use the command",
            "buttons to trigger debug logs, visible component changes,",
            "and warning paths."
          ),
          component_tag = htmltools::tagList(
            wa_dialog(
              input_id = "review_dialog",
              "Dialog body",
              label = "Interactive review dialog",
              footer = shiny::actionButton(
                "close_review_dialog_inside",
                "Close dialog from inside"
              )
            ),
            wa_input(
              input_id = "review_text_input",
              label = "Before",
              value = "alpha"
            ),
            wa_details(
              input_id = "review_details",
              "Command review details",
              summary = "Command review details"
            ),
            wa_checkbox(
              input_id = "review_checkbox",
              value = "accepted",
              "Accept terms"
            )
          ),
          controls = htmltools::tagList(
            shiny::actionButton("open_review_dialog", "Open dialog"),
            shiny::actionButton("update_review_label", "Update input label"),
            shiny::actionButton("show_review_details", "Show details"),
            shiny::actionButton(
              "set_review_validity",
              "Set checkbox validity"
            ),
            shiny::actionButton(
              "clear_review_validity",
              "Clear checkbox validity"
            ),
            shiny::actionButton(
              "missing_target_warning",
              "Warn: missing target"
            ),
            shiny::actionButton(
              "missing_method_warning",
              "Warn: missing method"
            )
          ),
          observed_output = "command_layer_state",
          notes = paste(
            "Representative category: runtime-command-layer.",
            "The validity buttons set or clear a custom browser",
            "validation message on the checkbox and then call",
            "`reportValidity()` so the browser-side validity state",
            "becomes visible."
          )
        ),
        .review_section(
          title = "Tree Warning Category",
          description = paste(
            "Select items in both trees. The stable tree should report",
            "selected ids. The warning tree should omit the missing-id",
            "item from the Shiny value and emit one browser warning."
          ),
          component_tag = htmltools::tags$div(
            class = "tree-review-grid",
            htmltools::tags$div(
              class = "tree-review-block",
              htmltools::tags$h4("Stable selected-id contract"),
              wa_tree(
                input_id = "stable_tree",
                selection = "multiple",
                wa_tree_item("Node A", id = "tree_item_a"),
                wa_tree_item("Node B", id = "tree_item_b")
              )
            ),
            htmltools::tags$div(
              class = "tree-review-block",
              htmltools::tags$h4("Missing-id warning contract"),
              suppressWarnings(
                wa_tree(
                  input_id = "warning_tree",
                  selection = "multiple",
                  wa_tree_item("Missing id"),
                  wa_tree_item("Present id", id = "tree_warning_present")
                )
              )
            )
          ),
          observed_output = "tree_state",
          notes = "Representative category: runtime-tree."
        )
      )
    )
  }

  server <- function(input, output, session) {
    browser_diagnostics <- shiny::reactiveVal(character())
    review_label_count <- shiny::reactiveVal(0L)

    append_browser_diagnostic <- function(diagnostic) {
      if (is.null(diagnostic) || is.null(diagnostic$message)) {
        return(invisible(NULL))
      }

      line <- sprintf(
        "[%s] %s",
        diagnostic$level %||% "log",
        diagnostic$message
      )
      browser_diagnostics(c(browser_diagnostics(), line))
      .log_review_state("browser", line)
      invisible(NULL)
    }

    output$browser_diagnostics <- shiny::renderText({
      diagnostics <- browser_diagnostics()
      if (length(diagnostics) == 0L) {
        return("No browser diagnostics captured yet.")
      }

      paste(utils::tail(diagnostics, 12L), collapse = "\n")
    })

    output$presentational_state <- shiny::renderText({
      paste(
        "No default Shiny input contract is expected here.",
        "Inspect the card to the left."
      )
    })

    output$semantic_select_state <- shiny::renderText({
      .format_runtime_state("input$semantic_select", input$semantic_select)
    })

    output$semantic_details_state <- shiny::renderText({
      .format_runtime_state("input$semantic_details", input$semantic_details)
    })

    output$action_dropdown_state <- shiny::renderText({
      paste(
        .format_runtime_state("input$action_dropdown", input$action_dropdown),
        .format_runtime_state(
          "input$action_dropdown_value",
          input$action_dropdown_value
        ),
        sep = "\n"
      )
    })

    output$copy_button_js_state <- shiny::renderText({
      if (is.null(input$copy_button_js_event)) {
        return(
          paste(
            "Click the copy button to observe the app-local wa_js()",
            "event payload."
          )
        )
      }

      .format_runtime_state(
        "input$copy_button_js_event",
        input$copy_button_js_event
      )
    })

    output$command_layer_state <- shiny::renderText({
      paste(
        .format_runtime_state(
          "input$review_text_input",
          input$review_text_input
        ),
        .format_runtime_state(
          "input$review_checkbox",
          input$review_checkbox
        ),
        .format_runtime_state("input$review_dialog", input$review_dialog),
        .format_runtime_state("input$review_details", input$review_details),
        sep = "\n"
      )
    })

    output$tree_state <- shiny::renderText({
      paste(
        .format_runtime_state("input$stable_tree", input$stable_tree),
        .format_runtime_state("input$warning_tree", input$warning_tree),
        sep = "\n"
      )
    })

    shiny::observeEvent(input$browser_diagnostic, ignoreInit = TRUE, {
      append_browser_diagnostic(input$browser_diagnostic)
    })

    shiny::observeEvent(input$semantic_select, ignoreInit = FALSE, {
      .log_review_state(
        "semantic_select",
        .format_runtime_state("input$semantic_select", input$semantic_select)
      )
    })

    shiny::observeEvent(input$semantic_details, ignoreInit = FALSE, {
      .log_review_state(
        "semantic_details",
        .format_runtime_state("input$semantic_details", input$semantic_details)
      )
    })

    shiny::observeEvent(
      list(input$action_dropdown, input$action_dropdown_value),
      ignoreInit = FALSE,
      {
        .log_review_state(
          "action_dropdown",
          paste(
            .format_runtime_state(
              "input$action_dropdown",
              input$action_dropdown
            ),
            .format_runtime_state(
              "input$action_dropdown_value",
              input$action_dropdown_value
            ),
            sep = " | "
          )
        )
      }
    )

    shiny::observeEvent(input$copy_button_js_event, ignoreInit = TRUE, {
      .log_review_state(
        "copy_button_js",
        .format_runtime_state(
          "input$copy_button_js_event",
          input$copy_button_js_event
        )
      )
    })

    shiny::observeEvent(
      list(
        input$review_text_input,
        input$review_checkbox,
        input$review_dialog,
        input$review_details
      ),
      ignoreInit = FALSE,
      {
        .log_review_state(
          "command_layer",
          paste(
            .format_runtime_state(
              "input$review_text_input",
              input$review_text_input
            ),
            .format_runtime_state(
              "input$review_checkbox",
              input$review_checkbox
            ),
            .format_runtime_state("input$review_dialog", input$review_dialog),
            .format_runtime_state("input$review_details", input$review_details),
            sep = " | "
          )
        )
      }
    )

    shiny::observeEvent(
      list(input$stable_tree, input$warning_tree),
      ignoreInit = FALSE,
      {
        .log_review_state(
          "tree",
          paste(
            .format_runtime_state("input$stable_tree", input$stable_tree),
            .format_runtime_state("input$warning_tree", input$warning_tree),
            sep = " | "
          )
        )
      }
    )

    shiny::observeEvent(input$open_review_dialog, {
      wa_set_property("review_dialog", "open", TRUE, session = session)
    })

    shiny::observeEvent(input$update_review_label, {
      next_count <- review_label_count() + 1L
      review_label_count(next_count)
      wa_set_property(
        "review_text_input",
        "label",
        sprintf("Updated %d from server", next_count),
        session = session
      )
    })

    shiny::observeEvent(input$close_review_dialog_inside, {
      wa_set_property("review_dialog", "open", FALSE, session = session)
    })

    shiny::observeEvent(input$show_review_details, {
      wa_call_method("review_details", "show", session = session)
    })

    shiny::observeEvent(input$set_review_validity, {
      wa_call_method(
        "review_checkbox",
        "setCustomValidity",
        args = list("Please accept the terms."),
        session = session
      )
      wa_call_method("review_checkbox", "reportValidity", session = session)
    })

    shiny::observeEvent(input$clear_review_validity, {
      wa_call_method(
        "review_checkbox",
        "setCustomValidity",
        args = list(""),
        session = session
      )
      wa_call_method("review_checkbox", "reportValidity", session = session)
    })

    shiny::observeEvent(input$missing_target_warning, {
      wa_set_property("missing_review_target", "open", TRUE, session = session)
    })

    shiny::observeEvent(input$missing_method_warning, {
      wa_call_method(
        "review_details",
        "missingMethod",
        session = session
      )
    })
  }

  shiny::shinyApp(ui, server)
}

# Launch the interactive review app used by the strict finalize visual gate.
#'
#' Loads the local package source, enables the documented warning and debug
#' options used during runtime review, and starts the representative Shiny app
#' used for the manual visual-review gate before strict finalize.
#'
#' CLI entry point:
#' `./tools/check_interactive.R --help`
#'
#' Run this tool from the repository root, open the printed local URL in a
#' browser, exercise each representative section, and stop the app with
#' `Ctrl-C` when the visual review is complete.
#'
#' @param root Repository root directory.
#' @param host Host passed to `shiny::runApp()`.
#' @param port Optional integer port passed to `shiny::runApp()`. When `NULL`,
#'   Shiny uses its usual default port selection.
#'
#' @return Invisibly returns the result of `shiny::runApp()`.
#'
#' @examples
#' \dontrun{
#' check_interactive()
#' check_interactive(port = 7448L)
#' }
check_interactive <- function(root = ".", host = "127.0.0.1", port = NULL) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  .load_review_packages(root)

  old_options <- options(
    shiny.webawesome.warnings = list(
      missing_tree_item_id = TRUE,
      command_layer = TRUE,
      command_layer_debug = TRUE
    )
  )
  on.exit(options(old_options), add = TRUE)

  app <- .build_interactive_review_app()

  message(
    "Starting interactive review app. Open the local URL printed by Shiny ",
    "and press Ctrl-C when the manual review is complete."
  )

  if (is.null(port)) {
    return(invisible(shiny::runApp(app, host = host, launch.browser = FALSE)))
  }

  invisible(shiny::runApp(
    app,
    host = host,
    port = port,
    launch.browser = FALSE
  ))
}

# Run the interactive review app from the command line.
run_check_interactive <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_check_interactive_args(args)

  if (isTRUE(options$help)) {
    .print_check_interactive_help()
    return(invisible(NULL))
  }

  .cli_run_main(function() {
    invisible(
      check_interactive(
        root = options$root,
        host = options$host,
        port = if (is.na(options$port)) NULL else options$port
      )
    )
  })
}

if (sys.nframe() == 0L) {
  run_check_interactive()
}
# nolint end

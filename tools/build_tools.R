#!/usr/bin/env Rscript

`_bootstrap_cli_ui` <- function() {
  ofiles <- vapply(
    sys.frames(),
    function(frame) if (is.null(frame$ofile)) "" else frame$ofile,
    character(1)
  )
  current_file <- tail(ofiles[nzchar(ofiles)], 1)
  current_dir <- if (length(current_file) == 0L) "." else dirname(current_file)

  candidates <- c(
    file.path("tools", "cli_ui.R"),
    file.path(current_dir, "cli_ui.R"),
    file.path(current_dir, "..", "cli_ui.R"),
    "cli_ui.R"
  )
  existing <- unique(candidates[file.exists(candidates)])

  if (length(existing) > 0L) {
    source(existing[[1]])
  }
}

`_bootstrap_cli_ui`()
rm(`_bootstrap_cli_ui`)

`_build_tools_usage` <- function() {
  paste(
    "Usage: ./tools/build_tools.R",
    "[--skip-tests] [--skip-docs] [--help]"
  )
}

`_build_tools_description` <- function() {
  "Run the top-level tool build workflow."
}

`_build_tools_option_lines` <- function() {
  c(
    "--skip-tests  Skip the tool test suite.",
    "--skip-docs   Skip tool documentation generation.",
    "--help, -h    Print this help text."
  )
}

`_print_build_tools_help` <- function() {
  writeLines(
    c(
      `_build_tools_description`(),
      "",
      `_build_tools_usage`(),
      "",
      "Options:",
      `_build_tools_option_lines`()
    )
  )
}

`_build_tools_defaults` <- function() {
  list(
    run_tests = TRUE,
    run_docs = TRUE,
    help = FALSE
  )
}

`_parse_build_tools_args` <- function(args) {
  options <- `_build_tools_defaults`()

  for (arg in args) {
    if (arg == "--skip-tests") {
      options$run_tests <- FALSE
      next
    }

    if (arg == "--skip-docs") {
      options$run_docs <- FALSE
      next
    }

    if (arg %in% c("--help", "-h")) {
      options$help <- TRUE
      next
    }

    stop(
      paste0("Unknown argument: ", arg, "\n", `_build_tools_usage`()),
      call. = FALSE
    )
  }

  options
}

`_run_build_tools_tests` <- function(ui) {
  `_cli_run_command`(
    ui = ui,
    label = "Testing tools",
    command = "./tools/test_tools.R",
    wd = ".",
    env = c(SHINY_WEBAWESOME_CLI_MODE = "plain")
  )
}

`_run_build_tools_docs` <- function(ui) {
  `_cli_run_command`(
    ui = ui,
    label = "Documenting tools",
    command = "./tools/document_tools.R",
    wd = ".",
    env = c(SHINY_WEBAWESOME_CLI_MODE = "plain")
  )
}

`_child_output_lines` <- function(run_result) {
  combined <- c(run_result$stdout, run_result$stderr)
  lines <- unlist(strsplit(paste(combined, collapse = "\n"), "\n", fixed = TRUE))
  lines[nzchar(lines)]
}

`_emit_child_section_details` <- function(run_result, parent_label) {
  lines <- `_child_output_lines`(run_result)
  if (length(lines) == 0L) {
    return(invisible(NULL))
  }

  summary_pattern <- paste0("^", parent_label, " \\.{2,} (Pass|Done|Fail)$")
  keep <- !lines %in% parent_label & !grepl(summary_pattern, lines)
  lines <- lines[keep]

  if (length(lines) > 0L) {
    cat(paste(lines, collapse = "\n"), "\n", file = stderr(), sep = "")
  }
}

#' Run the top-level tool build workflow
#'
#' Orchestrates the source-level tooling workflow by optionally running the tool
#' test suite and regenerating tool documentation.
#'
#' @param args Character vector of CLI arguments. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`.
#'
#' @return Invisibly returns a list describing which tool-build steps ran. If
#'   `--help` or `-h` is supplied, returns invisibly with `NULL`.
#'
#' @examples
#' \dontrun{
#' run_build_tools()
#' run_build_tools("--skip-docs")
#' run_build_tools("--help")
#' }
run_build_tools <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop("The `processx` package is required to run build tools.", call. = FALSE)
  }

  options <- `_parse_build_tools_args`(args)

  if (isTRUE(options$help)) {
    `_print_build_tools_help`()
    return(invisible(NULL))
  }

  ui <- `_cli_ui_new`()

  if (isTRUE(options$run_tests)) {
    `_cli_step_start`(ui, "Testing tools")
    test_run <- `_run_build_tools_tests`(ui)
    if (!identical(test_run$status, 0L)) {
      `_cli_step_fail`(
        ui,
        details = c(test_run$stdout, test_run$stderr)
      )
      stop("Tool tests failed.", call. = FALSE)
    }
    if (!isTRUE(ui$fancy)) {
      `_emit_child_section_details`(test_run, "Testing tools")
    }
    `_cli_step_finish`(ui, status = "Pass")
  }

  if (isTRUE(options$run_docs)) {
    `_cli_step_start`(ui, "Documenting tools")
    doc_run <- `_run_build_tools_docs`(ui)
    if (!identical(doc_run$status, 0L)) {
      `_cli_step_fail`(
        ui,
        details = c(doc_run$stdout, doc_run$stderr)
      )
      stop("Tool documentation generation failed.", call. = FALSE)
    }
    if (!isTRUE(ui$fancy)) {
      `_emit_child_section_details`(doc_run, "Documenting tools")
    }
    `_cli_step_finish`(ui, status = "Done")
  }

  invisible(
    list(
      ran_tests = options$run_tests,
      ran_docs = options$run_docs
    )
  )
}

if (sys.nframe() == 0L) {
  run_build_tools()
}

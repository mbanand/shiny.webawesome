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

`_test_tools_usage` <- function() {
  "Usage: Rscript tools/test_tools.R [--filter <pattern>] [--help]"
}

`_test_tools_description` <- function() {
  "Run build-tool tests under tools/testthat."
}

`_test_tools_option_lines` <- function() {
  c(
    "--filter, -f <pattern>  Restrict execution to matching test files.",
    "--help, -h              Print this help text."
  )
}

`_print_test_tools_help` <- function() {
  writeLines(
    c(
      `_test_tools_description`(),
      "",
      `_test_tools_usage`(),
      "",
      "Options:",
      `_test_tools_option_lines`()
    )
  )
}

`_parse_test_tools_args` <- function(args) {
  filter <- NULL
  help <- FALSE
  skip_next <- FALSE

  for (i in seq_along(args)) {
    if (skip_next) {
      skip_next <- FALSE
      next
    }

    arg <- args[[i]]

    if (arg %in% c("--filter", "-f")) {
      if (i == length(args)) {
        stop("Missing value for --filter.", call. = FALSE)
      }

      filter <- args[[i + 1L]]
      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--filter=")) {
      filter <- sub("^--filter=", "", arg)
      next
    }

    if (arg %in% c("--help", "-h")) {
      help <- TRUE
      next
    }

    stop(
      paste0("Unknown argument: ", arg, "\n", `_test_tools_usage`()),
      call. = FALSE
    )
  }

  list(filter = filter, help = help)
}

`_find_tool_test_files` <- function(test_dir = file.path("tools", "testthat")) {
  test_files <- sort(
    list.files(
      test_dir,
      pattern = "^test-.*\\.[Rr]$",
      recursive = TRUE,
      full.names = TRUE
    )
  )

  if (length(test_files) == 0L) {
    stop("No tool test files found.", call. = FALSE)
  }

  test_files
}

`_filter_tool_test_files` <- function(test_files, filter = NULL) {
  if (is.null(filter)) {
    return(test_files)
  }

  filtered_files <- test_files[grepl(filter, test_files)]

  if (length(filtered_files) == 0L) {
    stop("No tool test files matched the requested filter.", call. = FALSE)
  }

  filtered_files
}

`_run_tool_test_file` <- function(test_file, reporter) {
  testthat::test_file(test_file, reporter = reporter)
}

`_expectation_types` <- function(expectations) {
  vapply(
    expectations,
    function(expectation) testthat:::expectation_type(expectation),
    character(1)
  )
}

`_failed_expectation_lines` <- function(expectations) {
  failed <- expectations[`_expectation_types`(expectations) %in% c("failure", "error")]

  vapply(
    failed,
    function(expectation) expectation$message %||% "Test failure",
    character(1)
  )
}

#' Run build-tool tests from the command line
#'
#' Discovers `testthat` files under `tools/testthat/` and executes them in a
#' deterministic order. An optional file-path filter can be supplied to narrow
#' the run to a subset of tool tests.
#'
#' Supported options are:
#' - `--filter` / `-f` to match tool test file paths
#' - `--help` / `-h` to print CLI help
#'
#' @param args Character vector of CLI arguments. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`.
#'
#' @return Invisibly returns the tool test files that were executed. If
#'   `--help` or `-h` is supplied, returns invisibly with `NULL`.
#'
#' @examples
#' \dontrun{
#' run_tool_tests()
#' run_tool_tests(c("--filter", "clean"))
#' run_tool_tests("--help")
#' }
run_tool_tests <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- `_parse_test_tools_args`(args)

  if (isTRUE(options$help)) {
    `_print_test_tools_help`()
    return(invisible(NULL))
  }

  if (!requireNamespace("testthat", quietly = TRUE)) {
    stop("The `testthat` package is required to run tool tests.", call. = FALSE)
  }

  ui <- `_cli_ui_new`()
  test_files <- `_filter_tool_test_files`(
    test_files = `_find_tool_test_files`(),
    filter = options$filter
  )

  `_cli_step_start`(ui, "Testing tools")

  tryCatch(
    {
      for (i in seq_along(test_files)) {
        test_file <- test_files[[i]]
        reporter <- testthat::SilentReporter$new()
        label <- tools::file_path_sans_ext(basename(test_file))

        `_cli_step_update`(
          ui = ui,
          label = label,
          index = i,
          total = length(test_files)
        )
        `_run_tool_test_file`(test_file = test_file, reporter = reporter)

        failed_lines <- `_failed_expectation_lines`(reporter$expectations())
        if (length(failed_lines) > 0L) {
          stop(paste(failed_lines, collapse = "\n"), call. = FALSE)
        }

        `_cli_substep_pass`(
          ui = ui,
          label = label,
          index = i,
          total = length(test_files)
        )
      }
      `_cli_step_finish`(ui, status = "Pass")
    },
    error = function(condition) {
      `_cli_step_fail`(ui, details = conditionMessage(condition))
      stop(condition)
    }
  )

  invisible(test_files)
}

if (sys.nframe() == 0L) {
  run_tool_tests()
}

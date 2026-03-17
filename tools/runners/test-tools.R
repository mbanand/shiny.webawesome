#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

filter <- NULL

parse_arg <- function(i) {
  arg <- args[[i]]

  if (arg %in% c("--filter", "-f")) {
    if (i == length(args)) {
      stop("Missing value for --filter.", call. = FALSE)
    }

    filter <<- args[[i + 1L]]
    return(invisible("skip-next"))
  }

  if (startsWith(arg, "--filter=")) {
    filter <<- sub("^--filter=", "", arg)
    return(invisible(NULL))
  }

  stop(
    paste0(
      "Unknown argument: ", arg, "\n",
      "Usage: Rscript tools/runners/test-tools.R [--filter <pattern>]"
    ),
    call. = FALSE
  )
}

skip_next <- FALSE
for (i in seq_along(args)) {
  if (skip_next) {
    skip_next <- FALSE
    next
  }

  parsed <- parse_arg(i)
  if (identical(parsed, "skip-next")) {
    skip_next <- TRUE
  }
}

if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("The `testthat` package is required to run tool tests.", call. = FALSE)
}

test_dir <- file.path("tools", "testthat")
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

reporter <- testthat::SummaryReporter$new()

if (is.null(filter)) {
  for (test_file in test_files) {
    testthat::test_file(test_file, reporter = reporter)
  }
} else {
  for (test_file in test_files) {
    testthat::test_file(test_file, reporter = reporter, filter = filter)
  }
}

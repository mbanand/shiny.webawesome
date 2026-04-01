#!/usr/bin/env Rscript

# Integrity-check implementation for the shiny.webawesome build pipeline.
#
# This file is both sourceable by tests and directly executable as a top-level
# build-stage script. It verifies the current prune-owned and generate-owned
# surfaces against the integrity records written by earlier stages.

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

.integrity_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .integrity_tool_base_dirs
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

# Source the shared integrity helpers relative to this script when possible.
.bootstrap_integrity_helpers <- function() {
  base_dirs <- .integrity_tool_base_dirs
  candidates <- c(
    unlist(lapply(base_dirs, function(dir) file.path(dir, "integrity.R"))),
    unlist(
      lapply(base_dirs, function(dir) file.path(dir, "tools", "integrity.R"))
    ),
    unlist(
      lapply(base_dirs, function(dir) file.path(dir, "..", "integrity.R"))
    ),
    file.path("tools", "integrity.R"),
    "integrity.R"
  )
  existing <- unique(candidates[file.exists(candidates)])

  if (length(existing) > 0L) {
    source(existing[[1]])
  }
}

.bootstrap_cli_ui()
.bootstrap_integrity_helpers()
rm(.bootstrap_cli_ui, .bootstrap_integrity_helpers)

# Return the CLI usage string for the integrity checker.
.check_integrity_usage <- function() {
  paste(
    "Usage: ./tools/check_integrity.R",
    "[--root <path>] [--quiet] [--help]"
  )
}

# Return the short CLI description for the integrity checker.
.check_integrity_description <- function() {
  paste(
    "Verify prune and generate integrity records against current",
    "stage-owned surfaces."
  )
}

# List supported CLI options for the integrity checker.
.check_integrity_option_lines <- function() {
  c(
    paste(
      "--root <path>            Repository root.",
      "Defaults to the current directory."
    ),
    "--quiet                  Suppress stage-level progress messages.",
    "--help, -h               Print this help text."
  )
}

# Print the CLI help text for the integrity checker.
.print_check_integrity_help <- function() {
  writeLines(
    c(
      .check_integrity_description(),
      "",
      .check_integrity_usage(),
      "",
      "Options:",
      .check_integrity_option_lines()
    )
  )
}

# Define default CLI option values for the integrity checker.
.check_integrity_defaults <- function() {
  list(
    root = ".",
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the integrity checker.
.parse_check_integrity_args <- function(args) {
  options <- .check_integrity_defaults()
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

    if (arg == "--quiet") {
      options$verbose <- FALSE
      next
    }

    if (arg == "--root") {
      if (i == length(args)) {
        stop("Missing value for --root.", call. = FALSE)
      }

      options$root <- args[[i + 1L]]
      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--root=")) {
      options$root <- sub("^--root=", "", arg)
      next
    }

    stop(
      paste0("Unknown argument: ", arg, "\n", .check_integrity_usage()),
      call. = FALSE
    )
  }

  options
}

# Return one human-readable description for an integrity comparison.
.integrity_result_line <- function(result, label) {
  paste0(label, ": ", result$summary)
}

# Return the human-readable integrity report directory.
.integrity_report_dir <- function(root) {
  file.path(root, "reports", "integrity")
}

# Return the human-readable integrity summary path.
.integrity_summary_path <- function(root) {
  file.path(.integrity_report_dir(root), "summary.md")
}

# Write one deterministic text file.
.write_text_file <- function(path, text) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(enc2utf8(text), path, useBytes = TRUE)
  invisible(path)
}

# Return one short Markdown section for an integrity comparison.
.integrity_summary_section <- function(name, check) {
  current_record <- .or_default(check$current_record, list())
  roots <- .or_default(current_record$surface$roots, character())
  details <- .or_default(check$details, character())

  c(
    paste0("## `", name, "`"),
    "",
    paste0("- Status: `", check$status, "`"),
    paste0("- Summary: ", check$summary),
    paste0("- Record path: `", check$record_path, "`"),
    paste0(
      "- Current surface roots: ",
      if (length(roots) == 0L) {
        "None."
      } else {
        paste0("`", roots, "`", collapse = ", ")
      }
    ),
    paste0(
      "- Current file count: ",
      .or_default(current_record$summary$file_count, 0L)
    ),
    paste0(
      "- Current tree digest: `",
      .or_default(current_record$summary$tree_digest, ""),
      "`"
    ),
    "",
    "### Details",
    "",
    if (length(details) == 0L) {
      "- None."
    } else {
      paste0("- ", details)
    }
  )
}

# Return the human-readable integrity summary lines.
.integrity_summary_lines <- function(result) {
  checks <- result$checks

  c(
    "# Integrity Summary",
    "",
    "Generated by tools/check_integrity.R. Do not edit by hand.",
    "",
    paste0(
      "- Overall status: `",
      if (all(vapply(checks, function(check) isTRUE(check$ok), logical(1)))) {
        "pass"
      } else {
        "warn"
      },
      "`"
    ),
    paste0("- Prune output: ", checks$prune_output$summary),
    paste0("- Generate output: ", checks$generate_output$summary),
    "",
    .integrity_summary_section("prune_output", checks$prune_output),
    "",
    .integrity_summary_section("generate_output", checks$generate_output)
  )
}

# Write the human-readable integrity summary and return its relative path.
.write_integrity_summary <- function(root, result) {
  path <- .integrity_summary_path(root)
  .write_text_file(path, .integrity_summary_lines(result))
  .strip_root_prefix(path, root)
}

# Fail when any integrity comparison did not pass.
.assert_integrity_ok <- function(checks) {
  failed <- checks[
    !vapply(checks, function(check) isTRUE(check$ok), logical(1))
  ]

  if (length(failed) == 0L) {
    return(invisible(TRUE))
  }

  details <- unlist(
    lapply(
      names(failed),
      function(name) {
        check <- failed[[name]]
        c(
          .integrity_result_line(check, name),
          paste0("  ", check$details)
        )
      }
    ),
    use.names = FALSE
  )

  stop(paste(details, collapse = "\n"), call. = FALSE)
}

#' Check build-pipeline integrity records
#'
#' Verifies that the current prune-owned and generate-owned file surfaces still
#' match the integrity records produced by earlier stages.
#'
#' CLI entry point:
#' `./tools/check_integrity.R --help`
#'
#' @param root Repository root directory.
#' @param verbose Logical scalar. If `TRUE`, emits a short integrity summary.
#'
#' @return A list containing both integrity comparisons.
#'
#' @examples
#' \dontrun{
#' check_integrity()
#' }
check_integrity <- function(root = ".", verbose = interactive()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  checks <- list(
    prune_output = .check_prune_integrity(root),
    generate_output = .check_generate_integrity(root)
  )

  result <- list(
    root = root,
    checks = checks
  )
  result$written <- list(
    summary = .write_integrity_summary(root, result)
  )

  .assert_integrity_ok(checks)

  if (isTRUE(verbose)) {
    message(
      "Integrity check complete: prune=",
      checks$prune_output$summary,
      ", generate=",
      checks$generate_output$summary,
      ", report=",
      result$written$summary
    )
  }

  result
}

# Run the integrity checker from the command line.
run_check_integrity <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_check_integrity_args(args)

  if (isTRUE(options$help)) {
    .print_check_integrity_help()
    return(invisible(NULL))
  }

  ui <- .cli_ui_new()
  ui$quiet <- !isTRUE(options$verbose)
  .cli_step_start(ui, "Checking integrity")

  result <- tryCatch(
    check_integrity(
      root = options$root,
      verbose = FALSE
    ),
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled(conditionMessage(condition))
    }
  )

  .cli_substep_pass(
    ui,
    "Prune surface",
    status = .integrity_cli_status(result$checks$prune_output$status),
    comment = paste0("[", result$checks$prune_output$summary, "]")
  )
  .cli_substep_pass(
    ui,
    "Generate surface",
    status = .integrity_cli_status(result$checks$generate_output$status),
    comment = paste0("[", result$checks$generate_output$summary, "]")
  )

  .cli_step_finish(ui, status = "Pass")

  invisible(result)
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_check_integrity)
}
# nolint end

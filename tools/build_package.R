#!/usr/bin/env Rscript

# nolint start: object_usage_linter.
# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
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
  known_files <- known_files[nzchar(known_files)]
  current_dir <- if (length(known_files) == 0L) {
    "."
  } else {
    dirname(normalizePath(known_files[[1]], winslash = "/", mustWork = FALSE))
  }

  candidates <- c(
    file.path(current_dir, "cli_ui.R"),
    file.path(current_dir, "tools", "cli_ui.R"),
    file.path(current_dir, "..", "cli_ui.R"),
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

# Return the CLI usage string for the package build orchestrator.
.build_package_usage <- function() {
  paste(
    "Usage: ./tools/build_package.R",
    "[--skip-tools] [--help]"
  )
}

# Return the short CLI description for the package build orchestrator.
.build_package_description <- function() {
  "Run the package build orchestration workflow."
}

# List supported CLI options for the package build orchestrator.
.build_package_option_lines <- function() {
  c(
    "--skip-tools  Skip the prerequisite tool build workflow.",
    "--help, -h    Print this help text."
  )
}

# Print the CLI help text for the package build orchestrator.
.print_build_package_help <- function() {
  writeLines(
    c(
      .build_package_description(),
      "",
      .build_package_usage(),
      "",
      "Options:",
      .build_package_option_lines()
    )
  )
}

# Define default CLI option values for the package build orchestrator.
.build_package_defaults <- function() {
  list(
    run_tools = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the package build orchestrator.
.parse_build_package_args <- function(args) {
  options <- .build_package_defaults()

  for (arg in args) {
    if (arg == "--skip-tools") {
      options$run_tools <- FALSE
      next
    }

    if (arg %in% c("--help", "-h")) {
      options$help <- TRUE
      next
    }

    stop(
      paste0("Unknown argument: ", arg, "\n", .build_package_usage()),
      call. = FALSE
    )
  }

  options
}

# Discover currently implemented package build-stage scripts.
.existing_package_build_steps <- function() {
  candidate_steps <- c(
    "tools/fetch_webawesome.R",
    "tools/prune_webawesome.R",
    "tools/generate_components.R",
    "tools/review_binding_candidates.R",
    "tools/report_components.R",
    "tools/check_integrity.R"
  )

  candidate_steps[file.exists(candidate_steps)]
}

# Run the tool-build prerequisite as a child CLI command.
.run_package_build_tools <- function(ui) {
  .cli_run_command(
    ui = ui,
    label = "Building tools",
    command = "./tools/build_tools.R",
    wd = ".",
    env = c(SHINY_WEBAWESOME_CLI_MODE = "plain")
  )
}

# Run one package build-stage script as a child CLI command.
.run_package_build_step <- function(step_script, ui) {
  .cli_run_command(
    ui = ui,
    label = paste0("Running ", basename(step_script)),
    command = paste0("./", step_script),
    wd = ".",
    env = c(SHINY_WEBAWESOME_CLI_MODE = "plain")
  )
}

# Split combined child-process output into non-empty lines.
.child_output_lines <- function(run_result) {
  combined <- c(run_result$stdout, run_result$stderr)
  lines <- unlist(
    strsplit(paste(combined, collapse = "\n"), "\n", fixed = TRUE)
  )
  lines[nzchar(lines)]
}

# Emit child-process output indented under the parent orchestrator step.
.emit_child_output <- function(run_result) {
  lines <- .child_output_lines(run_result)

  if (length(lines) > 0L) {
    indented <- paste0("  ", lines)
    cat(paste(indented, collapse = "\n"), "\n", file = stderr(), sep = "")
  }
}

#' Run the package build orchestration workflow
#'
#' Runs the prerequisite tool build workflow and then executes whichever
#' package-build step scripts are currently present in `tools/`.
#'
#' CLI entry point:
#' `./tools/build_package.R --help`
#'
#' @param args Character vector of CLI arguments. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`.
#'
#' @return Invisibly returns a list describing whether the tool workflow ran and
#'   which package-build step scripts were executed. If `--help` or `-h` is
#'   supplied, returns invisibly with `NULL`.
#'
#' @examples
#' \dontrun{
#' run_build_package()
#' run_build_package("--skip-tools")
#' run_build_package("--help")
#' }
run_build_package <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop(
      "The `processx` package is required to run build tools.",
      call. = FALSE
    )
  }

  options <- .parse_build_package_args(args)

  if (isTRUE(options$help)) {
    .print_build_package_help()
    return(invisible(NULL))
  }

  ui <- .cli_ui_new()
  ui$plain_step_status_col <- 52L

  if (isTRUE(options$run_tools)) {
    .cli_step_start(ui, "Building tools")
    tool_run <- .run_package_build_tools(ui)
    if (!identical(tool_run$status, 0L)) {
      .cli_step_fail(
        ui,
        details = c(tool_run$stdout, tool_run$stderr)
      )
      .cli_abort_handled("Tool build workflow failed.")
    }
    if (!isTRUE(ui$fancy)) {
      .emit_child_output(tool_run)
    }
    .cli_step_finish(ui, status = "Done")
  }

  steps <- .existing_package_build_steps()

  for (step in steps) {
    .cli_step_start(ui, paste0("Running ", basename(step)))
    step_run <- .run_package_build_step(step, ui)
    if (!identical(step_run$status, 0L)) {
      .cli_step_fail(
        ui,
        details = c(step_run$stdout, step_run$stderr)
      )
      .cli_abort_handled(paste0("Package build step failed: ", step))
    }
    if (!isTRUE(ui$fancy)) {
      .emit_child_output(step_run)
    }
    .cli_step_finish(ui, status = "Done")
  }

  invisible(
    list(
      ran_tools = options$run_tools,
      package_steps = steps
    )
  )
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_build_package)
}
# nolint end

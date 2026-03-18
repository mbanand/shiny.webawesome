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

`_build_package_usage` <- function() {
  paste(
    "Usage: ./tools/build_package.R",
    "[--skip-tools] [--help]"
  )
}

`_build_package_description` <- function() {
  "Run the package build orchestration workflow."
}

`_build_package_option_lines` <- function() {
  c(
    "--skip-tools  Skip the prerequisite tool build workflow.",
    "--help, -h    Print this help text."
  )
}

`_print_build_package_help` <- function() {
  writeLines(
    c(
      `_build_package_description`(),
      "",
      `_build_package_usage`(),
      "",
      "Options:",
      `_build_package_option_lines`()
    )
  )
}

`_build_package_defaults` <- function() {
  list(
    run_tools = TRUE,
    help = FALSE
  )
}

`_parse_build_package_args` <- function(args) {
  options <- `_build_package_defaults`()

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
      paste0("Unknown argument: ", arg, "\n", `_build_package_usage`()),
      call. = FALSE
    )
  }

  options
}

`_existing_package_build_steps` <- function() {
  candidate_steps <- c(
    "tools/fetch_webawesome.R",
    "tools/prune_webawesome.R",
    "tools/generate_components.R"
  )

  candidate_steps[file.exists(candidate_steps)]
}

`_run_package_build_tools` <- function(ui) {
  `_cli_run_command`(
    ui = ui,
    label = "Building tools",
    command = "./tools/build_tools.R",
    wd = ".",
    env = c(SHINY_WEBAWESOME_CLI_MODE = "plain")
  )
}

`_run_package_build_step` <- function(step_script, ui) {
  `_cli_run_command`(
    ui = ui,
    label = paste0("Running ", basename(step_script)),
    command = paste0("./", step_script),
    wd = ".",
    env = c(SHINY_WEBAWESOME_CLI_MODE = "plain")
  )
}

`_child_output_lines` <- function(run_result) {
  combined <- c(run_result$stdout, run_result$stderr)
  lines <- unlist(strsplit(paste(combined, collapse = "\n"), "\n", fixed = TRUE))
  lines[nzchar(lines)]
}

`_emit_child_output` <- function(run_result) {
  lines <- `_child_output_lines`(run_result)

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
    stop("The `processx` package is required to run build tools.", call. = FALSE)
  }

  options <- `_parse_build_package_args`(args)

  if (isTRUE(options$help)) {
    `_print_build_package_help`()
    return(invisible(NULL))
  }

  ui <- `_cli_ui_new`()
  ui$plain_step_status_col <- 62L

  if (isTRUE(options$run_tools)) {
    `_cli_step_start`(ui, "Building tools")
    tool_run <- `_run_package_build_tools`(ui)
    if (!identical(tool_run$status, 0L)) {
      `_cli_step_fail`(
        ui,
        details = c(tool_run$stdout, tool_run$stderr)
      )
      stop("Tool build workflow failed.", call. = FALSE)
    }
    if (!isTRUE(ui$fancy)) {
      `_emit_child_output`(tool_run)
    }
    `_cli_step_finish`(ui, status = "Done")
  }

  steps <- `_existing_package_build_steps`()

  for (step in steps) {
    `_cli_step_start`(ui, paste0("Running ", basename(step)))
    step_run <- `_run_package_build_step`(step, ui)
    if (!identical(step_run$status, 0L)) {
      `_cli_step_fail`(
        ui,
        details = c(step_run$stdout, step_run$stderr)
      )
      stop("Package build step failed: ", step, call. = FALSE)
    }
    if (!isTRUE(ui$fancy)) {
      `_emit_child_output`(step_run)
    }
    `_cli_step_finish`(ui, status = "Done")
  }

  invisible(
    list(
      ran_tools = options$run_tools,
      package_steps = steps
    )
  )
}

if (sys.nframe() == 0L) {
  run_build_package()
}

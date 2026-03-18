#!/usr/bin/env Rscript

# Fetch stage implementation for the shiny.webawesome build pipeline.
#
# This file is both sourceable by tests and directly executable as a top-level
# build-stage script. It is not package runtime code.

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

`_fetch_usage` <- function() {
  paste(
    "Usage: ./tools/fetch_webawesome.R",
    "[--version <version>] [--root <path>] [--quiet] [--help]"
  )
}

`_fetch_description` <- function() {
  "Fetch a pinned Web Awesome dist bundle into vendor/webawesome/."
}

`_fetch_option_lines` <- function() {
  c(
    "--version, -v <version>  Upstream Web Awesome version to fetch.",
    "--root <path>            Repository root. Defaults to the current directory.",
    "--quiet                  Suppress stage-level progress messages.",
    "--help, -h               Print this help text."
  )
}

`_print_fetch_help` <- function() {
  writeLines(
    c(
      `_fetch_description`(),
      "",
      `_fetch_usage`(),
      "",
      "Options:",
      `_fetch_option_lines`()
    )
  )
}

`_fetch_defaults` <- function() {
  list(
    version = NULL,
    root = ".",
    verbose = TRUE,
    help = FALSE
  )
}

`_parse_fetch_args` <- function(args) {
  options <- `_fetch_defaults`()
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

    if (arg %in% c("--version", "-v")) {
      if (i == length(args)) {
        stop("Missing value for --version.", call. = FALSE)
      }

      options$version <- args[[i + 1L]]
      skip_next <- TRUE
      next
    }

    if (startsWith(arg, "--version=")) {
      options$version <- sub("^--version=", "", arg)
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
      paste0("Unknown argument: ", arg, "\n", `_fetch_usage`()),
      call. = FALSE
    )
  }

  options
}

`_is_repo_root` <- function(root) {
  required_paths <- c("DESCRIPTION", "docs", "tools")
  all(file.exists(file.path(root, required_paths)))
}

`_strip_root_prefix` <- function(paths, root) {
  sub(paste0("^", root, "/?"), "", paths)
}

`_default_webawesome_package` <- function() {
  "@awesome.me/webawesome"
}

`_fetch_npm_command` <- function() {
  command <- trimws(Sys.getenv("SHINY_WEBAWESOME_NPM", "npm"))

  if (!nzchar(command)) {
    stop("Resolved npm command is empty.", call. = FALSE)
  }

  command
}

`_default_webawesome_version_file` <- function() {
  file.path("dev", "webawesome-version.txt")
}

`_read_lines_trimmed` <- function(path) {
  trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
}

`_read_pinned_webawesome_version` <- function(root,
                                              version_file = `_default_webawesome_version_file`()) {
  version_path <- file.path(root, version_file)

  if (!file.exists(version_path)) {
    stop(
      "Pinned Web Awesome version file does not exist: ",
      version_file,
      call. = FALSE
    )
  }

  lines <- `_read_lines_trimmed`(version_path)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]

  if (length(lines) != 1L) {
    stop(
      "Pinned Web Awesome version file must contain exactly one version string: ",
      version_file,
      call. = FALSE
    )
  }

  lines[[1]]
}

`_validate_fetch_version` <- function(version) {
  version <- trimws(version %||% "")

  if (!nzchar(version)) {
    stop("Web Awesome version must be a non-empty string.", call. = FALSE)
  }

  if (grepl("[/\\\\]", version)) {
    stop("Web Awesome version must not contain path separators.", call. = FALSE)
  }

  version
}

`_fetch_target_dir` <- function(root, version) {
  file.path(root, "vendor", "webawesome", version)
}

`_fetch_dist_dir` <- function(root, version) {
  file.path(`_fetch_target_dir`(root, version), "dist")
}

`_run_fetch_command` <- function(command,
                                 args = character(),
                                 wd = ".",
                                 env = character()) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop("The `processx` package is required to fetch Web Awesome.", call. = FALSE)
  }

  tryCatch(
    processx::run(
      command = command,
      args = args,
      wd = wd,
      echo = FALSE,
      error_on_status = FALSE,
      env = env
    ),
    error = function(condition) {
      stop(conditionMessage(condition), call. = FALSE)
    }
  )
}

`_last_non_empty_line` <- function(text) {
  lines <- unlist(strsplit(text %||% "", "\n", fixed = TRUE))
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]

  if (length(lines) == 0L) {
    return(NULL)
  }

  tail(lines, 1L)
}

`_copy_directory` <- function(source_dir, target_dir) {
  dir.create(dirname(target_dir), recursive = TRUE, showWarnings = FALSE)
  copied <- file.copy(source_dir, dirname(target_dir), recursive = TRUE)

  if (!isTRUE(copied)) {
    stop(
      "Failed to copy directory into repository: ",
      basename(source_dir),
      call. = FALSE
    )
  }

  invisible(target_dir)
}

`_write_fetch_version_file` <- function(target_dir, version) {
  writeLines(version, file.path(target_dir, "VERSION"), useBytes = TRUE)
}

`_emit_fetch_summary` <- function(result) {
  message(
    "Fetched version ",
    result$version,
    " into ",
    result$target_dir
  )
}

#' Fetch a pinned Web Awesome dist bundle
#'
#' This tool supports both direct command-line execution and sourcing from R.
#'
#' Use `fetch_webawesome()` when the file has been sourced and you want to call
#' the fetch stage programmatically. Use `run_fetch_webawesome()` as the
#' command-line entry point when invoking `./tools/fetch_webawesome.R`.
#'
#' Downloads a specific version of the upstream Web Awesome npm package using
#' `npm pack`, extracts the package tarball in a temporary directory, and
#' copies only the upstream `dist/` tree into `vendor/webawesome/<version>/`.
#' The fetched version is also recorded in `vendor/webawesome/<version>/VERSION`.
#'
#' If `version` is `NULL`, the version pinned in `dev/webawesome-version.txt`
#' is used.
#'
#' @param version Optional Web Awesome version string. If `NULL`, reads the
#'   pinned version from `dev/webawesome-version.txt`.
#' @param root Repository root directory.
#' @param package_name Upstream npm package name. Defaults to
#'   `"@awesome.me/webawesome"`.
#' @param version_file Path to the pinned version file, relative to the
#'   repository root.
#' @param command_runner Function used to run external commands. Primarily
#'   intended for testing.
#' @param verbose Logical scalar. If `TRUE`, emits a short fetch summary.
#'
#' @return A list describing the fetch operation, including the resolved
#'   version, package name, target directory, and copied paths.
#'
#' @examples
#' \dontrun{
#' fetch_webawesome()
#' fetch_webawesome(version = "3.0.0-beta.4")
#' }
fetch_webawesome <- function(version = NULL,
                             root = ".",
                             package_name = `_default_webawesome_package`(),
                             version_file = `_default_webawesome_version_file`(),
                             command_runner = `_run_fetch_command`,
                             verbose = interactive()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!`_is_repo_root`(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  version <- version %||% `_read_pinned_webawesome_version`(
    root = root,
    version_file = version_file
  )
  version <- `_validate_fetch_version`(version)

  target_dir <- `_fetch_target_dir`(root, version)
  dist_target_dir <- `_fetch_dist_dir`(root, version)

  if (dir.exists(target_dir) || file.exists(target_dir)) {
    stop(
      "Fetched upstream version already exists: ",
      `_strip_root_prefix`(target_dir, root),
      ". Remove it first or run clean_webawesome(level = \"distclean\").",
      call. = FALSE
    )
  }

  temp_root <- tempfile("fetch-webawesome-")
  pack_dir <- file.path(temp_root, "pack")
  extract_dir <- file.path(temp_root, "extract")
  dir.create(pack_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(temp_root, recursive = TRUE, force = TRUE), add = TRUE)

  package_spec <- paste0(package_name, "@", version)
  run_result <- command_runner(
    command = `_fetch_npm_command`(),
    args = c("pack", package_spec),
    wd = pack_dir,
    env = character()
  )

  if (!identical(run_result$status, 0L)) {
    detail <- c(run_result$stderr, run_result$stdout)
    detail <- trimws(detail)
    detail <- detail[nzchar(detail)]
    stop(
      paste(
        c("Failed to fetch Web Awesome with npm pack.", detail),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }

  tarball_name <- `_last_non_empty_line`(run_result$stdout)
  if (is.null(tarball_name)) {
    stop("npm pack did not report a tarball name.", call. = FALSE)
  }

  tarball_path <- file.path(pack_dir, tarball_name)
  if (!file.exists(tarball_path)) {
    stop(
      "npm pack reported a tarball that was not created: ",
      tarball_name,
      call. = FALSE
    )
  }

  utils::untar(tarball_path, exdir = extract_dir)

  package_dir <- file.path(extract_dir, "package")
  dist_source_dir <- file.path(package_dir, "dist")

  if (!dir.exists(dist_source_dir)) {
    stop("Fetched package did not contain a dist/ directory.", call. = FALSE)
  }

  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
  `_copy_directory`(dist_source_dir, dist_target_dir)
  `_write_fetch_version_file`(target_dir, version)

  result <- list(
    version = version,
    package_name = package_name,
    package_spec = package_spec,
    root = root,
    version_file = version_file,
    target_dir = `_strip_root_prefix`(target_dir, root),
    dist_dir = `_strip_root_prefix`(dist_target_dir, root),
    version_record = `_strip_root_prefix`(
      file.path(target_dir, "VERSION"),
      root
    ),
    tarball = basename(tarball_path)
  )

  if (isTRUE(verbose)) {
    `_emit_fetch_summary`(result)
  }

  result
}

`_emit_fetch_runner_summary` <- function(result) {
  message(
    "Fetch complete: version=",
    result$version,
    ", path=",
    result$target_dir
  )
}

#' Run the fetch stage from the command line
#'
#' Parses CLI arguments, executes `fetch_webawesome()`, and prints a short
#' status summary for the fetched upstream version.
#'
#' This is the command-line entry point for the fetch stage.
#'
#' Supported options are:
#' - `--version` / `-v` to override the pinned upstream version
#' - `--root` to run against a different repository root
#' - `--quiet` to suppress stage-level progress messages
#' - `--help` / `-h` to print CLI help
#'
#' @rdname fetch_webawesome
#' @describeIn fetch_webawesome Run the fetch stage from the command line.
#'
#' @param args Character vector of CLI arguments. Defaults to
#'   `commandArgs(trailingOnly = TRUE)`.
#'
#' @return Invisibly returns the result from `fetch_webawesome()`. If `--help`
#'   or `-h` is supplied, returns invisibly with `NULL`.
#'
#' @examples
#' \dontrun{
#' run_fetch_webawesome()
#' run_fetch_webawesome(c("--version", "3.0.0-beta.4"))
#' run_fetch_webawesome("--help")
#' }
run_fetch_webawesome <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- `_parse_fetch_args`(args)

  if (isTRUE(options$help)) {
    `_print_fetch_help`()
    return(invisible(NULL))
  }

  ui <- `_cli_ui_new`()
  ui$quiet <- !isTRUE(options$verbose)
  `_cli_step_start`(ui, "Fetching Web Awesome")

  result <- tryCatch(
    {
      fetch_webawesome(
        version = options$version,
        root = options$root,
        verbose = FALSE
      )
    },
    error = function(condition) {
      `_cli_step_fail`(ui, details = conditionMessage(condition))
      stop(condition)
    }
  )

  `_cli_step_finish`(ui, status = "Done")
  `_emit_fetch_runner_summary`(result)

  invisible(result)
}

if (sys.nframe() == 0L) {
  run_fetch_webawesome()
}

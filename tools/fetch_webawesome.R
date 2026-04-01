#!/usr/bin/env Rscript

# Fetch stage implementation for the shiny.webawesome build pipeline.
#
# This file is both sourceable by tests and directly executable as a top-level
# build-stage script. It is not package runtime code.

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

# Return the CLI usage string for the fetch stage.
.fetch_usage <- function() {
  paste(
    "Usage: ./tools/fetch_webawesome.R",
    "[--version <version>] [--root <path>] [--quiet] [--help]"
  )
}

# Return the short CLI description for the fetch stage.
.fetch_description <- function() {
  "Fetch a pinned Web Awesome dist bundle into vendor/webawesome/."
}

# List supported CLI options for the fetch stage.
.fetch_option_lines <- function() {
  c(
    "--version, -v <version>  Upstream Web Awesome version to fetch.",
    paste(
      "--root <path>            Repository root.",
      "Defaults to the current directory."
    ),
    "--quiet                  Suppress stage-level progress messages.",
    "--help, -h               Print this help text."
  )
}

# Print the CLI help text for the fetch stage.
.print_fetch_help <- function() {
  writeLines(
    c(
      .fetch_description(),
      "",
      .fetch_usage(),
      "",
      "Options:",
      .fetch_option_lines()
    )
  )
}

# Define default CLI option values for the fetch stage.
.fetch_defaults <- function() {
  list(
    version = NULL,
    root = ".",
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the fetch stage.
.parse_fetch_args <- function(args) {
  options <- .fetch_defaults()
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
      paste0("Unknown argument: ", arg, "\n", .fetch_usage()),
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

# Remove the repository root prefix from one or more absolute paths.
.strip_root_prefix <- function(paths, root) {
  sub(paste0("^", root, "/?"), "", paths)
}

# Return the default upstream npm package name.
.default_webawesome_package <- function() {
  "@awesome.me/webawesome"
}

# Resolve the npm command used by the fetch stage.
.fetch_npm_command <- function() {
  command <- trimws(Sys.getenv("SHINY_WEBAWESOME_NPM", "npm"))

  if (!nzchar(command)) {
    stop("Resolved npm command is empty.", call. = FALSE)
  }

  command
}

# Return the default relative path to the pinned version file.
.default_version_file <- function() {
  file.path("dev", "webawesome-version.txt")
}

# Read and trim lines from a text file using UTF-8.
.read_lines_trimmed <- function(path) {
  trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
}

# Read the pinned Web Awesome version from the repository input file.
.read_pinned_version <- function(
  root,
  version_file = .default_version_file()
) {
  version_path <- file.path(root, version_file)

  if (!file.exists(version_path)) {
    stop(
      "Pinned Web Awesome version file does not exist: ",
      version_file,
      call. = FALSE
    )
  }

  lines <- .read_lines_trimmed(version_path)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]

  if (length(lines) != 1L) {
    stop(
      paste(
        "Pinned Web Awesome version file must contain exactly one",
        "version string:"
      ),
      version_file,
      call. = FALSE
    )
  }

  lines[[1]]
}

# Validate and normalize a requested Web Awesome version string.
.validate_fetch_version <- function(version) {
  version <- trimws(version %||% "")

  if (!nzchar(version)) {
    stop("Web Awesome version must be a non-empty string.", call. = FALSE)
  }

  if (grepl("[/\\\\]", version)) {
    stop("Web Awesome version must not contain path separators.", call. = FALSE)
  }

  version
}

# Build the version-specific vendor target directory path.
.fetch_target_dir <- function(root, version) {
  file.path(root, "vendor", "webawesome", version)
}

# Build the version-specific vendored browser-runtime directory path.
.fetch_runtime_dir <- function(root, version) {
  file.path(.fetch_target_dir(root, version), "dist-cdn")
}

# Run one external fetch command and normalize execution failures.
.run_fetch_command <- function(command,
                               args = character(),
                               wd = ".",
                               env = character()) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop(
      "The `processx` package is required to fetch Web Awesome.",
      call. = FALSE
    )
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

# Extract the final non-empty line from command output text.
.last_non_empty_line <- function(text) {
  lines <- unlist(strsplit(text %||% "", "\n", fixed = TRUE))
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]

  if (length(lines) == 0L) {
    return(NULL)
  }

  tail(lines, 1L)
}

# Copy a directory tree into the repository fetch target.
.copy_directory <- function(source_dir, target_dir) {
  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)

  entries <- list.files(
    source_dir,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    full.names = TRUE,
    include.dirs = TRUE
  )

  if (length(entries) == 0L) {
    return(invisible(target_dir))
  }

  relative_entries <- .strip_root_prefix(
    normalizePath(entries, winslash = "/", mustWork = TRUE),
    normalizePath(source_dir, winslash = "/", mustWork = TRUE)
  )

  is_dir <- dir.exists(entries)
  dir_entries <- entries[is_dir]
  if (length(dir_entries) > 0L) {
    invisible(vapply(
      dir_entries,
      function(path) {
        dir.create(
          file.path(
            target_dir,
            .strip_root_prefix(
              normalizePath(path, winslash = "/", mustWork = TRUE),
              normalizePath(source_dir, winslash = "/", mustWork = TRUE)
            )
          ),
          recursive = TRUE,
          showWarnings = FALSE
        )
        path
      },
      character(1)
    ))
  }

  file_entries <- entries[!is_dir]
  file_relative <- relative_entries[!is_dir]

  copied <- vapply(
    seq_along(file_entries),
    function(index) {
      target_path <- file.path(target_dir, file_relative[[index]])
      dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)
      isTRUE(file.copy(file_entries[[index]], target_path, overwrite = TRUE))
    },
    logical(1)
  )

  if (!all(copied)) {
    stop(
      "Failed to copy directory into repository: ",
      basename(source_dir),
      call. = FALSE
    )
  }

  invisible(target_dir)
}

# Write the fetched upstream version marker file.
.write_fetch_version_file <- function(target_dir, version) {
  writeLines(version, file.path(target_dir, "VERSION"), useBytes = TRUE)
}

# Emit a short summary for a programmatic fetch result.
.emit_fetch_summary <- function(result) {
  message(
    "Fetched version ",
    result$version,
    " into ",
    result$target_dir
  )
}

#' Fetch a pinned Web Awesome dist-cdn bundle
#'
#' Downloads a specific version of the upstream Web Awesome npm package using
#' `npm pack`, extracts the package tarball in a temporary directory, and
#' copies the upstream browser-ready `dist-cdn/` tree into
#' `vendor/webawesome/<version>/dist-cdn/`. The fetched version is also
#' recorded in `vendor/webawesome/<version>/VERSION`.
#'
#' If `version` is `NULL`, the version pinned in `dev/webawesome-version.txt`
#' is used.
#'
#' CLI entry point:
#' `./tools/fetch_webawesome.R --help`
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
#' fetch_webawesome(version = "3.3.1")
#' }
fetch_webawesome <- function(version = NULL,
                             root = ".",
                             package_name = .default_webawesome_package(),
                             version_file = .default_version_file(),
                             command_runner = .run_fetch_command,
                             verbose = interactive()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  version <- version %||% .read_pinned_version(
    root = root,
    version_file = version_file
  )
  version <- .validate_fetch_version(version)

  target_dir <- .fetch_target_dir(root, version)
  dist_target_dir <- .fetch_runtime_dir(root, version)

  if (dir.exists(target_dir) || file.exists(target_dir)) {
    stop(
      "Fetched upstream version already exists: ",
      .strip_root_prefix(target_dir, root),
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
    command = .fetch_npm_command(),
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

  tarball_name <- .last_non_empty_line(run_result$stdout)
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
  dist_source_dir <- file.path(package_dir, "dist-cdn")

  if (!dir.exists(dist_source_dir)) {
    stop(
      "Fetched package did not contain a dist-cdn/ directory.",
      call. = FALSE
    )
  }

  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
  .copy_directory(dist_source_dir, dist_target_dir)
  .write_fetch_version_file(target_dir, version)

  result <- list(
    version = version,
    package_name = package_name,
    package_spec = package_spec,
    root = root,
    version_file = version_file,
    target_dir = .strip_root_prefix(target_dir, root),
    dist_dir = .strip_root_prefix(dist_target_dir, root),
    version_record = .strip_root_prefix(
      file.path(target_dir, "VERSION"),
      root
    ),
    tarball = basename(tarball_path)
  )

  if (isTRUE(verbose)) {
    .emit_fetch_summary(result)
  }

  result
}

# Emit a short summary for the fetch CLI runner.
.emit_fetch_runner_summary <- function(result) {
  message(
    "Fetch complete: version=",
    result$version,
    ", path=",
    result$target_dir
  )
}

# Run the fetch stage from the command line.
run_fetch_webawesome <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_fetch_args(args)

  if (isTRUE(options$help)) {
    .print_fetch_help()
    return(invisible(NULL))
  }

  ui <- .cli_ui_new()
  ui$quiet <- !isTRUE(options$verbose)
  .cli_step_start(ui, "Fetching Web Awesome")

  result <- tryCatch(
    {
      fetch_webawesome(
        version = options$version,
        root = options$root,
        verbose = FALSE
      )
    },
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled(conditionMessage(condition))
    }
  )

  .cli_step_finish(ui, status = "Done")
  .emit_fetch_runner_summary(result)

  invisible(result)
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_fetch_webawesome)
}
# nolint end

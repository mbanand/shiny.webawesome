#!/usr/bin/env Rscript

# pkgdown site-build implementation for the shiny.webawesome repository.
#
# This file is both sourceable by tests and directly executable as a top-level
# tool entry point. It builds the documentation website using the checked-in
# pkgdown configuration.

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

.site_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .site_tool_base_dirs
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

# Return the CLI usage string for the site builder.
.build_site_usage <- function() {
  paste(
    "Usage: ./tools/build_site.R",
    paste(
      "[--root <path>] [--no-install] [--with-live-examples]",
      "[--preview] [--quiet] [--help]"
    )
  )
}

# Return the short CLI description for the site builder.
.build_site_description <- function() {
  "Build the pkgdown documentation site into the configured destination."
}

# List supported CLI options for the site builder.
.build_site_option_lines <- function() {
  c(
    paste(
      "--root <path>      Repository root.",
      "Defaults to the current directory."
    ),
    "--no-install        Do not install the package before building the site.",
    paste(
      "--with-live-examples",
      "Export standalone shinylive examples into the site."
    ),
    "--preview           Preview the site after the build completes.",
    "--quiet             Suppress tool-level progress messages.",
    "--help, -h          Print this help text."
  )
}

# Print the CLI help text for the site builder.
.print_build_site_help <- function() {
  writeLines(
    c(
      .build_site_description(),
      "",
      .build_site_usage(),
      "",
      "Options:",
      .build_site_option_lines()
    )
  )
}

# Define default CLI option values for the site builder.
.build_site_defaults <- function() {
  list(
    root = ".",
    install = TRUE,
    live_examples = FALSE,
    preview = FALSE,
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the site builder.
.parse_build_site_args <- function(args) {
  options <- .build_site_defaults()
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

    if (arg == "--no-install") {
      options$install <- FALSE
      next
    }

    if (arg == "--preview") {
      options$preview <- TRUE
      next
    }

    if (arg == "--with-live-examples") {
      options$live_examples <- TRUE
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
      paste0("Unknown argument: ", arg, "\n", .build_site_usage()),
      call. = FALSE
    )
  }

  options
}

# Check whether a path looks like the repository root for site builds.
.is_site_repo_root <- function(root) {
  required_paths <- c("DESCRIPTION", "projectdocs", "tools", "_pkgdown.yml")
  all(file.exists(file.path(root, required_paths)))
}

# Remove the repository root prefix from one or more absolute paths.
.strip_root_prefix <- function(paths, root) {
  sub(paste0("^", root, "/?"), "", paths)
}

# Return the default generated tool-documentation source directory.
.default_tool_doc_source_dir <- function() {
  file.path("tools", "man")
}

# Return the website directory used for copied tool docs.
.tool_doc_site_dir <- function(destination_dir) {
  file.path(destination_dir, "tool-docs")
}

# Return the default source directory for exported shinylive examples.
.default_shinylive_source_dir <- function() {
  file.path("vignettes", "shinylive-examples")
}

# Return the website directory used for exported shinylive examples.
.shinylive_site_dir <- function(destination_dir) {
  file.path(destination_dir, "live-examples")
}

# Remove any existing exported live-example directory from the built site.
.remove_live_examples <- function(destination_dir) {
  target_dir <- .shinylive_site_dir(destination_dir)

  if (dir.exists(target_dir)) {
    unlink(target_dir, recursive = TRUE, force = TRUE)
  }

  invisible(target_dir)
}

# Discover immediate shinylive example app directories in deterministic order.
.find_shinylive_example_dirs <- function(source_dir) {
  if (!dir.exists(source_dir)) {
    return(character())
  }

  example_dirs <- sort(
    list.dirs(source_dir, recursive = FALSE, full.names = TRUE)
  )

  example_dirs[file.exists(file.path(example_dirs, "app.R"))]
}

# Write a fallback page when a shinylive example is not exported.
.write_shinylive_placeholder <- function(target_dir, example_name, details) {
  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)

  lines <- c(
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    paste0("  <title>", example_name, " live demo unavailable</title>"),
    paste(
      "  <meta name=\"viewport\"",
      "content=\"width=device-width, initial-scale=1\">"
    ),
    "  <style>",
    "    body {",
    "      font-family: system-ui, sans-serif;",
    "      line-height: 1.5;",
    "      margin: 2rem auto;",
    "      max-width: 48rem;",
    "      padding: 0 1rem;",
    "    }",
    "    code {",
    "      background: #f4f4f4;",
    "      border-radius: 0.2rem;",
    "      padding: 0.1rem 0.3rem;",
    "    }",
    "  </style>",
    "</head>",
    "<body>",
    paste0("  <h1>", example_name, "</h1>"),
    "  <p>",
    "    This live demo was not exported for the current site build.",
    "  </p>",
    paste0("  <p>", details, "</p>"),
    "</body>",
    "</html>"
  )

  writeLines(lines, file.path(target_dir, "index.html"))
}

# Export shinylive examples into the built site or write placeholders.
.publish_live_examples <- function(root,
                                   destination_dir,
                                   source_dir =
                                     .default_shinylive_source_dir(),
                                   export_fun = NULL,
                                   fallback_to_installed = TRUE) {
  source_dir <- file.path(root, source_dir)
  example_dirs <- .find_shinylive_example_dirs(source_dir)

  if (length(example_dirs) == 0L) {
    return(invisible(character()))
  }

  target_root <- .shinylive_site_dir(destination_dir)
  dir.create(target_root, recursive = TRUE, showWarnings = FALSE)

  if (is.null(export_fun) && isTRUE(fallback_to_installed)) {
    if (requireNamespace("shinylive", quietly = TRUE)) {
      export_fun <- shinylive::export
    }
  }

  exported_paths <- character(length(example_dirs))

  for (i in seq_along(example_dirs)) {
    example_dir <- example_dirs[[i]]
    example_name <- basename(example_dir)
    target_dir <- file.path(target_root, example_name)

    if (dir.exists(target_dir)) {
      unlink(target_dir, recursive = TRUE, force = TRUE)
    }

    if (is.null(export_fun)) {
      .write_shinylive_placeholder(
        target_dir = target_dir,
        example_name = example_name,
        details = paste(
          "Install the `shinylive` package and its web assets, then rerun",
          "`./tools/build_site.R` to publish the exported app."
        )
      )

      exported_paths[[i]] <- target_dir
      next
    }

    dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)

    export_warnings <- character()
    export_error <- tryCatch(
      {
        withCallingHandlers(
          export_fun(
            appdir = example_dir,
            destdir = target_dir,
            quiet = TRUE
          ),
          warning = function(condition) {
            export_warnings <<- c(export_warnings, conditionMessage(condition))
            invokeRestart("muffleWarning")
          }
        )
        NULL
      },
      error = function(condition) {
        conditionMessage(condition)
      }
    )

    if (!is.null(export_error)) {
      unlink(target_dir, recursive = TRUE, force = TRUE)
      .write_shinylive_placeholder(
        target_dir = target_dir,
        example_name = example_name,
        details = paste(
          "The export step failed with:",
          export_error
        )
      )
    }

    if (length(export_warnings) > 0L) {
      unlink(target_dir, recursive = TRUE, force = TRUE)
      .write_shinylive_placeholder(
        target_dir = target_dir,
        example_name = example_name,
        details = paste(
          "The export step completed with warnings, so the live demo was not",
          "published. First warning:",
          export_warnings[[1]]
        )
      )
    }

    exported_paths[[i]] <- target_dir
  }

  invisible(.strip_root_prefix(exported_paths, root))
}

# Copy generated tool documentation into the built site.
.copy_tool_docs_to_site <- function(root,
                                    destination_dir,
                                    source_dir =
                                      .default_tool_doc_source_dir()) {
  source_dir <- file.path(root, source_dir)

  if (!dir.exists(source_dir)) {
    stop(
      paste(
        "Generated tool docs were not found under",
        .strip_root_prefix(source_dir, root),
        ". Run ./tools/document_tools.R first."
      ),
      call. = FALSE
    )
  }

  doc_files <- list.files(source_dir, full.names = TRUE, no.. = TRUE)
  if (length(doc_files) == 0L) {
    stop(
      paste(
        "Generated tool docs were not found under",
        .strip_root_prefix(source_dir, root),
        ". Run ./tools/document_tools.R first."
      ),
      call. = FALSE
    )
  }

  html_files <- doc_files[grepl("\\.html$", doc_files)]
  if (length(html_files) == 0L) {
    stop(
      paste(
        "No generated tool-doc HTML files were found under",
        .strip_root_prefix(source_dir, root),
        ". Run ./tools/document_tools.R first."
      ),
      call. = FALSE
    )
  }

  target_dir <- .tool_doc_site_dir(destination_dir)
  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
  file.copy(
    doc_files,
    file.path(target_dir, basename(doc_files)),
    overwrite = TRUE
  )

  r_css_path <- file.path(R.home("doc"), "html", "R.css")
  if (file.exists(r_css_path)) {
    file.copy(r_css_path, file.path(target_dir, "R.css"), overwrite = TRUE)
  }

  invisible(target_dir)
}

# Build the pkgdown site with optional output suppression.
.run_pkgdown_site_build <- function(root, install, preview, verbose) {
  result <- NULL

  if (isTRUE(verbose)) {
    result <- pkgdown::build_site(
      pkg = root,
      install = install,
      new_process = FALSE,
      preview = preview
    )
    return(result)
  }

  utils::capture.output(
    result <- withCallingHandlers(
      pkgdown::build_site(
        pkg = root,
        install = install,
        new_process = FALSE,
        preview = preview
      ),
      message = function(condition) {
        invokeRestart("muffleMessage")
      }
    ),
    type = "output"
  )

  result
}

#' Build the pkgdown documentation site
#'
#' Builds the repository documentation website using the checked-in
#' `_pkgdown.yml` configuration and writes the rendered output to the configured
#' destination directory.
#'
#' CLI entry point:
#' `./tools/build_site.R --help`
#'
#' When generated tool docs are present under `tools/man/`, this tool also
#' copies them into the built site under `tool-docs/`. When app sources are
#' present under `vignettes/shinylive-examples/`, this tool can also publish
#' matching standalone live-example targets under `live-examples/` when
#' `live_examples = TRUE`.
#'
#' @param root Repository root directory.
#' @param install Logical scalar. If `TRUE`, installs the package into a
#'   temporary library before building the site.
#' @param live_examples Logical scalar. If `TRUE`, exports standalone
#'   `shinylive` examples from `vignettes/shinylive-examples/` into the built
#'   site.
#' @param preview Logical scalar. If `TRUE`, asks `pkgdown` to preview the site
#'   after the build completes.
#' @param verbose Logical scalar. If `TRUE`, emits tool-level progress output.
#'
#' @return A list describing the site build, including the normalized root
#'   directory, the configured destination directory, and whether installation
#'   and preview were enabled.
#'
#' @examples
#' \dontrun{
#' build_site()
#' build_site(install = FALSE)
#' }
build_site <- function(root = ".",
                       install = TRUE,
                       live_examples = FALSE,
                       preview = FALSE,
                       verbose = interactive()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_site_repo_root(root)) {
    stop(
      paste(
        "`root` does not appear to be the repository root with",
        "a checked-in _pkgdown.yml."
      ),
      call. = FALSE
    )
  }

  if (!requireNamespace("pkgdown", quietly = TRUE)) {
    stop(
      "The `pkgdown` package is required to build the documentation site.",
      call. = FALSE
    )
  }

  pkg <- pkgdown::as_pkgdown(root)
  destination_dir <- normalizePath(
    pkg$dst_path,
    winslash = "/",
    mustWork = FALSE
  )

  ui <- .cli_ui_new()
  if (!isTRUE(verbose)) {
    ui$quiet <- TRUE
  }
  .cli_step_start(ui, "Building site")

  tryCatch(
    {
      .run_pkgdown_site_build(
        root = root,
        install = install,
        preview = preview,
        verbose = verbose
      )

      if (!dir.exists(destination_dir)) {
        stop(
          paste(
            "pkgdown did not create the configured destination directory:",
            .strip_root_prefix(destination_dir, root)
          ),
          call. = FALSE
        )
      }

      .copy_tool_docs_to_site(root = root, destination_dir = destination_dir)
      if (isTRUE(live_examples)) {
        .publish_live_examples(
          root = root,
          destination_dir = destination_dir
        )
      } else {
        .remove_live_examples(destination_dir)
      }

      .cli_step_finish(
        ui,
        status = "Done",
        comment = .strip_root_prefix(destination_dir, root)
      )
    },
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      .cli_abort_handled(conditionMessage(condition))
    }
  )

  invisible(list(
    root = root,
    destination = .strip_root_prefix(destination_dir, root),
    install = install,
    live_examples = live_examples,
    preview = preview
  ))
}

# Run the pkgdown site-build CLI entry point.
run_build_site <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_build_site_args(args)

  if (isTRUE(options$help)) {
    .print_build_site_help()
    return(invisible(NULL))
  }

  build_site(
    root = options$root,
    install = options$install,
    live_examples = options$live_examples,
    preview = options$preview,
    verbose = options$verbose
  )
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_build_site)
}
# nolint end

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
      "[--preview] [--strict-link-audit] [--quiet] [--help]"
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
    paste(
      "--strict-link-audit Fail if lychee is missing or reports broken",
      "website links."
    ),
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
    strict_link_audit = FALSE,
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

    if (arg == "--strict-link-audit") {
      options$strict_link_audit <- TRUE
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

# Remove any pre-existing generated site destination before pkgdown rebuilds it.
.reset_site_destination <- function(destination_dir) {
  if (dir.exists(destination_dir)) {
    unlink(destination_dir, recursive = TRUE, force = TRUE)
  }

  invisible(destination_dir)
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

# Export deferred live-example placeholders into the built site.
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
          "Live demo export is deferred for this release.",
          "The website currently publishes a placeholder page",
          "for this example instead."
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

# Parse one top-level scalar key from _pkgdown.yml.
.pkgdown_top_level_scalar <- function(root, key) {
  path <- file.path(root, "_pkgdown.yml")
  if (!file.exists(path)) {
    return(NA_character_)
  }

  lines <- trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
  pattern <- paste0("^", key, ":\\s*(.+?)\\s*$")
  matches <- regmatches(lines, regexec(pattern, lines, perl = TRUE))
  values <- vapply(
    matches,
    function(match) {
      if (length(match) >= 2L) {
        match[[2]]
      } else {
        NA_character_
      }
    },
    character(1)
  )
  values <- values[!is.na(values) & nzchar(values)]

  if (length(values) == 0L) {
    return(NA_character_)
  }

  values[[1]]
}

# Return the configured site URL from _pkgdown.yml when present.
.site_url <- function(root) {
  value <- .pkgdown_top_level_scalar(root, "url")

  if (is.na(value)) {
    return(NA_character_)
  }

  sub("/+$", "", value)
}

# Escape regular-expression metacharacters in one literal string.
.regex_escape <- function(value) {
  gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", value, perl = TRUE)
}

# Return lychee URL patterns that should be ignored for generated site output.
.lychee_exclude_patterns <- function(root) {
  repo_url <- "https://github.com/mbanand/shiny.webawesome"

  c(
    paste0("^", .regex_escape(repo_url), "/blob/HEAD/"),
    paste(
      "^file://.*/articles/.+_files/shiny\\.webawesome-[^/]+/",
      "(html(?:/|$)|NEWS(?:\\.md)?$)"
    )
  )
}

# Return lychee path patterns that should be ignored for generated site output.
.lychee_exclude_paths <- function(root) {
  c(
    ".*/articles/.+_files/shiny\\.webawesome-[^/]+/html(?:/|$)",
    ".*/articles/.+_files/shiny\\.webawesome-[^/]+/NEWS(?:\\.md)?$"
  )
}

# Run one child command using processx.
.run_process <- function(command,
                         args = character(),
                         wd = ".",
                         env = character()) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop(
      "The `processx` package is required to run site-audit commands.",
      call. = FALSE
    )
  }

  child_env <- if (length(env) == 0L) {
    NULL
  } else {
    current <- Sys.getenv(names = TRUE, unset = NA_character_)
    current[names(env)] <- unname(env)
    current
  }

  processx::run(
    command = command,
    args = args,
    wd = wd,
    echo = FALSE,
    error_on_status = FALSE,
    env = child_env
  )
}

# Collapse child command output into deterministic non-empty lines.
.process_output_lines <- function(result) {
  combined <- c(result$stdout, result$stderr)
  lines <- unlist(
    strsplit(paste(combined, collapse = "\n"), "\n", fixed = TRUE)
  )
  unique(lines[nzchar(trimws(lines))])
}

# Return the preferred lychee executable path, allowing an explicit override.
.lychee_command <- function() {
  override <- Sys.getenv("SHINY_WEBAWESOME_LYCHEE", unset = "")
  if (nzchar(override)) {
    if (!file.exists(override)) {
      stop(
        paste(
          "`SHINY_WEBAWESOME_LYCHEE` does not exist:",
          override
        ),
        call. = FALSE
      )
    }

    return(normalizePath(override, winslash = "/", mustWork = TRUE))
  }

  Sys.which("lychee")
}

# Audit built website links with lychee.
.audit_website_links <- function(root,
                                 destination_dir,
                                 strict = FALSE,
                                 runner = .run_process) {
  lychee <- .lychee_command()
  if (!nzchar(lychee)) {
    return(list(
      ok = FALSE,
      details = paste(
        "Could not find `lychee` on PATH for website link auditing.",
        "Install a standalone `lychee` binary or set",
        "`SHINY_WEBAWESOME_LYCHEE=/path/to/lychee`."
      ),
      fatal = isTRUE(strict)
    ))
  }

  if (grepl("(^|/)(snap/bin|snapd?/)", lychee)) {
    return(list(
      ok = FALSE,
      details = paste(
        "Detected a snap-packaged `lychee` at",
        paste0("`", lychee, "`."),
        "Its filesystem confinement cannot audit the repository reliably.",
        "Install a standalone `lychee` binary and either put it earlier on",
        "PATH or set `SHINY_WEBAWESOME_LYCHEE=/path/to/lychee`."
      ),
      fatal = isTRUE(strict)
    ))
  }

  site_url <- .site_url(root)

  args <- c(
    "--no-progress",
    "--root-dir",
    destination_dir,
    "--fallback-extensions",
    "html",
    "--index-files",
    "index.html,."
  )

  exclude_patterns <- .lychee_exclude_patterns(root)
  if (length(exclude_patterns) > 0L) {
    for (pattern in exclude_patterns) {
      args <- c(args, "--exclude", pattern)
    }
  }

  exclude_paths <- .lychee_exclude_paths(root)
  if (length(exclude_paths) > 0L) {
    for (pattern in exclude_paths) {
      args <- c(args, "--exclude-path", pattern)
    }
  }

  if (!is.na(site_url)) {
    args <- c(
      args,
      "--remap",
      paste(
        paste0("^", .regex_escape(site_url), "([?#/]|$)"),
        paste0("file://", destination_dir, "\\$1")
      )
    )
  }

  args <- c(args, destination_dir)

  result <- runner(
    command = lychee,
    args = args,
    wd = root
  )

  ok <- identical(result$status, 0L)
  details <- .process_output_lines(result)

  if (ok) {
    return(list(
      ok = TRUE,
      details = if (length(details) == 0L) NULL else details,
      data = list(command = lychee, args = args, output = details)
    ))
  }

  if (length(details) == 0L) {
    details <- "lychee reported broken website links."
  }

  list(
    ok = FALSE,
    details = details,
    fatal = isTRUE(strict),
    data = list(command = lychee, args = args, output = details)
  )
}

# Build the pkgdown site with optional output suppression.
.run_pkgdown_site_build <- function(root, install, preview, verbose) {
  result <- NULL

  if (isTRUE(verbose)) {
    result <- pkgdown::build_site(
      pkg = root,
      examples = FALSE,
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
        examples = FALSE,
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

# Build the site and return a structured stage result.
.build_site_stage <- function(root,
                              install = TRUE,
                              live_examples = FALSE,
                              preview = FALSE,
                              strict_link_audit = FALSE,
                              verbose = interactive()) {
  pkg <- pkgdown::as_pkgdown(root)
  destination_dir <- normalizePath(
    pkg$dst_path,
    winslash = "/",
    mustWork = FALSE
  )

  .reset_site_destination(destination_dir)

  .run_pkgdown_site_build(
    root = root,
    install = install,
    preview = preview,
    verbose = verbose
  )

  if (!dir.exists(destination_dir)) {
    return(list(
      ok = FALSE,
      warning = FALSE,
      details = paste(
        "pkgdown did not create the configured destination directory:",
        .strip_root_prefix(destination_dir, root)
      ),
      destination = destination_dir
    ))
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

  audit <- .audit_website_links(
    root = root,
    destination_dir = destination_dir,
    strict = strict_link_audit
  )

  list(
    ok = isTRUE(audit$ok),
    warning = !isTRUE(audit$ok) && !isTRUE(strict_link_audit) &&
      !isTRUE(audit$fatal),
    details = audit$details %||% character(),
    destination = destination_dir,
    audit = audit
  )
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
#' `live_examples = TRUE`. It also audits the built local site links with
#' `lychee`.
#'
#' @details
#' If `lychee` is not on `PATH`, set
#' `SHINY_WEBAWESOME_LYCHEE=/path/to/lychee`.
#'
#' @param root Repository root directory.
#' @param install Logical scalar. If `TRUE`, installs the package into a
#'   temporary library before building the site.
#' @param live_examples Logical scalar. If `TRUE`, exports standalone
#'   `shinylive` examples from `vignettes/shinylive-examples/` into the built
#'   site.
#' @param preview Logical scalar. If `TRUE`, asks `pkgdown` to preview the site
#'   after the build completes.
#' @param strict_link_audit Logical scalar. If `TRUE`, fail when `lychee` is
#'   missing or reports broken website links after the site build.
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
                       strict_link_audit = FALSE,
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

  ui <- .cli_ui_new()
  if (!isTRUE(verbose)) {
    ui$quiet <- TRUE
  }
  .cli_step_start(ui, "Building site")

  tryCatch(
    {
      stage <- .build_site_stage(
        root = root,
        install = install,
        live_examples = live_examples,
        preview = preview,
        strict_link_audit = strict_link_audit,
        verbose = verbose
      )

      destination_dir <- stage$destination

      if (!isTRUE(stage$ok)) {
        if (!isTRUE(stage$warning)) {
          .cli_step_fail(ui, details = stage$details)
          .cli_abort_handled(paste(stage$details, collapse = "\n"))
        }

        .cli_step_finish(ui, status = "Warn")
        cat(
          paste(stage$details, collapse = "\n"),
          "\n",
          file = stderr(),
          sep = ""
        )
      } else {
        .cli_step_finish(
          ui,
          status = "Done",
          comment = .strip_root_prefix(destination_dir, root)
        )
        if (length(stage$details %||% character()) > 0L) {
          cat(
            paste(stage$details, collapse = "\n"),
            "\n",
            file = stderr(),
            sep = ""
          )
        }
      }
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
    preview = preview,
    strict_link_audit = strict_link_audit
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
    strict_link_audit = options$strict_link_audit,
    verbose = options$verbose
  )
}

if (sys.nframe() == 0L) {
  .cli_run_main(run_build_site)
}
# nolint end

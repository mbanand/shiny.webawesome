#!/usr/bin/env Rscript

# Finalize-stage implementation for the shiny.webawesome build pipeline.
#
# This file is both sourceable by tests and directly executable as a top-level
# build-stage script. It performs the recurring late-stage local
# release-preparation workflow and writes finalize handoff artifacts.

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

.finalize_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .finalize_tool_base_dirs
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
  base_dirs <- .finalize_tool_base_dirs
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

# Return the CLI usage string for the finalize stage.
.finalize_package_usage <- function() {
  paste(
    "Usage: ./tools/finalize_package.R",
    paste(
      "[--root <path>] [--strict]",
      "[--confirmed-rhub-pass] [--confirmed-visual-review]",
      "[--quiet] [--help]"
    )
  )
}

# Return the short CLI description for the finalize stage.
.finalize_package_description <- function() {
  paste(
    "Run the late-stage local release-preparation workflow and",
    "write finalize handoff artifacts."
  )
}

# List supported CLI options for the finalize stage.
.finalize_package_option_lines <- function() {
  c(
    paste(
      "--root <path>                 Repository root.",
      "Defaults to the current directory."
    ),
    "--strict                      Fail on any release gate.",
    paste(
      "--confirmed-rhub-pass         Confirm that external release checks",
      "such as rhub have passed."
    ),
    paste(
      "--confirmed-visual-review     Confirm that the final manual visual",
      "review has passed."
    ),
    "--quiet                       Suppress stage-level progress messages.",
    "--help, -h                    Print this help text."
  )
}

# Print the CLI help text for the finalize stage.
.print_finalize_package_help <- function() {
  writeLines(
    c(
      .finalize_package_description(),
      "",
      .finalize_package_usage(),
      "",
      "Options:",
      .finalize_package_option_lines()
    )
  )
}

# Define default CLI option values for the finalize stage.
.finalize_package_defaults <- function() {
  list(
    root = ".",
    strict = FALSE,
    confirmed_rhub_pass = FALSE,
    confirmed_visual_review = FALSE,
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the finalize stage.
.parse_finalize_package_args <- function(args) {
  options <- .finalize_package_defaults()
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

    if (arg == "--strict") {
      options$strict <- TRUE
      next
    }

    if (arg == "--confirmed-rhub-pass") {
      options$confirmed_rhub_pass <- TRUE
      next
    }

    if (arg == "--confirmed-visual-review") {
      options$confirmed_visual_review <- TRUE
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
      paste0("Unknown argument: ", arg, "\n", .finalize_package_usage()),
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

# Return stage-owned surfaces that should not already exist before a strict run.
.strict_release_start_surfaces <- function() {
  c(
    "vendor/webawesome",
    "inst/extdata/webawesome",
    "inst/www/wa",
    "inst/bindings"
  )
}

# Return generated R files that should not already exist before a strict run.
.generated_r_files <- function(root) {
  r_dir <- file.path(root, "R")
  if (!dir.exists(r_dir)) {
    return(character())
  }

  paths <- list.files(r_dir, pattern = "\\.[Rr]$", full.names = TRUE)
  if (length(paths) == 0L) {
    return(character())
  }

  owned <- vapply(
    paths,
    function(path) {
      lines <- readLines(path, n = 1L, warn = FALSE)
      length(lines) > 0L &&
        identical(lines[[1]], .generated_file_marker())
    },
    logical(1)
  )

  sort(paths[owned])
}

# Fail early when strict finalize is requested from a non-clean release start.
.assert_strict_start_state <- function(root = ".") {
  stale_paths <- .strict_release_start_surfaces()
  existing <- stale_paths[file.exists(file.path(root, stale_paths))]

  generated_r <- .generated_r_files(root)
  if (length(generated_r) > 0L) {
    existing <- c(
      existing,
      .strip_root_prefix(
        normalizePath(generated_r, winslash = "/", mustWork = TRUE),
        root
      )
    )
  }

  existing <- sort(unique(existing))

  if (length(existing) == 0L) {
    return(invisible(TRUE))
  }

  stop(
    paste(
      "Strict finalize requires a clean release-build starting state.",
      "Remove existing stage-owned artifacts first, for example by running",
      "`clean_webawesome(level = \"distclean\")`.",
      "Found:",
      paste(existing, collapse = ", ")
    ),
    call. = FALSE
  )
}

# Return the finalize manifest directory.
.finalize_manifest_dir <- function(root) {
  file.path(root, "manifests", "finalize")
}

# Return the finalize report directory.
.finalize_report_dir <- function(root) {
  file.path(root, "reports", "finalize")
}

# Return the machine-readable finalize handoff path.
.finalize_handoff_path <- function(root) {
  file.path(.finalize_manifest_dir(root), "release-handoff.yaml")
}

# Return the human-readable finalize summary path.
.finalize_summary_path <- function(root) {
  file.path(.finalize_report_dir(root), "summary.md")
}

# Write one deterministic text file.
.write_text_file <- function(path, text) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(enc2utf8(text), path, useBytes = TRUE)
  invisible(path)
}

# Return the path to the local check_integrity stage script.
.check_integrity_script <- function(root) {
  file.path(root, "tools", "check_integrity.R")
}

# Run one child command using processx.
.run_process <- function(command,
                         args = character(),
                         wd = ".",
                         env = character()) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop(
      "The `processx` package is required to run finalize commands.",
      call. = FALSE
    )
  }

  processx::run(
    command = command,
    args = args,
    wd = wd,
    echo = FALSE,
    error_on_status = FALSE,
    env = env
  )
}

# Collapse child command output into a deterministic character vector.
.process_output_lines <- function(result) {
  combined <- c(result$stdout, result$stderr)
  lines <- unlist(
    strsplit(paste(combined, collapse = "\n"), "\n", fixed = TRUE)
  )
  unique(lines[nzchar(lines)])
}

# Build one Rscript expression child-command descriptor.
.rscript_command <- function(expr) {
  list(command = "Rscript", args = c("-e", expr))
}

# Return the relative handwritten JavaScript files to lint.
.handwritten_js_files <- function(root) {
  candidates <- c(file.path("inst", "www", "webawesome-init.js"))
  candidates[file.exists(file.path(root, candidates))]
}

# Return the child command descriptor for handwritten JS linting.
.eslint_command <- function(root) {
  js_files <- .handwritten_js_files(root)
  if (length(js_files) == 0L) {
    return(NULL)
  }

  eslint <- Sys.which("eslint")
  if (nzchar(eslint)) {
    return(list(command = eslint, args = js_files))
  }

  npx <- Sys.which("npx")
  if (nzchar(npx)) {
    return(list(command = npx, args = c("--no-install", "eslint", js_files)))
  }

  stop(
    "Could not find `eslint` or `npx` on PATH for handwritten JS linting.",
    call. = FALSE
  )
}

# Emit non-fatal warning details under the current step.
.emit_warning_details <- function(ui, details) {
  if (length(details) == 0L) {
    return(invisible(NULL))
  }

  if (isTRUE(ui$quiet)) {
    cat(paste(details, collapse = "\n"), "\n", file = stderr(), sep = "")
    return(invisible(NULL))
  }

  cat(paste(details, collapse = "\n"), "\n", file = stderr(), sep = "")
}

# Return the non-empty R and R Markdown files under one directory.
.collect_code_files <- function(root, rel_dir) {
  abs_dir <- file.path(root, rel_dir)
  if (!dir.exists(abs_dir)) {
    return(character())
  }

  paths <- list.files(
    abs_dir,
    pattern = "\\.(R|r|Rmd|rmd)$",
    recursive = TRUE,
    full.names = TRUE
  )

  sort(paths[file.info(paths)$isdir %in% FALSE])
}

# Return the code lines from one file for dependency scanning.
.dependency_scan_lines <- function(path) {
  lines <- readLines(path, warn = FALSE)

  if (grepl("\\.[Rr]md$", path)) {
    in_chunk <- FALSE
    keep <- logical(length(lines))

    for (i in seq_along(lines)) {
      line <- lines[[i]]

      if (grepl("^```\\s*\\{[Rr][^}]*\\}\\s*$", line)) {
        in_chunk <- TRUE
        next
      }

      if (in_chunk && grepl("^```\\s*$", line)) {
        in_chunk <- FALSE
        next
      }

      if (in_chunk) {
        keep[[i]] <- TRUE
      }
    }

    lines <- lines[keep]
  }

  lines
}

# Return the discovered package references from one set of source files.
.scan_package_references <- function(paths) {
  if (length(paths) == 0L) {
    return(character())
  }

  namespace_matches <- character()
  attach_matches <- character()
  attach_pattern <- paste0(
    "(library|require|requireNamespace)",
    "\\((?:package\\s*=\\s*)?[\"']?([A-Za-z][A-Za-z0-9.]*)[\"']?"
  )
  attach_extract_pattern <- paste0(
    "^(library|require|requireNamespace)",
    "\\((?:package\\s*=\\s*)?[\"']?([A-Za-z][A-Za-z0-9.]*)[\"']?.*$"
  )

  for (path in paths) {
    lines <- .dependency_scan_lines(path)
    if (length(lines) == 0L) {
      next
    }

    text <- paste(lines, collapse = "\n")

    current_namespace <- regmatches(
      text,
      gregexpr(
        "([A-Za-z][A-Za-z0-9.]*):::{0,2}",
        text,
        perl = TRUE
      )
    )[[1]]
    if (length(current_namespace) > 0L) {
      namespace_matches <- c(
        namespace_matches,
        sub(":::{0,2}$", "", current_namespace)
      )
    }

    current_attach <- regmatches(
      text,
      gregexpr(
        attach_pattern,
        text,
        perl = TRUE
      )
    )[[1]]
    if (length(current_attach) > 0L) {
      attach_matches <- c(
        attach_matches,
        sub(
          attach_extract_pattern,
          "\\2",
          current_attach,
          perl = TRUE
        )
      )
    }
  }

  pkgs <- sort(unique(c(namespace_matches, attach_matches)))
  pkgs[nzchar(pkgs)]
}

# Return base and recommended package names to exclude from audits.
.base_recommended_packages <- function() {
  installed <- tryCatch(
    rownames(utils::installed.packages(priority = c("base", "recommended"))),
    error = function(...) character()
  )

  sort(unique(c(
    "base", "compiler", "datasets", "graphics", "grDevices",
    "grid", "methods", "parallel", "splines", "stats",
    "stats4", "tcltk", "tools", "utils", installed
  )))
}

# Parse one DESCRIPTION package field into a character vector.
.description_packages <- function(root, field) {
  desc <- read.dcf(file.path(root, "DESCRIPTION"))

  if (!field %in% colnames(desc)) {
    return(character())
  }

  values <- trimws(unlist(strsplit(desc[[1, field]], ",", fixed = TRUE)))
  values <- sub("\\s*\\(.*\\)$", "", values)
  sort(unique(values[nzchar(values)]))
}

# Audit the currently declared package dependencies.
.audit_dependencies <- function(root) {
  imports <- .description_packages(root, "Imports")
  suggests <- .description_packages(root, "Suggests")
  known <- sort(unique(c(imports, suggests, "shiny.webawesome")))
  excluded <- .base_recommended_packages()

  package_refs <- setdiff(
    .scan_package_references(.collect_code_files(root, "R")),
    excluded
  )
  tool_refs <- setdiff(
    .scan_package_references(c(
      .collect_code_files(root, "tools"),
      .collect_code_files(root, "tests"),
      .collect_code_files(root, "vignettes")
    )),
    excluded
  )

  missing_imports <- setdiff(package_refs, imports)
  missing_support <- setdiff(tool_refs, known)

  details <- character()

  if (length(missing_imports) > 0L) {
    details <- c(
      details,
      paste0(
        "Packages referenced from `R/` but missing from DESCRIPTION Imports: ",
        paste(missing_imports, collapse = ", ")
      )
    )
  }

  if (length(missing_support) > 0L) {
    details <- c(
      details,
      paste0(
        "Packages referenced from tooling/tests/vignettes but undeclared in ",
        "DESCRIPTION Imports or Suggests: ",
        paste(missing_support, collapse = ", ")
      )
    )
  }

  list(
    ok = length(details) == 0L,
    details = details,
    data = list(
      package_refs = package_refs,
      tool_refs = tool_refs,
      imports = imports,
      suggests = suggests
    )
  )
}

# Return one deterministic record for the current website tree.
.website_tree_record <- function(root) {
  relative_files <- .integrity_list_relative_files(root, "website")
  .build_integrity_record(
    root = root,
    stage = "finalize",
    surface_name = "website",
    surface_roots = "website",
    relative_files = relative_files
  )
}

# Return one deterministic record for the current tracked git tree.
.tracked_tree_record <- function(root, runner = .run_process) {
  result <- runner(
    command = "git",
    args = "ls-files",
    wd = root
  )

  if (!identical(result$status, 0L)) {
    stop(
      paste(.process_output_lines(result), collapse = "\n"),
      call. = FALSE
    )
  }

  output <- paste(c(result$stdout, result$stderr), collapse = "\n")
  relative_files <- strsplit(output, "\n", fixed = TRUE)[[1]]
  relative_files <- sort(relative_files[nzchar(relative_files)])

  .build_integrity_record(
    root = root,
    stage = "finalize",
    surface_name = "tracked_git_tree",
    surface_roots = ".",
    relative_files = relative_files
  )
}

# Return the current git HEAD commit.
.git_head_commit <- function(root, runner = .run_process) {
  result <- runner(
    command = "git",
    args = c("rev-parse", "HEAD"),
    wd = root
  )

  if (!identical(result$status, 0L)) {
    stop(
      paste(.process_output_lines(result), collapse = "\n"),
      call. = FALSE
    )
  }

  trimws(paste(result$stdout, collapse = "\n"))
}

# Return the package version from DESCRIPTION.
.package_version <- function(root) {
  read.dcf(file.path(root, "DESCRIPTION"))[[1, "Version"]]
}

# Return the status label for one finalize run.
.finalize_status <- function(warnings) {
  if (length(warnings) == 0L) {
    "pass"
  } else {
    "warn"
  }
}

# Write the finalize handoff YAML file.
.write_finalize_handoff <- function(root, handoff) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "The `yaml` package is required to write finalize handoff records.",
      call. = FALSE
    )
  }

  path <- .finalize_handoff_path(root)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  yaml_text <- yaml::as.yaml(
    handoff,
    indent.mapping.sequence = TRUE,
    line.sep = "\n"
  )
  text <- paste(
    c(
      "# Generated by tools/finalize_package.R. Do not edit by hand.",
      yaml_text
    ),
    collapse = "\n"
  )
  writeLines(enc2utf8(text), path, useBytes = TRUE)

  .strip_root_prefix(path, root)
}

# Return the human-readable finalize summary lines.
.finalize_summary_lines <- function(handoff) {
  warning_lines <- handoff$warnings

  c(
    "# Finalize Summary",
    "",
    "Generated by tools/finalize_package.R. Do not edit by hand.",
    "",
    paste0("- Status: `", handoff$status, "`"),
    paste0("- Mode: `", handoff$mode, "`"),
    paste0("- Package version: `", handoff$package_version, "`"),
    paste0("- Git HEAD: `", handoff$git_head, "`"),
    paste0(
      "- Tarball: `",
      handoff$artifacts$tarball$path %||% "Unavailable",
      "`"
    ),
    paste0(
      "- Tarball digest: `",
      handoff$artifacts$tarball$digest %||% "",
      "`"
    ),
    paste0(
      "- Website root: `",
      handoff$artifacts$website$path %||% "Unavailable",
      "`"
    ),
    paste0(
      "- Website tree digest: `",
      handoff$artifacts$website$tree_digest %||% "",
      "`"
    ),
    paste0(
      "- Tracked git tree digest: `",
      handoff$artifacts$tracked_tree$tree_digest,
      "`"
    ),
    "",
    "## Warnings",
    "",
    if (length(warning_lines) == 0L) {
      "- None."
    } else {
      unlist(
        lapply(
          names(warning_lines),
          function(name) {
            c(
              paste0("- `", name, "`"),
              paste0("  ", warning_lines[[name]])
            )
          }
        ),
        use.names = FALSE
      )
    }
  )
}

# Write the finalize Markdown summary file.
.write_finalize_summary <- function(root, handoff) {
  path <- .finalize_summary_path(root)
  .write_text_file(path, .finalize_summary_lines(handoff))
  .strip_root_prefix(path, root)
}

# Remove any stale finalize handoff artifacts before a new run.
.clean_finalize_outputs <- function(root) {
  targets <- c(.finalize_manifest_dir(root), .finalize_report_dir(root))
  removed <- character()

  for (path in targets) {
    if (dir.exists(path) || file.exists(path)) {
      unlink(path, recursive = TRUE, force = TRUE)
      removed <- c(removed, .strip_root_prefix(path, root))
    }
  }

  list(
    ok = TRUE,
    details = if (length(removed) == 0L) {
      "No stale finalize outputs found."
    } else {
      paste0(
        "Removed stale finalize outputs: ",
        paste(removed, collapse = ", ")
      )
    }
  )
}

# Run the existing integrity stage as part of finalize.
.run_integrity_step <- function(root, runner = .run_process) {
  script <- .check_integrity_script(root)
  result <- runner(
    command = paste0("./", .strip_root_prefix(script, root)),
    args = "--quiet",
    wd = root,
    env = c(SHINY_WEBAWESOME_CLI_MODE = "plain")
  )

  if (!identical(result$status, 0L)) {
    return(list(ok = FALSE, details = .process_output_lines(result)))
  }

  list(ok = TRUE, details = .process_output_lines(result))
}

# Run one child command as one finalize validation step.
.run_command_step <- function(command,
                              args = character(),
                              root,
                              runner = .run_process,
                              env = character()) {
  result <- runner(
    command = command,
    args = args,
    wd = root,
    env = env
  )

  ok <- identical(result$status, 0L)
  list(
    ok = ok,
    details = .process_output_lines(result),
    result = result
  )
}

# Return the step definitions for a real finalize run.
.finalize_steps <- function(runner = .run_process) {
  list(
    cleanup = list(
      label = "Cleaning finalize outputs",
      fatal = TRUE,
      run = function(context) .clean_finalize_outputs(context$root)
    ),
    integrity = list(
      label = "Checking integrity",
      fatal = TRUE,
      run = function(context) {
        .run_integrity_step(
          root = context$root,
          runner = context$runner
        )
      }
    ),
    style = list(
      label = "Checking R style",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) {
        expr <- paste(
          "if (!requireNamespace('styler', quietly = TRUE))",
          paste(
            "stop('The `styler` package is required for finalize style",
            "checks.', call. = FALSE);"
          ),
          "targets <- c('R', 'tests', 'tools', 'vignettes');",
          "targets <- targets[file.exists(targets)];",
          "if (length(targets) > 0L) {",
          paste(
            "  invisible(lapply(targets, function(path)",
            "styler::style_dir(path, dry = 'fail')))"
          ),
          "}"
        )
        cmd <- .rscript_command(expr)
        .run_command_step(
          command = cmd$command,
          args = cmd$args,
          root = context$root,
          runner = context$runner
        )
      }
    ),
    lint = list(
      label = "Checking R lint",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) {
        expr <- paste(
          "if (!requireNamespace('lintr', quietly = TRUE))",
          paste(
            "stop('The `lintr` package is required for finalize lint",
            "checks.', call. = FALSE);"
          ),
          "targets <- c('R', 'tests', 'tools', 'vignettes');",
          "targets <- targets[file.exists(targets)];",
          "results <- list();",
          "if (length(targets) > 0L) {",
          "  for (path in targets) {",
          "    results[[path]] <- lintr::lint_dir(path)",
          "  }",
          "}",
          "all_results <- unlist(results, recursive = FALSE);",
          "if (length(all_results) > 0L) {",
          "  print(all_results);",
          "  stop('Lint issues detected.', call. = FALSE)",
          "}"
        )
        cmd <- .rscript_command(expr)
        .run_command_step(
          command = cmd$command,
          args = cmd$args,
          root = context$root,
          runner = context$runner
        )
      }
    ),
    js_lint = list(
      label = "Checking handwritten JavaScript lint",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) {
        cmd <- .eslint_command(context$root)
        if (is.null(cmd)) {
          return(
            list(
              ok = TRUE,
              details = "No handwritten JavaScript files found."
            )
          )
        }

        .run_command_step(
          command = cmd$command,
          args = cmd$args,
          root = context$root,
          runner = context$runner
        )
      }
    ),
    dependency_audit = list(
      label = "Auditing dependencies",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) .audit_dependencies(context$root)
    ),
    document = list(
      label = "Documenting package",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) {
        expr <- paste(
          "if (!requireNamespace('devtools', quietly = TRUE))",
          paste(
            "stop('The `devtools` package is required for finalize",
            "documentation.', call. = FALSE);"
          ),
          "devtools::document(quiet = TRUE)"
        )
        cmd <- .rscript_command(expr)
        .run_command_step(
          command = cmd$command,
          args = cmd$args,
          root = context$root,
          runner = context$runner
        )
      }
    ),
    test = list(
      label = "Testing package",
      fatal = TRUE,
      run = function(context) {
        expr <- paste(
          "if (!requireNamespace('devtools', quietly = TRUE))",
          paste(
            "stop('The `devtools` package is required for finalize",
            "testing.', call. = FALSE);"
          ),
          "devtools::test(stop_on_failure = TRUE)"
        )
        cmd <- .rscript_command(expr)
        .run_command_step(
          command = cmd$command,
          args = cmd$args,
          root = context$root,
          runner = context$runner
        )
      }
    ),
    site = list(
      label = "Building website",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) {
        .run_command_step(
          command = "./tools/build_site.R",
          args = "--quiet",
          root = context$root,
          runner = context$runner,
          env = c(SHINY_WEBAWESOME_CLI_MODE = "plain")
        )
      }
    ),
    check = list(
      label = "Checking package",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) {
        expr <- paste(
          "if (!requireNamespace('devtools', quietly = TRUE))",
          paste(
            "stop('The `devtools` package is required for finalize",
            "checks.', call. = FALSE);"
          ),
          "devtools::check(document = FALSE, error_on = 'warning')"
        )
        cmd <- .rscript_command(expr)
        .run_command_step(
          command = cmd$command,
          args = cmd$args,
          root = context$root,
          runner = context$runner
        )
      }
    ),
    confirmations = list(
      label = "Checking external confirmations",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) {
        if (!isTRUE(context$strict)) {
          return(list(
            ok = TRUE,
            details = c(
              "Next steps:",
              "- Run external pre-release checks such as rhub separately.",
              paste(
                "- Run the representative Shiny review app and complete the",
                "manual visual review separately."
              )
            )
          ))
        }

        details <- character()
        if (!isTRUE(context$confirmed_rhub_pass)) {
          details <- c(
            details,
            "Strict finalize requires --confirmed-rhub-pass."
          )
        }
        if (!isTRUE(context$confirmed_visual_review)) {
          details <- c(
            details,
            "Strict finalize requires --confirmed-visual-review."
          )
        }

        list(ok = length(details) == 0L, details = details)
      }
    ),
    build = list(
      label = "Building package tarball",
      fatal = TRUE,
      run = function(context) {
        expr <- paste(
          "if (!requireNamespace('devtools', quietly = TRUE))",
          paste(
            "stop('The `devtools` package is required for finalize",
            "builds.', call. = FALSE);"
          ),
          "path <- devtools::build(path = '.', manual = FALSE, quiet = TRUE);",
          "cat(normalizePath(path, winslash = '/', mustWork = FALSE))"
        )
        cmd <- .rscript_command(expr)
        step <- .run_command_step(
          command = cmd$command,
          args = cmd$args,
          root = context$root,
          runner = context$runner
        )

        tarball_path <- trimws(paste(step$result$stdout, collapse = "\n"))
        if (isTRUE(step$ok) && !nzchar(tarball_path)) {
          step$ok <- FALSE
          step$details <- c(
            step$details,
            "Finalize build did not return a tarball path."
          )
        }

        step$data <- list(tarball_path = tarball_path)
        step
      }
    )
  )
}

# Run one finalize step with the configured fatality policy.
.execute_finalize_step <- function(name, step, context, ui) {
  .cli_step_start(ui, step$label)

  result <- tryCatch(
    step$run(context),
    error = function(condition) {
      list(ok = FALSE, details = conditionMessage(condition))
    }
  )

  if (!isTRUE(result$ok)) {
    details <- result$details %||% "Step failed."
    fatal <- if (is.function(step$fatal)) {
      isTRUE(step$fatal(context))
    } else {
      isTRUE(step$fatal)
    }

    if (fatal) {
      .cli_step_fail(ui, details = details)
      stop(paste(details, collapse = "\n"), call. = FALSE)
    }

    .cli_step_finish(ui, status = "Warn")
    .emit_warning_details(ui, details)
    return(list(name = name, result = result, warning = TRUE))
  }

  if (
    identical(name, "confirmations") &&
      !isTRUE(context$strict) &&
      length(result$details %||% character()) > 0L
  ) {
    .cli_step_finish(ui, status = "Done")
    .emit_warning_details(ui, result$details)
  } else {
    .cli_step_finish(ui, status = "Done")
  }

  list(name = name, result = result, warning = FALSE)
}

# Build the finalize handoff record from the current repo state.
.build_finalize_handoff <- function(root,
                                    strict,
                                    warnings,
                                    tarball_path,
                                    runner) {
  tarball_digest <- if (
    !is.null(tarball_path) &&
      nzchar(tarball_path) &&
      file.exists(tarball_path)
  ) {
    .file_sha256(tarball_path)
  } else {
    NULL
  }

  website_record <- .website_tree_record(root)
  tracked_tree <- .tracked_tree_record(root, runner = runner)
  git_head <- .git_head_commit(root, runner = runner)

  list(
    schema_version = 1L,
    record_type = "finalize_handoff",
    generated_at = .integrity_timestamp(),
    status = .finalize_status(warnings),
    mode = if (isTRUE(strict)) "strict" else "default",
    package_version = .package_version(root),
    git_head = git_head,
    warnings = warnings,
    artifacts = list(
      tarball = list(
        path = if (is.null(tarball_path) || !nzchar(tarball_path)) {
          NULL
        } else {
          tarball_path
        },
        digest = tarball_digest
      ),
      website = list(
        path = if (dir.exists(file.path(root, "website"))) {
          "website"
        } else {
          NULL
        },
        file_count = website_record$summary$file_count,
        tree_digest = website_record$summary$tree_digest
      ),
      tracked_tree = list(
        file_count = tracked_tree$summary$file_count,
        tree_digest = tracked_tree$summary$tree_digest
      )
    )
  )
}

#' Run the finalize-stage package workflow
#'
#' Executes the recurring late-stage local release-preparation workflow,
#' including integrity checks, non-mutating validation gates, package
#' documentation and tarball generation, and finalize handoff recording.
#'
#' The finalize workflow expects ESLint to be available for handwritten
#' JavaScript linting. The current official bootstrap command for repository
#' setup is `npm init @eslint/config@latest`.
#'
#' CLI entry point:
#' `./tools/finalize_package.R --help`
#'
#' @param root Repository root directory.
#' @param strict Logical scalar. If `TRUE`, fail on any release gate.
#' @param confirmed_rhub_pass Logical scalar. In strict mode, confirms that the
#'   external release checks have been run and passed.
#' @param confirmed_visual_review Logical scalar. In strict mode, confirms that
#'   the final manual visual review has passed.
#' @param verbose Logical scalar. If `TRUE`, emits progress messages.
#' @param runner Function used to execute child commands. Primarily intended for
#'   tool tests.
#' @param steps Optional named list of step definitions. Primarily intended for
#'   tool tests.
#'
#' @return A list describing the finalize run, including any warning steps and
#'   the written handoff artifacts.
#'
#' @examples
#' \dontrun{
#' finalize_package()
#' finalize_package(
#'   strict = TRUE,
#'   confirmed_rhub_pass = TRUE,
#'   confirmed_visual_review = TRUE
#' )
#' }
finalize_package <- function(root = ".",
                             strict = FALSE,
                             confirmed_rhub_pass = FALSE,
                             confirmed_visual_review = FALSE,
                             verbose = interactive(),
                             runner = .run_process,
                             steps = NULL) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  if (isTRUE(strict)) {
    .assert_strict_start_state(root)
  }

  ui <- .cli_ui_new()
  ui$quiet <- !isTRUE(verbose)
  ui$plain_step_status_col <- 56L

  context <- list(
    root = root,
    strict = strict,
    confirmed_rhub_pass = confirmed_rhub_pass,
    confirmed_visual_review = confirmed_visual_review,
    runner = runner
  )

  if (is.null(steps)) {
    steps <- .finalize_steps(runner = runner)
  }

  results <- list()
  warnings <- list()

  for (name in names(steps)) {
    executed <- .execute_finalize_step(name, steps[[name]], context, ui)
    results[[name]] <- executed$result

    if (isTRUE(executed$warning)) {
      warnings[[name]] <- executed$result$details
    }
  }

  tarball_path <- results$build$data$tarball_path %||% NULL
  handoff <- .build_finalize_handoff(
    root = root,
    strict = strict,
    warnings = warnings,
    tarball_path = tarball_path,
    runner = runner
  )

  written <- list(
    handoff = .write_finalize_handoff(root, handoff),
    summary = .write_finalize_summary(root, handoff)
  )

  result <- list(
    root = root,
    strict = strict,
    warnings = warnings,
    steps = results,
    handoff = handoff,
    written = written
  )

  if (isTRUE(verbose)) {
    message(
      "Finalize complete: status=",
      handoff$status,
      ", handoff=",
      written$handoff,
      ", summary=",
      written$summary
    )
  }

  result
}

# Run the finalize stage from the command line.
run_finalize_package <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_finalize_package_args(args)

  if (isTRUE(options$help)) {
    .print_finalize_package_help()
    return(invisible(NULL))
  }

  .cli_run_main(function() {
    invisible(
      finalize_package(
        root = options$root,
        strict = options$strict,
        confirmed_rhub_pass = options$confirmed_rhub_pass,
        confirmed_visual_review = options$confirmed_visual_review,
        verbose = options$verbose
      )
    )
  })
}

if (sys.nframe() == 0L) {
  run_finalize_package()
}
# nolint end

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

.bootstrap_build_site_helpers <- function() {
  base_dirs <- .finalize_tool_base_dirs
  candidates <- c(
    unlist(lapply(base_dirs, function(dir) file.path(dir, "build_site.R"))),
    unlist(
      lapply(base_dirs, function(dir) file.path(dir, "tools", "build_site.R"))
    ),
    unlist(
      lapply(base_dirs, function(dir) file.path(dir, "..", "build_site.R"))
    ),
    file.path("tools", "build_site.R"),
    "build_site.R"
  )
  existing <- unique(candidates[file.exists(candidates)])

  if (length(existing) > 0L) {
    build_site_env <- new.env(parent = globalenv())
    source(existing[[1]], local = build_site_env)

    if (
      !exists(".build_site_stage", envir = build_site_env, inherits = FALSE)
    ) {
      stop(
        "The `build_site` tool did not provide `.build_site_stage()`.",
        call. = FALSE
      )
    }

    assign(
      ".build_site_stage",
      get(".build_site_stage", envir = build_site_env, inherits = FALSE),
      envir = parent.frame()
    )
  }
}

.bootstrap_cli_ui()
.bootstrap_integrity_helpers()
.bootstrap_build_site_helpers()
rm(
  .bootstrap_cli_ui,
  .bootstrap_integrity_helpers,
  .bootstrap_build_site_helpers
)

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

# Return the configured pkgdown site URL from _pkgdown.yml when present.
.pkgdown_site_url <- function(root) {
  value <- .pkgdown_top_level_scalar(root, "url")

  if (is.na(value)) {
    return(NA_character_)
  }

  sub("/+$", "", value)
}

# Return the configured pkgdown destination directory.
.pkgdown_destination_dir <- function(root) {
  destination <- .pkgdown_top_level_scalar(root, "destination")

  if (is.na(destination) || !nzchar(destination)) {
    destination <- "website"
  }

  file.path(root, destination)
}

# Format one urlchecker-style problem data frame as detail lines.
.format_url_problems <- function(problems) {
  if (nrow(problems) == 0L) {
    return(character())
  }

  vapply(
    seq_len(nrow(problems)),
    function(i) {
      from <- problems$From[[i]]
      if (length(from) == 0L || !any(nzchar(from))) {
        from <- "<unknown source>"
      }

      paste(
        paste(from, collapse = "; "),
        paste0(problems$Status[[i]], ":"),
        problems$Message[[i]],
        problems$URL[[i]]
      )
    },
    character(1)
  )
}

# Return whether one URL belongs to the configured package website.
.is_pkgdown_site_url <- function(url, site_url) {
  if (is.na(site_url) || !nzchar(site_url) || is.na(url) || !nzchar(url)) {
    return(FALSE)
  }

  identical(url, site_url) || startsWith(url, paste0(site_url, "/")) ||
    startsWith(url, paste0(site_url, "?")) ||
    startsWith(url, paste0(site_url, "#"))
}

# Map one package-owned website URL to candidate local site artifact paths.
.pkgdown_site_url_candidates <- function(root, url) {
  site_url <- .pkgdown_site_url(root)
  destination_dir <- .pkgdown_destination_dir(root)

  if (!.is_pkgdown_site_url(url, site_url)) {
    return(character())
  }

  path <- sub(paste0("^", site_url), "", url)
  path <- sub("[?#].*$", "", path)
  path <- sub("^/+", "", path)
  path <- utils::URLdecode(path)

  relative_candidates <- if (!nzchar(path)) {
    "index.html"
  } else if (grepl("/$", path)) {
    file.path(path, "index.html")
  } else {
    ext <- tools::file_ext(path)
    unique(c(
      path,
      if (!nzchar(ext)) paste0(path, ".html"),
      file.path(path, "index.html")
    ))
  }

  normalizePath(
    file.path(destination_dir, relative_candidates),
    winslash = "/",
    mustWork = FALSE
  )
}

# Validate package-owned website URLs against the built local site artifact.
.audit_pkgdown_site_urls <- function(root, problems) {
  site_url <- .pkgdown_site_url(root)
  destination_dir <- .pkgdown_destination_dir(root)

  if (nrow(problems) == 0L || is.na(site_url) || !nzchar(site_url)) {
    return(list(
      external = problems,
      local = data.frame(stringsAsFactors = FALSE),
      details = character()
    ))
  }

  keep_external <- logical(nrow(problems))
  local_records <- vector("list", nrow(problems))
  local_details <- character()
  local_count <- 0L

  for (i in seq_len(nrow(problems))) {
    url <- problems$URL[[i]]
    if (!.is_pkgdown_site_url(url, site_url)) {
      keep_external[[i]] <- TRUE
      next
    }

    candidates <- .pkgdown_site_url_candidates(root, url)
    existing <- candidates[file.exists(candidates) | dir.exists(candidates)]

    if (length(existing) > 0L) {
      next
    }

    local_count <- local_count + 1L
    from <- problems$From[[i]]
    if (length(from) == 0L || !any(nzchar(from))) {
      from <- "<unknown source>"
    }

    relative_candidates <- sub(
      paste0(
        "^",
        normalizePath(destination_dir, winslash = "/", mustWork = FALSE),
        "/?"
      ),
      "",
      candidates
    )

    local_records[[local_count]] <- data.frame(
      URL = url,
      From = I(list(from)),
      Expected = I(list(relative_candidates)),
      stringsAsFactors = FALSE
    )
    local_details[[local_count]] <- paste(
      paste(from, collapse = "; "),
      "missing from built website artifact:",
      url,
      "expected one of",
      paste(sprintf("`%s`", relative_candidates), collapse = ", ")
    )
  }

  local_records <- local_records[seq_len(local_count)]
  local_problems <- if (length(local_records) == 0L) {
    data.frame(stringsAsFactors = FALSE)
  } else {
    do.call(rbind, local_records)
  }

  list(
    external = problems[keep_external, , drop = FALSE],
    local = local_problems,
    details = local_details
  )
}

# Run a package-source URL audit without mutating any package files.
.audit_package_urls <- function(root, checker = NULL) {
  if (is.null(checker)) {
    if (!requireNamespace("urlchecker", quietly = TRUE)) {
      stop(
        paste(
          "The `urlchecker` package is required for finalize package URL",
          "audits."
        ),
        call. = FALSE
      )
    }

    checker <- function(path) {
      urlchecker::url_check(path = path, progress = FALSE)
    }
  }

  result <- checker(root)
  problems <- as.data.frame(result, stringsAsFactors = FALSE)

  if (nrow(problems) == 0L) {
    return(list(ok = TRUE))
  }

  split <- .audit_pkgdown_site_urls(root, problems)
  details <- c(
    .format_url_problems(split$external),
    split$details
  )

  if (length(details) == 0L) {
    return(list(
      ok = TRUE,
      data = list(
        url_problems = split$external,
        local_site_url_problems = split$local
      )
    ))
  }

  list(
    ok = FALSE,
    details = details,
    data = list(
      url_problems = split$external,
      local_site_url_problems = split$local
    )
  )
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

# Return trimmed file lines when one file exists, otherwise an empty vector.
.read_trimmed_lines <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }

  trimws(readLines(path, warn = FALSE, encoding = "UTF-8"))
}

# Return the bundled upstream Web Awesome version from the dev default file.
.upstream_version <- function(root) {
  path <- file.path(root, "dev", "webawesome-version.txt")
  lines <- .read_trimmed_lines(path)
  lines <- lines[nzchar(lines)]

  if (length(lines) == 0L) {
    return(NA_character_)
  }

  lines[[1]]
}

# Return the shipped bundled Web Awesome version from inst/.
.shipped_upstream_version <- function(root) {
  path <- file.path(root, "inst", "SHINY.WEBAWESOME_VERSION")
  lines <- .read_trimmed_lines(path)
  lines <- lines[nzchar(lines)]

  if (length(lines) == 0L) {
    return(NA_character_)
  }

  lines[[1]]
}

# Return the latest NEWS heading version when present.
.news_version <- function(root) {
  path <- file.path(root, "NEWS.md")
  lines <- .read_trimmed_lines(path)

  if (length(lines) == 0L) {
    return(NA_character_)
  }

  patterns <- c(
    "^#\\s+Version\\s+([0-9][0-9A-Za-z.\\-]*)\\s*$",
    "^#\\s+[A-Za-z][A-Za-z0-9._\\-]*\\s+([0-9][0-9A-Za-z.\\-]*)\\s*$"
  )

  for (pattern in patterns) {
    headings <- regmatches(lines, regexec(pattern, lines, perl = TRUE))
    versions <- vapply(
      headings,
      function(match) {
        if (length(match) >= 2L) {
          match[[2]]
        } else {
          NA_character_
        }
      },
      character(1)
    )
    versions <- versions[!is.na(versions) & nzchar(versions)]

    if (length(versions) > 0L) {
      return(versions[[1]])
    }
  }

  NA_character_
}

# Return the first captured version for one pkgdown line pattern.
.pkgdown_line_version <- function(lines, pattern) {
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

# Return explicit mirrored version records embedded in _pkgdown.yml.
.pkgdown_versions <- function(root) {
  path <- file.path(root, "_pkgdown.yml")
  lines <- .read_trimmed_lines(path)

  if (length(lines) == 0L) {
    return(list(
      package_description = NA_character_,
      package_subtitle = NA_character_,
      upstream_description = NA_character_,
      upstream_subtitle = NA_character_,
      upstream_navbar = NA_character_
    ))
  }

  list(
    package_description = .pkgdown_line_version(
      lines,
      "Package version\\s+([0-9][0-9A-Za-z.\\-]*[0-9A-Za-z])"
    ),
    package_subtitle = .pkgdown_line_version(
      lines,
      "Package\\s+([0-9][0-9A-Za-z.\\-]*[0-9A-Za-z])\\s+with bundled"
    ),
    upstream_description = .pkgdown_line_version(
      lines,
      "Web Awesome version\\s+([0-9][0-9A-Za-z.\\-]*[0-9A-Za-z])"
    ),
    upstream_subtitle = .pkgdown_line_version(
      lines,
      "Web Awesome\\s+([0-9][0-9A-Za-z.\\-]*[0-9A-Za-z])"
    ),
    upstream_navbar = .pkgdown_line_version(
      lines,
      "^text:\\s*Web Awesome\\s+([0-9][0-9A-Za-z.\\-]*[0-9A-Za-z])\\s*$"
    )
  )
}

# Check consistency of handwritten release/version metadata.
.check_version_consistency <- function(root) {
  package_version <- .package_version(root)
  news_version <- .news_version(root)
  upstream_version <- .upstream_version(root)
  shipped_upstream_version <- .shipped_upstream_version(root)
  pkgdown_versions <- .pkgdown_versions(root)

  details <- character()

  if (is.na(news_version)) {
    details <- c(
      details,
      "Could not determine the latest package version heading from `NEWS.md`."
    )
  } else if (!identical(news_version, package_version)) {
    details <- c(
      details,
      paste(
        "`NEWS.md` latest heading version",
        paste0("(`", news_version, "`)"),
        "does not match DESCRIPTION version",
        paste0("(`", package_version, "`).")
      )
    )
  }

  pkgdown_package_fields <- c(
    "home.description" = pkgdown_versions$package_description,
    "home.strip.subtitle" = pkgdown_versions$package_subtitle
  )

  for (field in names(pkgdown_package_fields)) {
    value <- pkgdown_package_fields[[field]]

    if (is.na(value)) {
      details <- c(
        details,
        paste(
          "Could not determine the package version text from `_pkgdown.yml`",
          paste0("field `", field, "`."),
          sep = " "
        )
      )
      next
    }

    if (!identical(value, package_version)) {
      details <- c(
        details,
        paste(
          "`_pkgdown.yml`",
          paste0("field `", field, "` package version"),
          paste0("(`", value, "`)"),
          "does not match DESCRIPTION version",
          paste0("(`", package_version, "`).")
        )
      )
    }
  }

  if (is.na(upstream_version)) {
    details <- c(
      details,
      paste(
        "Could not determine the bundled upstream version from",
        "`dev/webawesome-version.txt`."
      )
    )
  }

  if (is.na(shipped_upstream_version)) {
    details <- c(
      details,
      paste(
        "Could not determine the shipped bundled upstream version from",
        "`inst/SHINY.WEBAWESOME_VERSION`."
      )
    )
  } else if (
    !is.na(upstream_version) &&
      !identical(shipped_upstream_version, upstream_version)
  ) {
    details <- c(
      details,
      paste(
        "`inst/SHINY.WEBAWESOME_VERSION`",
        paste0("(`", shipped_upstream_version, "`)"),
        "does not match `dev/webawesome-version.txt`",
        paste0("(`", upstream_version, "`).")
      )
    )
  }

  pkgdown_upstream_fields <- c(
    "home.description" = pkgdown_versions$upstream_description,
    "home.strip.subtitle" = pkgdown_versions$upstream_subtitle,
    "navbar.components.upstream.text" = pkgdown_versions$upstream_navbar
  )

  for (field in names(pkgdown_upstream_fields)) {
    value <- pkgdown_upstream_fields[[field]]

    if (is.na(value)) {
      details <- c(
        details,
        paste(
          paste(
            "Could not determine the Web Awesome version text from",
            "`_pkgdown.yml`"
          ),
          paste0("field `", field, "`."),
          sep = " "
        )
      )
      next
    }

    if (!is.na(upstream_version) && !identical(value, upstream_version)) {
      details <- c(
        details,
        paste(
          "`_pkgdown.yml`",
          paste0("field `", field, "` Web Awesome version"),
          paste0("(`", value, "`)"),
          "does not match `dev/webawesome-version.txt`",
          paste0("(`", upstream_version, "`).")
        )
      )
    }
  }

  list(ok = length(details) == 0L, details = details)
}

# Return the status label for one finalize run.
.finalize_status <- function(warnings) {
  if (length(warnings) == 0L) {
    "pass"
  } else {
    "warn"
  }
}

# Return one advisory package-coverage record.
.package_coverage_record <- function(available = FALSE,
                                     percent = NULL,
                                     details = character()) {
  list(
    available = isTRUE(available),
    percent = if (is.null(percent)) NULL else round(as.numeric(percent), 3L),
    details = details
  )
}

# Return one formatted package-coverage label for summaries.
.package_coverage_label <- function(record) {
  if (!isTRUE(record$available) || is.null(record$percent)) {
    return("Unavailable")
  }

  paste0(format(record$percent, trim = TRUE, nsmall = 1L), "%")
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
  coverage <- handoff$coverage$package %||% .package_coverage_record()

  c(
    "# Finalize Summary",
    "",
    "Generated by tools/finalize_package.R. Do not edit by hand.",
    paste0("Generated at: ", handoff$generated_at),
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
    paste0(
      "- Advisory package test coverage: `",
      .package_coverage_label(coverage),
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

# Run the website stage with structured warning semantics.
.run_site_step <- function(context,
                           stage_runner = .build_site_stage) {
  if (!exists(".build_site_stage", mode = "function")) {
    stop(
      "The `build_site` stage helpers are required for finalize site builds.",
      call. = FALSE
    )
  }

  stage <- stage_runner(
    root = context$root,
    install = TRUE,
    live_examples = FALSE,
    preview = FALSE,
    strict_link_audit = isTRUE(context$strict),
    verbose = FALSE
  )

  if (isTRUE(stage$ok) && !isTRUE(stage$warning)) {
    return(list(
      ok = TRUE,
      details = stage$details %||% character(),
      data = list(
        destination = .strip_root_prefix(stage$destination, context$root),
        audit = stage$audit %||% NULL
      )
    ))
  }

  list(
    ok = FALSE,
    details = stage$details %||% "Website build failed.",
    data = list(
      destination = .strip_root_prefix(stage$destination, context$root),
      audit = stage$audit %||% NULL
    )
  )
}

# Compute advisory package test coverage for finalize reporting.
.run_package_coverage_step <- function(root, runner = .run_process) {
  expr <- paste(
    "if (!requireNamespace('covr', quietly = TRUE))",
    paste(
      "stop('The `covr` package is required for finalize coverage",
      "reporting.', call. = FALSE);"
    ),
    paste(
      "value <- covr::percent_coverage(",
      "  covr::package_coverage(path = '.', quiet = TRUE)",
      ");"
    ),
    "cat(format(round(as.numeric(value), 3), trim = TRUE, nsmall = 3))"
  )
  cmd <- .rscript_command(expr)
  step <- .run_command_step(
    command = cmd$command,
    args = cmd$args,
    root = root,
    runner = runner
  )

  if (!isTRUE(step$ok)) {
    message <- paste(
      "Package test coverage unavailable.",
      paste(step$details %||% character(), collapse = " ")
    )
    step$ok <- TRUE
    step$details <- message
    step$data <- list(
      package_coverage = .package_coverage_record(
        available = FALSE,
        details = message
      )
    )
    return(step)
  }

  output <- trimws(paste(step$result$stdout %||% character(), collapse = "\n"))
  percent <- suppressWarnings(as.numeric(output))

  if (is.na(percent)) {
    message <- "Package test coverage unavailable."
    step$details <- message
    step$data <- list(
      package_coverage = .package_coverage_record(
        available = FALSE,
        details = message
      )
    )
    return(step)
  }

  record <- .package_coverage_record(
    available = TRUE,
    percent = percent,
    details = paste0(
      "Package test coverage: ",
      format(round(percent, 3), trim = TRUE, nsmall = 1L),
      "%"
    )
  )
  step$details <- record$details
  step$data <- list(package_coverage = record)
  step
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
          paste(
            "    results[[path]] <- if (identical(path, 'vignettes'))",
            "lintr::lint_dir(",
            "      path,",
            "      linters = lintr::linters_with_defaults(",
            "        object_usage_linter = NULL",
            "      )",
            "    ) else lintr::lint_dir(path);"
          ),
          "  }",
          "};",
          "all_results <- unlist(results, recursive = FALSE);",
          "if (length(all_results) > 0L) {",
          "  print(all_results);",
          "  message('Lint issues detected.');",
          "  quit(save = 'no', status = 1L)",
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
    coverage = list(
      label = "Computing package test coverage",
      fatal = FALSE,
      run = function(context) {
        .run_package_coverage_step(
          root = context$root,
          runner = context$runner
        )
      }
    ),
    site = list(
      label = "Building website",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) {
        .run_site_step(context)
      }
    ),
    url_audit = list(
      label = "Auditing package URLs",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) .audit_package_urls(context$root)
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
    version_consistency = list(
      label = "Checking version consistency",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) .check_version_consistency(context$root)
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
                "  (consider running checks also on WinBuilder via",
                "`devtools::check_win_release()` - this has additional",
                "CRAN-type URL checks)"
              ),
              paste(
                "- Run `./tools/check_interactive.R`, review the printed local",
                "URL in a browser, and complete the manual visual review",
                "separately."
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
    (identical(name, "confirmations") || identical(name, "coverage")) &&
      !isTRUE(context$strict) &&
      length(result$details %||% character()) > 0L
  ) {
    .cli_step_finish(ui, status = "Done")
    .emit_warning_details(ui, result$details)
  } else if (
    identical(name, "coverage") &&
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
                                    package_coverage,
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
    coverage = list(
      package = package_coverage %||% .package_coverage_record()
    ),
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
#' documentation, local website auditing, package URL auditing, tarball
#' generation, and finalize handoff recording.
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
#' @param runner Function used to execute child commands. This is primarily a
#'   test seam for tool tests, which can inject a fake process runner to
#'   simulate `git`, `Rscript`, and other child-command results without running
#'   the full finalize workflow.
#' @param steps Optional named list of step definitions. This is primarily a
#'   test seam for tool tests, which can inject a small synthetic finalize step
#'   set to exercise warning accumulation, strict-mode failure handling, and
#'   handoff writing without invoking the full toolchain.
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
  package_coverage <- results$coverage$data$package_coverage %||%
    .package_coverage_record()
  handoff <- .build_finalize_handoff(
    root = root,
    strict = strict,
    warnings = warnings,
    package_coverage = package_coverage,
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

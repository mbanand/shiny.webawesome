#!/usr/bin/env Rscript

# Netlify deployment wrapper for the shiny.webawesome website artifact.
#
# This file is both sourceable by tests and directly executable as a top-level
# tool entry point. It provides a narrow repository-owned wrapper around the
# Netlify CLI so publish-stage deployment checks stay explicit and testable.

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

.deploy_tool_base_dirs <- .script_base_dirs()

# Source the shared CLI helpers relative to this script when possible.
.bootstrap_cli_ui <- function() {
  base_dirs <- .deploy_tool_base_dirs
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

# Return the CLI usage string for the Netlify deploy wrapper.
.deploy_site_usage <- function() {
  paste(
    "Usage: ./tools/deploy_site_netlify.R",
    "[--root <path>] [--dry-run] [--quiet] [--help]"
  )
}

# Return the short CLI description for the Netlify deploy wrapper.
.deploy_site_description <- function() {
  paste(
    "Verify or deploy the finalize-built website artifact using the",
    "Netlify CLI."
  )
}

# List supported CLI options for the Netlify deploy wrapper.
.deploy_site_option_lines <- function() {
  c(
    paste(
      "--root <path>   Repository root.",
      "Defaults to the current directory."
    ),
    "--dry-run       Verify Netlify readiness without deploying.",
    "--quiet         Suppress stage-level progress messages.",
    "--help, -h      Print this help text."
  )
}

# Print the CLI help text for the Netlify deploy wrapper.
.print_deploy_site_help <- function() {
  writeLines(
    c(
      .deploy_site_description(),
      "",
      .deploy_site_usage(),
      "",
      "Options:",
      .deploy_site_option_lines()
    )
  )
}

# Define default CLI option values for the Netlify deploy wrapper.
.deploy_site_defaults <- function() {
  list(
    root = ".",
    dry_run = FALSE,
    verbose = TRUE,
    help = FALSE
  )
}

# Parse command-line arguments for the Netlify deploy wrapper.
.parse_deploy_site_args <- function(args) {
  options <- .deploy_site_defaults()
  skip_next <- FALSE

  for (i in seq_along(args)) {
    if (skip_next) {
      skip_next <- FALSE
      next
    }

    arg <- args[[i]]

    if (arg == "--dry-run") {
      options$dry_run <- TRUE
      next
    }

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
      paste0("Unknown argument: ", arg, "\n", .deploy_site_usage()),
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

# Return the repository-local website output directory.
.website_dir <- function(root) {
  file.path(root, "website")
}

# Return one Netlify CLI command descriptor.
.netlify_cli_command <- function(args) {
  netlify <- Sys.which("netlify")
  if (nzchar(netlify)) {
    return(list(command = netlify, args = args))
  }

  npx <- Sys.which("npx")
  if (nzchar(npx)) {
    return(list(
      command = npx,
      args = c("--no-install", "netlify-cli", args)
    ))
  }

  stop(
    paste(
      "Could not find `netlify` or `npx` on PATH for Netlify deployment."
    ),
    call. = FALSE
  )
}

# Run one child command using processx.
.run_process <- function(command,
                         args = character(),
                         wd = ".",
                         env = character()) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop(
      "The `processx` package is required to run Netlify deployment commands.",
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

# Return the configured Netlify auth token from the environment.
.netlify_auth_token <- function() {
  token <- trimws(Sys.getenv("NETLIFY_AUTH_TOKEN", unset = ""))
  if (!nzchar(token)) {
    return(NULL)
  }

  token
}

# Return the configured Netlify site id from env or a linked local config.
.netlify_site_id <- function(root) {
  env_site_id <- trimws(Sys.getenv("NETLIFY_SITE_ID", unset = ""))
  if (nzchar(env_site_id)) {
    return(env_site_id)
  }

  state_path <- file.path(root, ".netlify", "state.json")
  if (!file.exists(state_path)) {
    return(NULL)
  }

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop(
      "The `jsonlite` package is required to read `.netlify/state.json`.",
      call. = FALSE
    )
  }

  state <- jsonlite::fromJSON(state_path, simplifyVector = TRUE)
  site_id <- state$siteId %||% NULL

  if (is.null(site_id) || !nzchar(site_id)) {
    return(NULL)
  }

  site_id
}

# Return one compact Netlify deployment message.
.netlify_deploy_message <- function(root) {
  package_version <- read.dcf(file.path(root, "DESCRIPTION"))[[1, "Version"]]
  paste("shiny.webawesome website deploy for", package_version)
}

# Return the environment variables passed to Netlify CLI.
.netlify_child_env <- function(token) {
  c(NETLIFY_AUTH_TOKEN = token)
}

# Verify Netlify readiness using the authenticated sites list.
.verify_netlify_site <- function(root,
                                 site_id,
                                 token,
                                 runner = .run_process) {
  descriptor <- .netlify_cli_command(c("sites:list", "--json"))
  result <- runner(
    command = descriptor$command,
    args = descriptor$args,
    wd = root,
    env = .netlify_child_env(token)
  )

  if (!identical(result$status, 0L)) {
    stop(
      paste(.process_output_lines(result), collapse = "\n"),
      call. = FALSE
    )
  }

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop(
      "The `jsonlite` package is required to parse Netlify CLI JSON output.",
      call. = FALSE
    )
  }

  payload <- trimws(paste(result$stdout, collapse = "\n"))
  sites <- jsonlite::fromJSON(payload, simplifyVector = TRUE)

  current_ids <- character()
  if (is.data.frame(sites) && "id" %in% names(sites)) {
    current_ids <- as.character(sites$id)
  } else if (is.list(sites) && !is.null(sites$id)) {
    current_ids <- as.character(sites$id)
  }

  if (!(site_id %in% current_ids)) {
    stop(
      paste0(
        "Configured Netlify site id `",
        site_id,
        "` was not found in the authenticated account."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

# Deploy the built website directory to Netlify production.
.deploy_netlify_site <- function(root,
                                 site_id,
                                 token,
                                 runner = .run_process) {
  descriptor <- .netlify_cli_command(c(
    "deploy",
    "--json",
    "--prod",
    "--no-build",
    "--dir",
    "website",
    "--site",
    site_id,
    "--message",
    .netlify_deploy_message(root)
  ))

  result <- runner(
    command = descriptor$command,
    args = descriptor$args,
    wd = root,
    env = .netlify_child_env(token)
  )

  if (!identical(result$status, 0L)) {
    stop(
      paste(.process_output_lines(result), collapse = "\n"),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

#' Verify or deploy the finalize-built website using Netlify
#'
#' Provides a narrow repository-owned wrapper around the Netlify CLI for the
#' built `website/` artifact. In dry-run mode, it verifies local prerequisites,
#' validates Netlify authentication, and confirms that the configured site id is
#' available to the authenticated account without deploying.
#'
#' CLI entry point:
#' `./tools/deploy_site_netlify.R --help`
#'
#' @param root Repository root directory.
#' @param dry_run Logical scalar. If `TRUE`, verifies Netlify readiness without
#'   performing a deployment.
#' @param verbose Logical scalar. If `TRUE`, emits stage-level progress
#'   messages.
#' @param runner Function used to execute child commands. This is primarily a
#'   test seam for tool tests.
#'
#' @return A list describing the verified deploy inputs and whether a deployment
#'   was executed.
#'
#' @examples
#' \dontrun{
#' deploy_site_netlify(dry_run = TRUE)
#' deploy_site_netlify()
#' }
deploy_site_netlify <- function(root = ".",
                                dry_run = FALSE,
                                verbose = interactive(),
                                runner = .run_process) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  website_dir <- .website_dir(root)
  if (!dir.exists(website_dir)) {
    stop("`website/` does not exist.", call. = FALSE)
  }

  token <- .netlify_auth_token()
  if (is.null(token)) {
    stop(
      "`NETLIFY_AUTH_TOKEN` is required for Netlify deployment.",
      call. = FALSE
    )
  }

  site_id <- .netlify_site_id(root)
  if (is.null(site_id)) {
    stop(
      paste(
        "Netlify site id is required. Set `NETLIFY_SITE_ID` or create a linked",
        "`.netlify/state.json`."
      ),
      call. = FALSE
    )
  }

  ui <- .cli_ui_new()
  if (!isTRUE(verbose)) {
    ui$quiet <- TRUE
  }

  .cli_step_start(ui, "Verifying Netlify deployment readiness")
  tryCatch(
    .verify_netlify_site(root, site_id, token, runner = runner),
    error = function(condition) {
      .cli_step_fail(ui, details = conditionMessage(condition))
      stop(conditionMessage(condition), call. = FALSE)
    }
  )
  .cli_step_finish(ui, status = "Done")

  deployed <- FALSE
  if (!isTRUE(dry_run)) {
    .cli_step_start(ui, "Deploying website to Netlify")
    tryCatch(
      .deploy_netlify_site(root, site_id, token, runner = runner),
      error = function(condition) {
        .cli_step_fail(ui, details = conditionMessage(condition))
        stop(conditionMessage(condition), call. = FALSE)
      }
    )
    .cli_step_finish(ui, status = "Done")
    deployed <- TRUE
  }

  result <- list(
    root = root,
    dry_run = dry_run,
    website_dir = website_dir,
    site_id = site_id,
    deployed = deployed
  )

  if (!isTRUE(ui$quiet)) {
    message(
      "Netlify deploy wrapper complete: dry-run=",
      if (isTRUE(dry_run)) "yes" else "no",
      ", deployed=",
      if (isTRUE(deployed)) "yes" else "no"
    )
  }

  invisible(result)
}

# Run the Netlify deploy wrapper from the command line.
run_deploy_site_netlify <- function(args = commandArgs(trailingOnly = TRUE)) {
  options <- .parse_deploy_site_args(args)

  if (isTRUE(options$help)) {
    .print_deploy_site_help()
    return(invisible(NULL))
  }

  .cli_run_main(function() {
    invisible(
      deploy_site_netlify(
        root = options$root,
        dry_run = options$dry_run,
        verbose = options$verbose
      )
    )
  })
}

if (sys.nframe() == 0L) {
  run_deploy_site_netlify()
}
# nolint end

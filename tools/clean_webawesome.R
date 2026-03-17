# Clean stage implementation for the shiny.webawesome build pipeline.
#
# This file is sourced by stage runners under tools/runners/ and may also be
# sourced directly by tests. It is not package runtime code.

clean_target_sets <- function() {
  list(
    clean = list(
      remove = c(
        "R/generated",
        "R/generated_updates",
        "inst/bindings",
        "inst/www/webawesome",
        "manifests",
        "report"
      )
    ),
    distclean = list(
      remove = c(
        "R/generated",
        "R/generated_updates",
        "inst/bindings",
        "inst/www/webawesome",
        "manifests",
        "report",
        "vendor/webawesome",
        "inst/extdata/webawesome"
      )
    )
  )
}

is_repo_root <- function(root) {
  required_paths <- c("DESCRIPTION", "docs", "tools")
  all(file.exists(file.path(root, required_paths)))
}

remove_path <- function(path, dry_run = FALSE) {
  if (!dry_run) {
    unlink(path, recursive = TRUE, force = TRUE)
  }

  path
}

clean_webawesome <- function(level = c("clean", "distclean"),
                             dry_run = FALSE,
                             verbose = interactive(),
                             root = ".") {
  level <- match.arg(level)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  target_set <- clean_target_sets()[[level]]

  remove_targets <- file.path(root, target_set$remove)
  existing_remove <- remove_targets[file.exists(remove_targets)]
  missing <- remove_targets[!file.exists(remove_targets)]

  removed_paths <- character()
  if (length(existing_remove) > 0L) {
    for (path in sort(existing_remove)) {
      removed_paths <- c(removed_paths, remove_path(path, dry_run = dry_run))
    }
  }

  result <- list(
    level = level,
    root = root,
    requested_remove = sort(target_set$remove),
    existing_remove = sort(sub(paste0("^", root, "/?"), "", existing_remove)),
    removed = sort(sub(paste0("^", root, "/?"), "", removed_paths)),
    missing = sort(sub(paste0("^", root, "/?"), "", missing)),
    dry_run = dry_run
  )

  if (isTRUE(verbose)) {
    action <- if (dry_run) "Would remove" else "Removed"

    if (length(result$removed) > 0L) {
      message(action, ": ", paste(result$removed, collapse = ", "))
    }

    if (length(result$missing) > 0L) {
      message("Already absent: ", paste(result$missing, collapse = ", "))
    }
  }

  result
}

# Clean stage implementation for the shiny.webawesome build pipeline.
#
# This file is sourced by stage runners under tools/runners/ and may also be
# sourced directly by tests. It is not package runtime code.

`_clean_target_sets` <- function() {
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

`_is_repo_root` <- function(root) {
  required_paths <- c("DESCRIPTION", "docs", "tools")
  all(file.exists(file.path(root, required_paths)))
}

`_remove_path` <- function(path, dry_run = FALSE) {
  if (!dry_run) {
    unlink(path, recursive = TRUE, force = TRUE)
  }

  path
}

`_strip_root_prefix` <- function(paths, root) {
  sub(paste0("^", root, "/?"), "", paths)
}

`_emit_clean_summary` <- function(result) {
  action <- if (result$dry_run) "Would remove" else "Removed"

  if (length(result$removed) > 0L) {
    message(action, ": ", paste(result$removed, collapse = ", "))
  }

  if (length(result$missing) > 0L) {
    message("Already absent: ", paste(result$missing, collapse = ", "))
  }
}

#' Remove generated build artifacts from the repository
#'
#' Executes the `clean` stage of the build pipeline. The default `clean` level
#' removes generated package artifacts and the pruned runtime bundle.
#' `distclean` additionally removes fetched upstream inputs and copied metadata.
#'
#' @param level Cleanup level. Must be one of `"clean"` or `"distclean"`.
#' @param dry_run Logical scalar. If `TRUE`, reports the paths that would be
#'   removed without deleting them.
#' @param verbose Logical scalar. If `TRUE`, emits a short summary of removed
#'   and already-absent paths.
#' @param root Repository root directory.
#'
#' @return A list describing the cleanup operation, including removed and
#'   missing paths.
#'
#' @examples
#' \dontrun{
#' clean_webawesome()
#' clean_webawesome(level = "distclean", dry_run = TRUE)
#' }
clean_webawesome <- function(level = c("clean", "distclean"),
                             dry_run = FALSE,
                             verbose = interactive(),
                             root = ".") {
  level <- match.arg(level)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)

  if (!`_is_repo_root`(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  target_set <- `_clean_target_sets`()[[level]]

  remove_targets <- file.path(root, target_set$remove)
  existing_remove <- remove_targets[file.exists(remove_targets)]
  missing <- remove_targets[!file.exists(remove_targets)]

  removed_paths <- character()
  if (length(existing_remove) > 0L) {
    for (path in sort(existing_remove)) {
      removed_paths <- c(
        removed_paths,
        `_remove_path`(path, dry_run = dry_run)
      )
    }
  }

  result <- list(
    level = level,
    root = root,
    requested_remove = sort(target_set$remove),
    existing_remove = sort(`_strip_root_prefix`(existing_remove, root)),
    removed = sort(`_strip_root_prefix`(removed_paths, root)),
    missing = sort(`_strip_root_prefix`(missing, root)),
    dry_run = dry_run
  )

  if (isTRUE(verbose)) {
    `_emit_clean_summary`(result)
  }

  result
}

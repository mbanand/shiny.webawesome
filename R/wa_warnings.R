# nolint start: object_usage_linter

# Return whether one known warning key is currently enabled.
.wa_warning_enabled <- function(key) {
  isTRUE(.wa_warning_registry()[[key]])
}

# Return the number of descendant wa-tree-item tags without DOM ids.
.wa_count_tree_missing_ids <- function(x) {
  if (is.null(x)) {
    return(0L)
  }

  if (inherits(x, "shiny.tag")) {
    count <- 0L

    if (identical(x$name, "wa-tree-item")) {
      id <- x$attribs$id
      has_id <- is.character(id) && length(id) == 1L && nzchar(id)

      if (!has_id) {
        count <- 1L
      }
    }

    return(count + .wa_count_tree_missing_ids(x$children))
  }

  if (is.list(x)) {
    return(sum(vapply(x, .wa_count_tree_missing_ids, integer(1))))
  }

  0L
}

# Warn once per wa_tree() call when selected tree items may lack stable ids.
.wa_warn_missing_tree_item_ids <- function(children, input_id = NULL) {
  if (!.wa_warning_enabled("missing_tree_item_id")) {
    return(invisible(NULL))
  }

  missing_count <- .wa_count_tree_missing_ids(children)

  if (missing_count <= 0L) {
    return(invisible(NULL))
  }

  item_label <- if (missing_count == 1L) {
    "1 descendant `wa-tree-item` element"
  } else {
    sprintf("%d descendant `wa-tree-item` elements", missing_count)
  }

  input_label <- if (
    is.character(input_id) &&
      length(input_id) == 1L &&
      nzchar(input_id)
  ) {
    sprintf(" for `input_id = \"%s\"`", input_id)
  } else {
    ""
  }

  warning(
    paste0(
      "`wa_tree()` found ",
      item_label,
      " without an `id`",
      input_label,
      "; selected items without ids will be omitted from the Shiny value. ",
      "Suppress with `options(shiny.webawesome.warnings = ",
      "list(missing_tree_item_id = FALSE))`."
    ),
    call. = FALSE
  )

  invisible(NULL)
}

# nolint end

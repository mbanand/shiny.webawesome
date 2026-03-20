# Wrapper rendering helpers for the generate stage.
# nolint start: object_usage_linter,line_length_linter.

# Return the slot argument names to surface in the wrapper signature.
.wrapper_slots <- function(component) {
  slots <- component$slots %||% list()

  if (length(slots) == 0L) {
    return(list())
  }

  slots <- slots[vapply(slots, function(slot) !identical(slot$name, ""), logical(1))]

  attr_args <- vapply(
    .wrapper_attributes(component),
    `[[`,
    character(1),
    "argument_name"
  )
  reserved <- c(attr_args, "id")

  lapply(
    slots,
    function(slot) {
      arg_name <- slot$argument_name
      if (arg_name %in% reserved) {
        arg_name <- paste0(arg_name, "_slot")
      }

      slot$wrapper_argument_name <- arg_name
      slot
    }
  )
}

# Return whether a component should accept an id argument.
.wrapper_uses_id <- function(component) {
  component$tag_name %in% c("wa-checkbox", "wa-select")
}

# Return the preferred wrapper argument order for component attributes.
.wrapper_attributes <- function(component) {
  attrs <- component$attributes %||% list()

  if (length(attrs) == 0L) {
    return(list())
  }

  attrs <- attrs[vapply(
    attrs,
    function(attr) {
      !all(is.na(c(attr$type, attr$default, attr$description)))
    },
    logical(1)
  )]

  if (length(attrs) == 0L) {
    return(list())
  }

  preferred <- c("value", "checked", "disabled", "label", "hint", "name")
  attr_names <- vapply(attrs, `[[`, character(1), "name")
  rank <- match(attr_names, preferred)
  rank[is.na(rank)] <- length(preferred) + seq_len(sum(is.na(rank)))
  attrs[order(rank, attr_names)]
}

# Render one wrapper function signature.
.render_wrapper_signature <- function(component) {
  args <- c("...")

  if (.wrapper_uses_id(component)) {
    args <- c(args, "id = NULL")
  }

  attrs <- .wrapper_attributes(component)
  if (length(attrs) > 0L) {
    args <- c(
      args,
      vapply(
        attrs,
        function(attr) paste0(attr$argument_name, " = NULL"),
        character(1)
      )
    )
  }

  slots <- .wrapper_slots(component)
  if (length(slots) > 0L) {
    args <- c(
      args,
      vapply(
        slots,
        function(slot) paste0(slot$wrapper_argument_name, " = NULL"),
        character(1)
      )
    )
  }

  paste(args, collapse = ",\n  ")
}

# Render the normalized attribute list for one wrapper.
.render_wrapper_attrs <- function(component) {
  attrs <- .wrapper_attributes(component)
  lines <- character()

  if (.wrapper_uses_id(component)) {
    lines <- c(lines, "\"id\" = id")
  }

  if (length(attrs) > 0L) {
    lines <- c(
      lines,
      vapply(
        attrs,
        function(attr) {
          paste0(.r_string(attr$name), " = ", attr$argument_name)
        },
        character(1)
      )
    )
  }

  if (length(lines) == 0L) {
    return("list()")
  }

  paste0(
    "list(\n    ",
    paste(lines, collapse = ",\n    "),
    "\n  )"
  )
}

# Render the boolean attribute names for one wrapper.
.render_wrapper_booleans <- function(component) {
  attrs <- .wrapper_attributes(component)
  booleans <- attrs[vapply(attrs, `[[`, logical(1), "is_boolean")]

  if (length(booleans) == 0L) {
    return("character()")
  }

  values <- vapply(booleans, function(attr) .r_string(attr$name), character(1))
  paste0("c(", paste(values, collapse = ", "), ")")
}

# Render slot-child assembly code for one wrapper.
.render_wrapper_children <- function(component) {
  slots <- .wrapper_slots(component)
  lines <- c("children <- list(...)")

  if (length(slots) > 0L) {
    lines <- c(
      lines,
      vapply(
        slots,
        function(slot) {
          paste0(
            "children <- c(children, list(.wa_slot(",
            slot$wrapper_argument_name,
            ", ",
            .r_string(slot$name),
            ")))"
          )
        },
        character(1)
      )
    )
  }

  paste(lines, collapse = "\n  ")
}

# Render one generated wrapper file from template.
.render_wrapper_file <- function(component, template_path) {
  values <- c(
    HEADER = .generated_header(),
    FUNCTION_NAME = component$r_function_name,
    FUNCTION_TITLE = paste("Generated wrapper for", paste0("`", component$tag_name, "`")),
    TAG_NAME = .r_string(component$tag_name),
    SIGNATURE = .render_wrapper_signature(component),
    ATTRS = .render_wrapper_attrs(component),
    BOOLEAN_ATTRS = .render_wrapper_booleans(component),
    CHILDREN = .render_wrapper_children(component)
  )

  .render_template(template_path, values)
}
# nolint end

# Wrapper rendering helpers for the generate stage.
# nolint start: object_usage_linter,line_length_linter.

# Return whether one attribute belongs in the user-facing wrapper surface.
.wrapper_supports_attribute <- function(attr) {
  name <- attr$name %||% ""
  description <- attr$description %||% ""

  if (identical(name, "did-ssr")) {
    return(FALSE)
  }

  if (
    nzchar(description) &&
      grepl(
        "only needed for SSR|used for SSR purposes",
        description,
        ignore.case = TRUE
      )
  ) {
    return(FALSE)
  }

  TRUE
}

# Normalize one documentation string for generated roxygen output.
.doc_text <- function(text, fallback = "") {
  if (length(text) == 0L || all(is.na(text))) {
    text <- fallback
  }

  text <- as.character(text[[1]])
  text <- gsub("\\]\\([^)]+\\)", "]", text, perl = TRUE)
  text <- gsub("\\[([^]]+)\\]", "\\1", text, perl = TRUE)
  text <- gsub("(?i)\\btrue\\b", "TRUE", text, perl = TRUE)
  text <- gsub("(?i)\\bfalse\\b", "FALSE", text, perl = TRUE)
  trimws(gsub("[[:space:]]+", " ", text))
}

# Return one concise doc label for a wrapper attribute type.
.wrapper_attr_type_label <- function(attr) {
  type_text <- .scalar_string(attr$type, fallback = "")

  if (length(attr$enum_values %||% character()) > 0L) {
    return("Enumerated string.")
  }

  if (.is_boolean_type(type_text)) {
    return("Boolean.")
  }

  if (.is_number_type(type_text)) {
    return("Number.")
  }

  if (.is_string_type(type_text)) {
    return("String.")
  }

  ""
}

# Return one formatted doc literal for a default or allowed value.
.wrapper_doc_value <- function(value, string_like = FALSE) {
  value <- .scalar_string(value, fallback = NA_character_)

  if (is.na(value)) {
    return(value)
  }

  if (identical(value, "''")) {
    return('`""`')
  }

  if (string_like) {
    value <- sub("^'(.*)'$", "\\1", value, perl = TRUE)
    return(paste0("`", value, "`"))
  }

  if (identical(tolower(value), "true")) {
    return("`TRUE`")
  }

  if (identical(tolower(value), "false")) {
    return("`FALSE`")
  }

  paste0("`", value, "`")
}

# Return whether one attribute has a same-name live property mapping ambiguity.
.attr_has_live_prop_collision <- function(component, attr) {
  field_name <- .scalar_string(attr$field_name, fallback = NA_character_)
  attr_name <- .scalar_string(attr$name, fallback = NA_character_)

  if (is.na(field_name) || !nzchar(field_name) || identical(field_name, attr_name)) {
    return(FALSE)
  }

  property_names <- vapply(
    component$properties %||% list(),
    `[[`,
    character(1),
    "name"
  )

  attr_name %in% property_names
}

# Return whether one attribute maps to a different upstream field/property name.
.attr_has_field_mismatch <- function(attr) {
  field_name <- .scalar_string(attr$field_name, fallback = NA_character_)
  attr_name <- .scalar_string(attr$name, fallback = NA_character_)

  !is.na(field_name) &&
    nzchar(field_name) &&
    !identical(.as_snake_case(field_name), .as_snake_case(attr_name))
}

# Return one concise parameter description for a wrapper attribute.
.wrapper_attr_param_doc <- function(component, attr) {
  description <- .doc_text(attr$description)

  if (!nzchar(description)) {
    description <- "Optional Web Awesome attribute."
  }

  if (.attr_has_field_mismatch(attr)) {
    description <- paste(
      description,
      "This wrapper argument sets the HTML",
      paste0("`", attr$name, "`"),
      "attribute, which maps to the component's",
      paste0("`", attr$field_name, "`"),
      "field/property."
    )

    if (.attr_has_live_prop_collision(component, attr)) {
      description <- paste(
        sub("\\.$", "", description),
        "rather than its live",
        paste0("`", attr$name, "`"),
        "property."
      )
    }
  }

  enum_values <- attr$enum_values %||% character()
  default <- .scalar_string(attr$default, fallback = NA_character_)
  type_text <- .scalar_string(attr$type, fallback = "")
  is_string_like <- .is_string_type(type_text) || length(enum_values) > 0L

  details <- c(.wrapper_attr_type_label(attr))

  if (length(enum_values) > 0L) {
    details <- c(
      details,
      paste0(
        "Allowed values:",
        " ",
        paste(
          vapply(
            enum_values,
            .wrapper_doc_value,
            character(1),
            string_like = TRUE
          ),
          collapse = ", "
        ),
        "."
      )
    )
  }

  if (!is.na(default) && nzchar(default)) {
    details <- c(
      details,
      paste0(
        "Default: ",
        .wrapper_doc_value(default, string_like = is_string_like),
        "."
      )
    )
  }

  paste(c(details[nzchar(details)], description), collapse = " ")
}

# Return wrapped roxygen lines for one text fragment.
.roxygen_lines <- function(text, width = 72L) {
  paste0("#' ", strwrap(text, width = width))
}

# Return wrapped roxygen lines for one parameter description.
.roxygen_param_lines <- function(name, description) {
  .roxygen_lines(paste("@param", name, description))
}

# Return wrapped roxygen lines for one generated documentation section.
.roxygen_section_lines <- function(title, paragraphs) {
  paragraphs <- paragraphs[nzchar(paragraphs)]

  if (length(paragraphs) == 0L) {
    return(character())
  }

  lines <- c(paste0("#' @section ", title, ":"))

  for (paragraph in paragraphs) {
    lines <- c(lines, .roxygen_lines(paragraph), "#'")
  }

  lines
}

# Return one generated roxygen line for the wrapper identity argument.
.wrapper_id_param_doc <- function(component) {
  if (.component_has_binding(component)) {
    return(
      paste(
        "Shiny input id for the component.",
        "This is also used as the rendered DOM `id` attribute."
      )
    )
  }

  "Optional DOM id attribute for HTML, CSS, and JS targeting."
}

# Return one concise parameter description for a wrapper slot.
.wrapper_slot_param_doc <- function(slot) {
  description <- .doc_text(slot$description)

  if (!nzchar(description)) {
    return("Optional slot content.")
  }

  description
}

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
  global_attr_args <- vapply(
    .wrapper_global_attrs(component),
    `[[`,
    character(1),
    "argument_name"
  )
  reserved <- c(attr_args, global_attr_args, "id", "input_id")

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
  TRUE
}

# Return whether a component should expose input_id instead of id.
.wrapper_uses_input_id <- function(component) {
  .component_has_binding(component)
}

# Return package-defined global HTML attrs to inject into wrapper surfaces.
.wrapper_global_attrs <- function(component) {
  defined_attrs <- .wrapper_attributes(component)
  defined_names <- vapply(defined_attrs, `[[`, character(1), "name")
  defined_arg_names <- vapply(
    defined_attrs,
    `[[`,
    character(1),
    "argument_name"
  )

  globals <- list(
    list(
      name = "class",
      argument_name = "class",
      description = "Optional CSS class string."
    ),
    list(
      name = "style",
      argument_name = "style",
      description = "Optional inline CSS style string."
    )
  )

  globals[!vapply(
    globals,
    function(attr) {
      attr$name %in% defined_names ||
        attr$argument_name %in% defined_arg_names
    },
    logical(1)
  )]
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
      !all(is.na(c(attr$type, attr$default, attr$description))) &&
        .wrapper_supports_attribute(attr)
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

  if (.wrapper_uses_input_id(component)) {
    args <- c("input_id", args)
  } else if (.wrapper_uses_id(component)) {
    args <- c(args, "id = NULL")
  }

  global_attrs <- .wrapper_global_attrs(component)
  if (length(global_attrs) > 0L) {
    args <- c(
      args,
      vapply(
        global_attrs,
        function(attr) paste0(.as_r_symbol(attr$argument_name), " = NULL"),
        character(1)
      )
    )
  }

  attrs <- .wrapper_attributes(component)
  if (length(attrs) > 0L) {
    args <- c(
      args,
      vapply(
        attrs,
        function(attr) paste0(.as_r_symbol(attr$argument_name), " = NULL"),
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
        function(slot) paste0(.as_r_symbol(slot$wrapper_argument_name), " = NULL"),
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

  if (.wrapper_uses_input_id(component)) {
    lines <- c(lines, "\"id\" = input_id")
  } else if (.wrapper_uses_id(component)) {
    lines <- c(lines, "\"id\" = id")
  }

  global_attrs <- .wrapper_global_attrs(component)
  if (length(global_attrs) > 0L) {
    lines <- c(
      lines,
      vapply(
        global_attrs,
        function(attr) {
          paste0(.r_string(attr$name), " = ", .as_r_symbol(attr$argument_name))
        },
        character(1)
      )
    )
  }

  if (length(attrs) > 0L) {
    lines <- c(
      lines,
      vapply(
        attrs,
        function(attr) {
          paste0(.r_string(attr$name), " = ", .as_r_symbol(attr$argument_name))
        },
        character(1)
      )
    )
  }

  if (length(lines) == 0L) {
    return("    list()")
  }

  paste(
    "    list(",
    paste0("      ", paste(lines, collapse = ",\n      ")),
    "    )",
    sep = "\n"
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
  if (length(values) <= 2L) {
    return(paste0("c(", paste(values, collapse = ", "), ")"))
  }

  paste0(
    "c(\n      ",
    paste(values, collapse = ",\n      "),
    "\n    )"
  )
}

# Render the boolean HTML-attribute to wrapper-argument name map.
.render_wrapper_bool_arg_names <- function(component) {
  attrs <- .wrapper_attributes(component)
  booleans <- attrs[vapply(attrs, `[[`, logical(1), "is_boolean")]

  if (length(booleans) == 0L) {
    return("NULL")
  }

  values <- vapply(
    booleans,
    function(attr) {
      paste0(.r_string(attr$name), " = ", .r_string(attr$argument_name))
    },
    character(1)
  )

  if (length(values) <= 1L) {
    return(paste0("c(", paste(values, collapse = ", "), ")"))
  }

  paste0(
    "c(\n      ",
    paste(values, collapse = ",\n      "),
    "\n    )"
  )
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
          paste(
            "children <- c(",
            "  children,",
            "  list(",
            paste0(
              "    .wa_slot(",
              .as_r_symbol(slot$wrapper_argument_name),
              ", ",
              .r_string(slot$name),
              ")"
            ),
            "  )",
            ")",
            sep = "\n"
          )
        },
        character(1)
      )
    )
  }

  paste0("  ", gsub("\n", "\n  ", paste(lines, collapse = "\n"), fixed = TRUE))
}

# Return the configured wrapper warning key for one component.
.component_wrapper_warning <- function(component) {
  .scalar_string(
    component$classification$binding_wrapper_warning,
    fallback = NA_character_
  )
}

# Return any wrapper-side warning hook code for one wrapper.
.render_wrapper_warnings <- function(component) {
  warning_key <- .component_wrapper_warning(component)

  if (is.na(warning_key) || !nzchar(warning_key)) {
    return("")
  }

  if (identical(warning_key, "missing_tree_item_id")) {
    return("  .wa_warn_missing_tree_item_ids(children, input_id = input_id)")
  }

  stop(
    "Unsupported wrapper warning key for ",
    component$tag_name,
    ": ",
    warning_key,
    call. = FALSE
  )
}

# Return any wrapper-specific documentation note text.
.render_wrapper_doc_note <- function(component) {
  binding_mode <- .scalar_string(
    component$classification$binding_mode,
    fallback = "none"
  )
  binding_value_field <- .scalar_string(
    component$classification$binding_value_field,
    fallback = NA_character_
  )
  binding_value_field <- if (is.na(binding_value_field) || !nzchar(binding_value_field)) {
    "value"
  } else {
    binding_value_field
  }
  warning_key <- .component_wrapper_warning(component)
  notes <- character()

  if (identical(binding_mode, "action_with_payload")) {
    notes <- c(notes, paste(
      "When used as a Shiny input,",
      "action semantics are exposed through",
      paste0("`input$", "<input_id>", "`"),
      "and the latest selected dropdown item value is exposed through",
      paste0("`input$", "<input_id>_value", "`."),
      "The action input increments on every selection, including repeated",
      "selection of the same item. The companion value input reflects the",
      "selected item's `value`, returns `NULL` when the selected item has",
      "no `value`, and preserves an explicit empty string `\"\"` when that",
      "is the selected item's value."
    ))
  } else if (identical(binding_mode, "action")) {
    notes <- c(notes, paste(
      "When used as a Shiny input,",
      "the component exposes action semantics through",
      paste0("`input$", "<input_id>", "`."),
      "The Shiny input invalidates on each committed action rather than",
      "publishing a durable value payload."
    ))
  } else if (identical(binding_mode, "semantic")) {
    if (!is.na(binding_value_field) && nzchar(binding_value_field)) {
      notes <- c(notes, paste(
        "When used as a Shiny input,",
        paste0("`input$", "<input_id>", "`"),
        "reflects the component's current semantic",
        paste0("`", binding_value_field, "`"),
        "state."
      ))
    } else {
      notes <- c(notes, paste(
        "When used as a Shiny input,",
        paste0("`input$", "<input_id>", "`"),
        "reflects the component's current committed semantic state."
      ))
    }
  } else if (identical(binding_mode, "value")) {
    if (!is.na(binding_value_field) && nzchar(binding_value_field)) {
      notes <- c(notes, paste(
        "When used as a Shiny input,",
        paste0("`input$", "<input_id>", "`"),
        "reflects the component's current",
        paste0("`", binding_value_field, "`"),
        "value."
      ))
    } else {
      notes <- c(notes, paste(
        "When used as a Shiny input,",
        paste0("`input$", "<input_id>", "`"),
        "reflects the component's current value."
      ))
    }
  }

  if (!is.na(warning_key) && nzchar(warning_key)) {
    if (identical(warning_key, "missing_tree_item_id")) {
      notes <- c(notes, paste(
        "For stable Shiny selection values, selectable descendant",
        "`wa-tree-item` elements should have DOM `id` attributes."
      ))
    } else {
      stop(
        "Unsupported wrapper documentation note for ",
        component$tag_name,
        ": ",
        warning_key,
        call. = FALSE
      )
    }
  }

  paste(notes[nzchar(notes)], collapse = " ")
}

# Return any wrapper-specific Shiny binding section paragraphs.
.render_bind_section_paras <- function(component) {
  binding_mode <- .scalar_string(
    component$classification$binding_mode,
    fallback = "none"
  )
  binding_value_field <- .scalar_string(
    component$classification$binding_value_field,
    fallback = NA_character_
  )
  binding_value_field <- if (is.na(binding_value_field) || !nzchar(binding_value_field)) {
    "value"
  } else {
    binding_value_field
  }

  if (identical(binding_mode, "action_with_payload")) {
    return(c(
      paste(
        paste0("`input$", "<input_id>", "`"),
        "uses action semantics and invalidates on each committed action,",
        "including repeated selection of the same item."
      ),
      paste(
        paste0("`input$", "<input_id>_value", "`"),
        "reflects the latest selected item's",
        paste0("`", binding_value_field, "`"),
        "value, returns `NULL` when the selected item has no",
        paste0("`", binding_value_field, "`"),
        ", and preserves an explicit empty string `\"\"` when that is",
        "the selected item's value."
      )
    ))
  }

  if (identical(binding_mode, "action")) {
    return(paste(
      paste0("`input$", "<input_id>", "`"),
      "uses action semantics and invalidates on each committed action",
      "rather than publishing a durable value payload."
    ))
  }

  if (identical(binding_mode, "semantic")) {
    if (!is.na(binding_value_field) && nzchar(binding_value_field)) {
      return(paste(
        paste0("`input$", "<input_id>", "`"),
        "reflects the component's current semantic",
        paste0("`", binding_value_field, "`"),
        "state."
      ))
    }

    return(paste(
      paste0("`input$", "<input_id>", "`"),
      "reflects the component's current committed semantic state."
    ))
  }

  if (identical(binding_mode, "value")) {
    if (!is.na(binding_value_field) && nzchar(binding_value_field)) {
      return(paste(
        paste0("`input$", "<input_id>", "`"),
        "reflects the component's current",
        paste0("`", binding_value_field, "`"),
        "value."
      ))
    }

    return(paste(
      paste0("`input$", "<input_id>", "`"),
      "reflects the component's current value."
    ))
  }

  character()
}

# Return any generated wrapper-specific Shiny binding section block.
.render_bind_section <- function(component) {
  lines <- .roxygen_section_lines(
    "Shiny Bindings",
    .render_bind_section_paras(component)
  )

  if (length(lines) == 0L) {
    return("")
  }

  paste(c(lines, ""), collapse = "\n")
}

# Render enum validation lines for one wrapper.
.render_wrapper_validations <- function(component) {
  attrs <- .wrapper_attributes(component)
  attrs <- attrs[vapply(
    attrs,
    function(attr) length(attr$enum_values %||% character()) > 0L,
    logical(1)
  )]

  if (length(attrs) == 0L) {
    return("")
  }

  lines <- vapply(
    attrs,
    function(attr) {
      choices <- paste0(
        "c(\n",
        paste0(
          "        ",
          sprintf('"%s"', attr$enum_values),
          collapse = ",\n"
        ),
        "\n      )"
      )

      paste0(
        "  if (!is.null(",
        .as_r_symbol(attr$argument_name),
        ")) {\n",
        "    ",
        .as_r_symbol(attr$argument_name),
        " <- .wa_match_arg(\n",
        "      ",
        .as_r_symbol(attr$argument_name),
        ",\n",
        "      ",
        .r_string(attr$argument_name),
        ",\n      ",
        choices,
        "\n    )\n",
        "  }"
      )
    },
    character(1)
  )

  paste(lines, collapse = "\n\n")
}

# Render one generated wrapper file from template.
.render_wrapper_file <- function(component, template_path) {
  description <- .doc_text(
    component$description,
    fallback = paste(
      "Generated wrapper for the Web Awesome",
      paste0("`", component$tag_name, "`"),
      "component."
    )
  )
  wrapper_doc_note <- .render_wrapper_doc_note(component)
  if (nzchar(wrapper_doc_note)) {
    description <- paste(description, wrapper_doc_note)
  }

  param_docs <- .roxygen_param_lines(
    "...",
    "Child content for the component's default slot."
  )

  if (.wrapper_uses_id(component)) {
    param_name <- if (.wrapper_uses_input_id(component)) "input_id" else "id"
    param_docs <- c(
      param_docs,
      .roxygen_param_lines(param_name, .wrapper_id_param_doc(component))
    )
  }

  global_attrs <- .wrapper_global_attrs(component)
  if (length(global_attrs) > 0L) {
    param_docs <- c(
      param_docs,
      vapply(
        global_attrs,
        function(attr) {
          paste(
            .roxygen_param_lines(attr$argument_name, attr$description),
            collapse = "\n"
          )
        },
        character(1)
      )
    )
  }

  attrs <- .wrapper_attributes(component)
  if (length(attrs) > 0L) {
    param_docs <- c(
      param_docs,
      vapply(
        attrs,
        function(attr) {
          paste(
            .roxygen_param_lines(
              attr$argument_name,
              .wrapper_attr_param_doc(component, attr)
            ),
            collapse = "\n"
          )
        },
        character(1)
      )
    )
  }

  slots <- .wrapper_slots(component)
  if (length(slots) > 0L) {
    param_docs <- c(
      param_docs,
      vapply(
        slots,
        function(slot) {
          paste(
            .roxygen_param_lines(
              slot$wrapper_argument_name,
              .wrapper_slot_param_doc(slot)
            ),
            collapse = "\n"
          )
        },
        character(1)
      )
    )
  }

  values <- c(
    HEADER = .generated_header(),
    FUNCTION_NAME = component$r_function_name,
    FUNCTION_TITLE = paste("Create a", paste0("`", component$tag_name, "`"), "component"),
    FUNCTION_DESCRIPTION = paste(.roxygen_lines(description), collapse = "\n"),
    PARAM_DOCS = paste(param_docs, collapse = "\n"),
    BINDING_SECTION = .render_bind_section(component),
    TAG_NAME = .r_string(component$tag_name),
    SIGNATURE = .render_wrapper_signature(component),
    VALIDATIONS = .render_wrapper_validations(component),
    ATTRS = .render_wrapper_attrs(component),
    BOOLEAN_ATTRS = .render_wrapper_booleans(component),
    BOOLEAN_ARG_NAMES = .render_wrapper_bool_arg_names(component),
    CHILDREN = .render_wrapper_children(component),
    WRAPPER_WARNINGS = .render_wrapper_warnings(component)
  )

  .render_template(template_path, values)
}
# nolint end

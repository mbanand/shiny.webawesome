# Binding rendering helpers for the generate stage.
# nolint start: object_usage_linter,line_length_linter.

# Return whether a component should emit a Shiny binding.
.component_has_binding <- function(component) {
  isTRUE(component$classification$binding)
}

# Return one component's attribute names.
.component_attribute_names <- function(component) {
  vapply(component$attributes %||% list(), `[[`, character(1), "name")
}

# Return one component's property names.
.component_property_names <- function(component) {
  vapply(component$properties %||% list(), `[[`, character(1), "name")
}

# Return one component's event names.
.component_event_names <- function(component) {
  vapply(component$events %||% list(), `[[`, character(1), "name")
}

# Return whether the component exposes one state field by name.
.component_has_state_field <- function(component, name) {
  name %in% unique(c(.component_attribute_names(component), .component_property_names(component)))
}

# Return the preferred DOM event to subscribe to for a binding.
.binding_subscribe_event <- function(component) {
  events <- .component_event_names(component)
  preferred <- c("change", "input", "click", "toggle", "wa-change", "wa-input", "wa-toggle")
  matched <- preferred[preferred %in% events]

  if (length(matched) == 0L) {
    stop("No supported binding event found for ", component$tag_name, call. = FALSE)
  }

  matched[[1]]
}

# Return the JS binding name for one component.
.binding_name <- function(component) {
  paste0("shiny.webawesome.", component$r_function_name)
}

# Return the JS selector for one component binding.
.binding_selector <- function(component) {
  paste0(component$tag_name, "[id]")
}

# Return JS for extracting the current component value.
.binding_get_value <- function(component) {
  if (.component_has_state_field(component, "checked")) {
    return("return !!el.checked;")
  }

  paste(
    "if (Array.isArray(el.value)) {",
    "  return el.value;",
    "}",
    "return el.value;",
    sep = "\n    "
  )
}

# Return one supported list of fields for receiveMessage.
.binding_receive_fields <- function(component) {
  supported <- c("value", "checked", "label", "hint", "disabled")
  fields <- supported[supported %in% unique(c(
    .component_attribute_names(component),
    .component_property_names(component)
  ))]

  if (.component_has_state_field(component, "checked") && !("value" %in% fields)) {
    fields <- c("value", fields)
  }

  unique(fields)
}

# Return JS for applying one receiveMessage payload.
.binding_set_value <- function(component) {
  fields <- .binding_receive_fields(component)

  if (length(fields) == 0L) {
    return("")
  }

  lines <- vapply(
    fields,
    function(field) {
      if (.component_has_state_field(component, "checked") && identical(field, "value")) {
        return("if (Object.prototype.hasOwnProperty.call(data, \"value\")) { el.checked = !!data.value; }")
      }

      if (field %in% c("checked", "disabled")) {
        return(paste0(
          "if (Object.prototype.hasOwnProperty.call(data, \"",
          field,
          "\")) { el.",
          field,
          " = !!data.",
          field,
          "; }"
        ))
      }

      paste0(
        "if (Object.prototype.hasOwnProperty.call(data, \"",
        field,
        "\")) { el.",
        field,
        " = data.",
        field,
        "; }"
      )
    },
    character(1)
  )

  paste(lines, collapse = "\n    ")
}

# Render JS binding behavior values for one component.
.binding_values <- function(component) {
  c(
    FIND_SELECTOR = .binding_selector(component),
    BINDING_NAME = .binding_name(component),
    GET_VALUE = .binding_get_value(component),
    SET_VALUE = .binding_set_value(component),
    SUBSCRIBE_EVENT = .binding_subscribe_event(component)
  )
}

# Render one JS binding file from template.
.render_binding_file <- function(component, template_path) {
  if (!.component_has_binding(component)) {
    return(NULL)
  }

  values <- c(
    HEADER = paste("//", .generated_header()),
    FILE_STEM = component$component_name,
    .binding_values(component)
  )

  .render_template(template_path, values)
}
# nolint end

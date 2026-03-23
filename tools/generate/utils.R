# Shared helpers for the generate stage.

# Return `fallback` when `value` is `NULL`.
.or_default <- function(value, fallback) {
  if (is.null(value)) {
    fallback
  } else {
    value
  }
}

# Return one trimmed scalar string from possibly missing metadata.
.scalar_string <- function(value, fallback = NA_character_) {
  value <- .or_default(value, fallback)

  if (length(value) == 0L) {
    return(fallback)
  }

  value <- as.character(value[[1]])
  value <- trimws(value)

  if (!nzchar(value)) {
    return(fallback)
  }

  value
}

# Normalize one metadata name into snake_case.
.as_snake_case <- function(value) {
  value <- gsub("([a-z0-9])([A-Z])", "\\1_\\2", value, perl = TRUE)
  value <- gsub("[^A-Za-z0-9]+", "_", value, perl = TRUE)
  value <- gsub("_+", "_", value, perl = TRUE)
  value <- gsub("^_|_$", "", value, perl = TRUE)
  tolower(value)
}

# Return whether one name is reserved in R syntax.
.is_reserved_r_word <- function(value) {
  value %in% c(
    "if", "else", "repeat", "while", "function", "for", "in",
    "next", "break", "TRUE", "FALSE", "NULL", "Inf", "NaN",
    "NA", "NA_integer_", "NA_real_", "NA_complex_", "NA_character_"
  )
}

# Return one name as a safe R symbol for generated code.
.as_r_symbol <- function(value) {
  value <- .scalar_string(value, fallback = "")

  if (!nzchar(value)) {
    return(value)
  }

  if (identical(make.names(value), value) && !.is_reserved_r_word(value)) {
    return(value)
  }

  paste0("`", value, "`")
}

# Normalize whitespace in one text scalar.
.squish_ws <- function(value) {
  value <- .scalar_string(value, fallback = "")
  value <- gsub("[[:space:]]+", " ", value, perl = TRUE)
  trimws(value)
}

# Return one normalized type string from metadata.
.type_text <- function(type_node) {
  if (is.null(type_node)) {
    return(NA_character_)
  }

  .scalar_string(type_node$text, fallback = NA_character_)
}

# Return whether a type string represents a boolean.
.is_boolean_type <- function(type_text) {
  identical(.scalar_string(type_text, fallback = ""), "boolean")
}

# Extract string enum values from a TypeScript union type.
.enum_values <- function(type_text) {
  type_text <- .scalar_string(type_text, fallback = "")

  if (!nzchar(type_text)) {
    return(character())
  }

  parts <- trimws(strsplit(type_text, "|", fixed = TRUE)[[1]])
  parts <- parts[nzchar(parts)]

  if (length(parts) == 0L) {
    return(character())
  }

  quoted <- grepl("^'.+'$", parts)
  if (!all(quoted)) {
    return(character())
  }

  sort(unique(sub("^'(.+)'$", "\\1", parts, perl = TRUE)))
}

# Return one sorted character vector with missing values removed.
.sorted_unique <- function(values) {
  values <- values[!is.na(values) & nzchar(values)]
  sort(unique(values))
}

# Normalize a possibly mixed filter input into one sorted token vector.
.normalize_filter_tokens <- function(values) {
  if (is.null(values) || length(values) == 0L) {
    return(character())
  }

  pieces <- unlist(strsplit(as.character(values), ",", fixed = TRUE))
  pieces <- trimws(pieces)
  pieces <- pieces[nzchar(pieces)]
  .sorted_unique(tolower(pieces))
}

# Write one deterministic JSON debug artifact.
.write_debug_json <- function(path, object) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    object,
    path = path,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null"
  )

  invisible(path)
}

# Return one named list keyed by component tag for human-readable debug output.
.components_by_tag <- function(components) {
  if (is.null(components) || length(components) == 0L) {
    return(list())
  }

  tags <- vapply(components, `[[`, character(1), "tag_name")
  order_idx <- order(tags)
  components <- components[order_idx]
  tags <- tags[order_idx]
  names(components) <- tags
  components
}

# Return one named list keyed by element name for human-readable debug output.
.debug_items_by_name <- function(items, field = "name") {
  if (is.null(items) || length(items) == 0L) {
    return(list())
  }

  item_names <- vapply(items, `[[`, character(1), field)
  order_idx <- order(item_names)
  items <- items[order_idx]
  item_names <- item_names[order_idx]
  names(items) <- item_names
  items
}

# Return one readable debug key for one slot definition.
.debug_slot_key <- function(slot) {
  key <- .scalar_string(slot$name, fallback = "")

  if (nzchar(key)) {
    return(key)
  }

  .scalar_string(slot$argument_name, fallback = "")
}

# Return one component rewritten for human-readable debug-schema inspection.
.debug_component_view <- function(component) {
  component$attributes <- .debug_items_by_name(component$attributes)
  component$properties <- .debug_items_by_name(component$properties)
  component$events <- .debug_items_by_name(component$events)
  component$slots <- .debug_items_by_name(
    component$slots,
    field = "argument_name"
  )

  if (length(component$slots) > 0L) {
    slot_names <- vapply(component$slots, .debug_slot_key, character(1))
    order_idx <- order(slot_names)
    component$slots <- component$slots[order_idx]
    names(component$slots) <- slot_names[order_idx]
  }

  component
}

# Return components rewritten for the debug schema artifact.
.debug_components_by_tag <- function(components) {
  components <- .components_by_tag(components)

  if (length(components) == 0L) {
    return(components)
  }

  lapply(components, .debug_component_view)
}

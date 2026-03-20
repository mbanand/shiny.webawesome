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

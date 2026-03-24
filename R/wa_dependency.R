# Return the relative script paths for generated Shiny bindings.
.wa_binding_scripts <- function() {
  binding_dir <- system.file("bindings", package = "shiny.webawesome")

  if (!nzchar(binding_dir)) {
    binding_dir <- file.path("inst", "bindings")
  }

  if (!dir.exists(binding_dir)) {
    return(character())
  }

  scripts <- list.files(
    binding_dir,
    pattern = "\\.js$",
    full.names = FALSE
  )

  if (length(scripts) == 0L) {
    return(character())
  }

  paste0("bindings/", sort(scripts))
}

# Build the package dependency object for the shipped Web Awesome runtime.
.wa_dependency <- function() {
  scripts <- c("www/webawesome-init.js", .wa_binding_scripts())
  scripts <- lapply(
    scripts,
    function(path) list(src = path, type = "module")
  )

  htmltools::htmlDependency(
    name = "shiny.webawesome",
    version = as.character(utils::packageVersion("shiny.webawesome")),
    package = "shiny.webawesome",
    src = c(file = "."),
    stylesheet = "www/wa/styles/webawesome.css",
    script = scripts
  )
}

# Return whether wrapper-level dependency attachment is currently enabled.
.wa_dependency_enabled <- function() {
  isTRUE(getOption("shiny.webawesome.attach_dependency", TRUE))
}

# Evaluate code with wrapper-level dependency attachment temporarily disabled.
.wa_without_dependency <- function(code) {
  old <- options(shiny.webawesome.attach_dependency = FALSE)
  on.exit(options(old), add = TRUE)
  force(code)
}

# Attach the package dependency when wrapper-level attachment is enabled.
.wa_attach_dependency <- function(tag) {
  if (!.wa_dependency_enabled()) {
    return(tag)
  }

  htmltools::attachDependencies(tag, .wa_dependency())
}

# Return the user-facing name to report for one boolean attribute.
.wa_boolean_arg_label <- function(name, boolean_arg_names) {
  if (is.null(boolean_arg_names) || !(name %in% names(boolean_arg_names))) {
    return(name)
  }

  boolean_arg_names[[name]]
}

# Validate one boolean wrapper argument before HTML normalization.
.wa_validate_boolean_attr <- function(value, name, boolean_arg_names = NULL) {
  if (is.logical(value) && length(value) == 1L && !is.na(value)) {
    return(value)
  }

  label <- .wa_boolean_arg_label(name, boolean_arg_names)
  stop(
    sprintf("`%s` must be TRUE, FALSE, or NULL.", label),
    call. = FALSE
  )
}

# Normalize component attributes for deterministic HTML emission.
.wa_normalize_attrs <- function(
  attrs,
  boolean_names = character(),
  boolean_arg_names = NULL
) {
  attrs <- Filter(Negate(is.null), attrs)

  if (length(attrs) == 0L) {
    return(list())
  }

  attrs <- Map(
    function(name, value) {
      if (!(name %in% boolean_names)) {
        return(value)
      }

      value <- .wa_validate_boolean_attr(
        value,
        name,
        boolean_arg_names = boolean_arg_names
      )

      if (isFALSE(value)) {
        return(NULL)
      }

      if (isTRUE(value)) {
        return(NA_character_)
      }

      value
    },
    names(attrs),
    attrs
  )
  attrs <- stats::setNames(attrs, names(attrs))
  Filter(Negate(is.null), attrs)
}

# Validate one optional wrapper enum argument against exact allowed values.
.wa_match_arg <- function(value, name, values) {
  if (is.null(value)) {
    return(NULL)
  }

  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    stop(
      sprintf("`%s` must be one non-missing string.", name),
      call. = FALSE
    )
  }

  matched <- match(value, values)
  if (is.na(matched)) {
    stop(
      sprintf(
        "`%s` must be one of %s.",
        name,
        paste(sprintf('"%s"', values), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  values[[matched]]
}

# Attach one slot name to each child in a slot payload.
.wa_slot <- function(content, slot) {
  if (is.null(content)) {
    return(NULL)
  }

  content <- as.list(htmltools::tagList(content))
  if (length(content) == 0L) {
    return(NULL)
  }

  htmltools::tagList(lapply(
    content,
    function(child) {
      if (inherits(child, "shiny.tag")) {
        return(htmltools::tagAppendAttributes(child, slot = slot))
      }

      htmltools::tags$span(slot = slot, child)
    }
  ))
}

# Build one Web Awesome tag and attach the package dependency when enabled.
.wa_component <- function(tag_name, ..., .attrs = list()) {
  children <- list(...)
  tag <- htmltools::tag(tag_name, children)

  if (length(.attrs) > 0L) {
    tag <- do.call(htmltools::tagAppendAttributes, c(list(tag), .attrs))
  }

  .wa_attach_dependency(tag)
}

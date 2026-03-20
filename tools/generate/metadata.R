# Metadata loading helpers for the generate stage.
# nolint start: object_usage_linter,line_length_linter.

# Check whether a path looks like the repository root.
.is_repo_root <- function(root) {
  required_paths <- c("DESCRIPTION", "docs", "tools")
  all(file.exists(file.path(root, required_paths)))
}

# Remove the repository root prefix from one or more absolute paths.
.strip_root_prefix <- function(paths, root) {
  sub(paste0("^", root, "/?"), "", paths)
}

# Return the default metadata directory relative to the repository root.
.default_metadata_dir <- function() {
  file.path("inst", "extdata", "webawesome")
}

# Return the default metadata file path relative to the repository root.
.default_metadata_file <- function(metadata_dir = .default_metadata_dir()) {
  file.path(metadata_dir, "custom-elements.json")
}

# Return the default copied version marker path relative to the repository root.
.default_metadata_version_file <- function(
  metadata_dir = .default_metadata_dir()
) {
  file.path(metadata_dir, "VERSION")
}

# Resolve the copied metadata file path.
.resolve_metadata_path <- function(root,
                                   metadata_file = .default_metadata_file()) {
  file.path(root, metadata_file)
}

# Resolve the copied metadata version file path.
.resolve_metadata_version_path <- function(
  root,
  version_file = .default_metadata_version_file()
) {
  file.path(root, version_file)
}

# Return all fetched upstream custom-elements metadata files under vendor/.
.vendor_metadata_candidates <- function(root) {
  sort(
    Sys.glob(
      file.path(root, "vendor", "webawesome", "*", "dist-cdn", "custom-elements.json")
    )
  )
}

# Return whether at least one fetched upstream Web Awesome dist-cdn exists.
.has_fetched_webawesome_dist_cdn <- function(root) {
  length(.vendor_metadata_candidates(root)) > 0L
}

# Build the missing-input remediation message for the generate stage.
.generate_input_error <- function(root, metadata_file) {
  if (.has_fetched_webawesome_dist_cdn(root)) {
    return(
      paste(
        "Generator metadata does not exist:",
        metadata_file,
        "Run prune_webawesome() first."
      )
    )
  }

  paste(
    "Generator metadata does not exist:",
    metadata_file,
    "No fetched Web Awesome dist-cdn runtime was found under vendor/webawesome/.",
    "Run fetch_webawesome() and then prune_webawesome() first."
  )
}

# Validate that prune-owned generator inputs exist.
.validate_generate_inputs <- function(
  root,
  metadata_path,
  metadata_file = .default_metadata_file()
) {
  if (!.is_repo_root(root)) {
    stop("`root` does not appear to be the repository root.", call. = FALSE)
  }

  if (!file.exists(metadata_path)) {
    stop(.generate_input_error(root, metadata_file), call. = FALSE)
  }

  invisible(TRUE)
}

# Read the copied Web Awesome version marker when present.
.read_metadata_version <- function(
  root,
  version_file = .default_metadata_version_file()
) {
  version_path <- .resolve_metadata_version_path(root, version_file)

  if (!file.exists(version_path)) {
    return(NA_character_)
  }

  .scalar_string(
    readLines(version_path, warn = FALSE, encoding = "UTF-8"),
    fallback = NA_character_
  )
}

# Read the copied custom-elements metadata as a nested list.
.read_component_metadata <- function(metadata_path) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop(
      "The `jsonlite` package is required to read custom-elements metadata.",
      call. = FALSE
    )
  }

  jsonlite::fromJSON(metadata_path, simplifyVector = FALSE)
}

# Return all modules from the custom-elements payload.
.metadata_modules <- function(metadata) {
  .or_default(metadata$modules, list())
}

# Return custom element declarations paired with their source module paths.
.component_declaration_records <- function(metadata) {
  modules <- .metadata_modules(metadata)
  records <- list()

  for (module in modules) {
    declarations <- .or_default(module$declarations, list())
    module_path <- .scalar_string(module$path, fallback = NA_character_)

    for (declaration in declarations) {
      tag_name <- .scalar_string(declaration$tagName, fallback = NA_character_)

      if (is.na(tag_name) || !startsWith(tag_name, "wa-")) {
        next
      }

      records[[length(records) + 1L]] <- list(
        module_path = module_path,
        declaration = declaration
      )
    }
  }

  if (length(records) == 0L) {
    return(list())
  }

  order_keys <- vapply(
    records,
    function(record) .scalar_string(record$declaration$tagName, fallback = ""),
    character(1)
  )

  records[order(order_keys)]
}
# nolint end

# Return the known warning-registry defaults for the package runtime.
.wa_warning_defaults <- function() {
  list(
    missing_tree_item_id = TRUE
  )
}

# Return the known package warning-registry keys.
.wa_warning_keys <- function() {
  names(.wa_warning_defaults())
}

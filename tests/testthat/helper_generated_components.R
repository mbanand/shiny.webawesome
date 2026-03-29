render_html <- function(tag) {
  as.character(htmltools::renderTags(tag)$html)
}

expect_exact_html <- function(actual, expected_lines) {
  testthat::expect_equal(actual, paste(expected_lines, collapse = "\n"))
}

make_wa_dropdown_item <- function(value, label) {
  shiny.webawesome:::wa_dropdown_item(label, value = value)
}

make_wa_option <- function(value, label) {
  shiny.webawesome:::wa_option(label, value = value)
}

make_wa_radio <- function(value, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-radio", label),
    value = value
  )
}

make_wa_tab <- function(panel, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-tab", label),
    panel = panel
  )
}

make_wa_tab_panel <- function(name, label) {
  htmltools::tagAppendAttributes(
    htmltools::tag("wa-tab-panel", label),
    name = name
  )
}

# Capture update-message payloads from generated update helpers in unit tests.
new_message_recorder <- function() {
  seen <- new.env(parent = emptyenv())
  seen$calls <- list()

  session <- list(
    sendInputMessage = function(input_id, message) {
      seen$calls[[length(seen$calls) + 1L]] <- list(
        input_id = input_id,
        message = message
      )
    }
  )

  list(
    session = session,
    seen = seen
  )
}

skip_if_no_chrome <- function() {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    testthat::skip("chromote is not available")
  }

  chrome <- suppressMessages(chromote::find_chrome())
  if (is.null(chrome)) {
    testthat::skip("No Chromium-based browser available for shinytest2")
  }
}

# Launch one shared shinytest2 app fixture and wait for its initial idle state.
new_browser_runtime_app <- function(app_name) {
  app <- shinytest2::AppDriver$new(
    app_dir = testthat::test_path("apps", app_name),
    name = app_name
  )

  app$wait_for_idle()
  app
}

# Wait until the requested custom elements have been registered in the browser.
wait_for_custom_elements <- function(app, tags) {
  checks <- paste(
    sprintf("Boolean(window.customElements.get('%s'))", tags),
    collapse = " && "
  )

  app$wait_for_js(checks)
}

# Poll a Shiny input until it reaches the expected value from the browser.
wait_for_shiny_input <- function(
  app,
  input,
  expected,
  timeout = 5,
  poll_interval = 0.1
) {
  values_match <- function(actual, expected) {
    if (is.numeric(actual) && is.numeric(expected)) {
      return(
        identical(length(actual), length(expected)) &&
          all(actual == expected)
      )
    }

    identical(actual, expected)
  }

  deadline <- Sys.time() + timeout

  repeat {
    value <- app$get_value(input = input)

    if (values_match(value, expected)) {
      return(invisible(value))
    }

    if (Sys.time() >= deadline) {
      testthat::fail(
        sprintf(
          "Timed out waiting for input$%s to equal %s; last value was %s",
          input,
          paste(deparse(expected), collapse = " "),
          paste(deparse(value), collapse = " ")
        )
      )
    }

    Sys.sleep(poll_interval)
  }
}

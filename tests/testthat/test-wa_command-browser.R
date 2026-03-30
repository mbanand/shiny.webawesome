test_that("wa_set_property updates a live dialog property from the server", {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("shinytest2")
  skip_if_no_chrome()

  app <- new_browser_runtime_app("runtime-command-layer")
  on.exit(app$stop(), add = TRUE)

  wait_for_custom_elements(app, "wa-dialog")

  app$click("open_dialog")
  app$wait_for_js("document.getElementById('dialog').open === true")

  testthat::expect_true(app$get_js("document.getElementById('dialog').open"))
  wait_for_shiny_input(app, input = "dialog", expected = TRUE)

  app$click("close_dialog")
  app$wait_for_js("document.getElementById('dialog').open === false")

  testthat::expect_false(app$get_js("document.getElementById('dialog').open"))
  wait_for_shiny_input(app, input = "dialog", expected = FALSE)
})

test_that("wa_set_property updates a non-boolean string property", {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("shinytest2")
  skip_if_no_chrome()

  app <- new_browser_runtime_app("runtime-command-layer")
  on.exit(app$stop(), add = TRUE)

  wait_for_custom_elements(app, "wa-input")

  testthat::expect_equal(
    app$get_js("document.getElementById('text_input').label"),
    "Before"
  )

  app$click("update_input_label", wait_ = FALSE)
  app$wait_for_js("document.getElementById('text_input').label === 'After'")

  testthat::expect_equal(
    app$get_js("document.getElementById('text_input').label"),
    "After"
  )
})

test_that("wa_call_method invokes details show and hide from the server", {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("shinytest2")
  skip_if_no_chrome()

  app <- new_browser_runtime_app("runtime-command-layer")
  on.exit(app$stop(), add = TRUE)

  wait_for_custom_elements(app, "wa-details")

  app$click("show_details", wait_ = FALSE)
  app$wait_for_js("document.getElementById('details').open === true")

  testthat::expect_true(app$get_js("document.getElementById('details').open"))
  wait_for_shiny_input(app, input = "details", expected = TRUE)

  app$click("hide_details", wait_ = FALSE)
  app$wait_for_js("document.getElementById('details').open === false")

  testthat::expect_false(app$get_js("document.getElementById('details').open"))
  wait_for_shiny_input(app, input = "details", expected = FALSE)
})

test_that("wa_call_method invokes a method with arguments", {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("shinytest2")
  skip_if_no_chrome()

  app <- new_browser_runtime_app("runtime-command-layer")
  on.exit(app$stop(), add = TRUE)

  wait_for_custom_elements(app, "wa-checkbox")

  app$click("set_checkbox_error", wait_ = FALSE)
  app$wait_for_js(
    paste(
      "document.getElementById('check').validationMessage",
      "=== 'Please accept the terms.'"
    )
  )

  testthat::expect_equal(
    app$get_js("document.getElementById('check').validationMessage"),
    "Please accept the terms."
  )

  app$click("clear_checkbox_error", wait_ = FALSE)
  app$wait_for_js("document.getElementById('check').validationMessage === ''")

  testthat::expect_equal(
    app$get_js("document.getElementById('check').validationMessage"),
    ""
  )
})

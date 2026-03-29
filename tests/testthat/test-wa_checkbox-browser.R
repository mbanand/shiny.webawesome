test_that(
  "wa_checkbox keeps boolean checked state aligned in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-checkbox")

    app$run_js(
      paste(
        "const el = document.getElementById('checkbox');",
        "el.checked = true;",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "checkbox", expected = TRUE)

    testthat::expect_true(app$get_value(input = "checkbox"))
    testthat::expect_equal(
      app$get_text("#checkbox_state"),
      "input$checkbox = TRUE"
    )
    testthat::expect_true(
      app$get_js("document.getElementById('checkbox').checked")
    )
  }
)

test_that(
  "wa_radio_group keeps selected value aligned in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, c("wa-radio", "wa-radio-group"))

    app$run_js(
      paste(
        "const el = document.getElementById('radio_group');",
        "el.value = 'beta';",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "radio_group", expected = "beta")

    testthat::expect_equal(app$get_value(input = "radio_group"), "beta")
    testthat::expect_equal(
      app$get_text("#radio_group_state"),
      'input$radio_group = "beta"'
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('radio_group').value"),
      "beta"
    )
  }
)

test_that(
  "wa_switch keeps boolean checked state aligned in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-switch")

    app$run_js(
      paste(
        "const el = document.getElementById('switch');",
        "el.checked = true;",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "switch", expected = TRUE)

    testthat::expect_true(app$get_value(input = "switch"))
    testthat::expect_equal(
      app$get_text("#switch_state"),
      "input$switch = TRUE"
    )
    testthat::expect_true(
      app$get_js("document.getElementById('switch').checked")
    )
  }
)

test_that(
  "wa_slider keeps browser and Shiny state aligned in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-slider")

    app$run_js(
      paste(
        "const el = document.getElementById('slider');",
        "el.value = 5;",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "slider", expected = 5)

    testthat::expect_equal(app$get_value(input = "slider"), 5)
    testthat::expect_equal(
      app$get_text("#slider_state"),
      "input$slider = 5"
    )
    testthat::expect_equal(
      app$get_js("String(document.getElementById('slider').value)"),
      "5"
    )

    app$click("update_slider")

    wait_for_shiny_input(app, input = "slider", expected = 7)

    testthat::expect_equal(app$get_value(input = "slider"), 7)
    testthat::expect_equal(
      app$get_js("document.getElementById('slider').label"),
      "Updated volume"
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('slider').hint"),
      "Updated slider hint"
    )
  }
)

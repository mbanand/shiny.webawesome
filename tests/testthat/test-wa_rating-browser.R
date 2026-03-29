test_that(
  "wa_rating keeps numeric rating state aligned in the semantic harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-rating")

    app$run_js(
      paste(
        "const el = document.getElementById('rating');",
        "el.value = 4;",
        "el.dispatchEvent(new Event('change', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "rating", expected = 4)

    testthat::expect_equal(app$get_value(input = "rating"), 4)
    testthat::expect_equal(app$get_text("#rating_state"), "input$rating = 4")
    testthat::expect_equal(
      app$get_js("document.getElementById('rating').value"),
      4
    )
  }
)

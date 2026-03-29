test_that(
  "wa_drawer keeps semantic open state aligned in the event harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic-events")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-drawer")

    app$run_js(
      paste(
        "const el = document.getElementById('drawer');",
        "el.open = true;",
        "el.dispatchEvent(new CustomEvent('wa-show', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "drawer", expected = TRUE)

    testthat::expect_true(app$get_value(input = "drawer"))
    testthat::expect_equal(app$get_text("#drawer_state"), "input$drawer = TRUE")
    testthat::expect_true(
      app$get_js("document.getElementById('drawer').open")
    )

    app$run_js(
      paste(
        "const el = document.getElementById('drawer');",
        "el.open = false;",
        "el.dispatchEvent(new CustomEvent('wa-after-hide', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "drawer", expected = FALSE)

    testthat::expect_false(app$get_value(input = "drawer"))
    testthat::expect_equal(
      app$get_text("#drawer_state"),
      "input$drawer = FALSE"
    )
  }
)

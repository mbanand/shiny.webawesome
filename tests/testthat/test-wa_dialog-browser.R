test_that(
  "wa_dialog keeps semantic open state aligned in the event harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic-events")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-dialog")

    app$run_js(
      paste(
        "const el = document.getElementById('dialog');",
        "el.open = true;",
        "el.dispatchEvent(new CustomEvent('wa-show', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "dialog", expected = TRUE)

    testthat::expect_true(app$get_value(input = "dialog"))
    testthat::expect_equal(app$get_text("#dialog_state"), "input$dialog = TRUE")
    testthat::expect_true(
      app$get_js("document.getElementById('dialog').open")
    )

    app$run_js(
      paste(
        "const el = document.getElementById('dialog');",
        "el.open = false;",
        "el.dispatchEvent(new CustomEvent('wa-after-hide', { bubbles: true }));"
      )
    )

    wait_for_shiny_input(app, input = "dialog", expected = FALSE)

    testthat::expect_false(app$get_value(input = "dialog"))
    testthat::expect_equal(
      app$get_text("#dialog_state"),
      "input$dialog = FALSE"
    )
  }
)

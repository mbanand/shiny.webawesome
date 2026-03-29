test_that(
  "wa_carousel keeps semantic slide state aligned in the event harness",
  {
    testthat::skip_on_cran()
    testthat::skip_if_not_installed("shinytest2")
    skip_if_no_chrome()

    app <- new_browser_runtime_app("runtime-semantic-events")
    on.exit(app$stop(), add = TRUE)

    wait_for_custom_elements(app, "wa-carousel")

    testthat::expect_match(
      app$get_text("#wa_carousel-section h2"),
      "wa_carousel"
    )

    app$run_js(
      paste(
        "const el = document.getElementById('carousel');",
        "el.activeSlide = 1;",
        paste(
          "el.dispatchEvent(new CustomEvent('wa-slide-change',",
          "{ bubbles: true }));"
        )
      )
    )

    wait_for_shiny_input(app, input = "carousel", expected = 1)

    testthat::expect_equal(app$get_value(input = "carousel"), 1)
    testthat::expect_equal(
      app$get_text("#carousel_state"),
      "input$carousel = 1"
    )
    testthat::expect_equal(
      app$get_js("document.getElementById('carousel').activeSlide"),
      1
    )
  }
)

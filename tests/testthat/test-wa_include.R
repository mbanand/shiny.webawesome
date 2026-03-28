test_that("wa_include defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_include()),
    c("<wa-include></wa-include>")
  )
})

test_that("wa_include override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_include(
        id = "include",
        allow_scripts = TRUE,
        dir = "rtl",
        lang = "en",
        mode = "same-origin",
        src = "panel.html"
      )
    ),
    c(
      paste0(
        '<wa-include id="include" allow-scripts dir="rtl" lang="en" ',
        'mode="same-origin" src="panel.html"></wa-include>'
      )
    )
  )
})

test_that("wa_include allow_scripts validates and renders correctly", {
  default_html <- render_html(shiny.webawesome:::wa_include())

  expect_exact_html(
    render_html(shiny.webawesome:::wa_include(allow_scripts = TRUE)),
    c("<wa-include allow-scripts></wa-include>")
  )

  expect_equal(
    render_html(shiny.webawesome:::wa_include(allow_scripts = FALSE)),
    default_html
  )

  expect_equal(
    render_html(shiny.webawesome:::wa_include(allow_scripts = NULL)),
    default_html
  )

  expect_error(
    shiny.webawesome:::wa_include(allow_scripts = "yes"),
    "`allow_scripts` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

test_that("wa_include mode enum validates exactly", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_include(mode = "no-cors")),
    c('<wa-include mode="no-cors"></wa-include>')
  )

  expect_error(
    shiny.webawesome:::wa_include(mode = "private"),
    "`mode` must be one of ",
    fixed = TRUE
  )
})

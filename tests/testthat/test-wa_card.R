test_that("wa_card defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_card("Hello")),
    c("<wa-card>Hello</wa-card>")
  )
})

test_that("wa_card representative overrides render expected attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_card(
        "Hello",
        id = "card",
        appearance = "filled",
        dir = "rtl",
        lang = "en",
        orientation = "horizontal",
        header = "Header",
        media = "Media"
      )
    ),
    c(
      paste0(
        '<wa-card id="card" appearance="filled" dir="rtl" lang="en" ',
        'orientation="horizontal">'
      ),
      "  Hello",
      '  <span slot="header">Header</span>',
      '  <span slot="media">Media</span>',
      "</wa-card>"
    )
  )
})

test_that("wa_card uses id and does not expose input_id", {
  expect_false("input_id" %in% names(formals(shiny.webawesome:::wa_card)))

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_card("Hello", id = "card")
    ),
    c('<wa-card id="card">Hello</wa-card>')
  )
})

test_that("wa_card enum arguments validate exactly", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_card(
        "Hello",
        appearance = "plain",
        orientation = "vertical"
      )
    ),
    c('<wa-card appearance="plain" orientation="vertical">Hello</wa-card>')
  )

  expect_error(
    shiny.webawesome:::wa_card("Hello", appearance = "invalid"),
    "`appearance` must be one of ",
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome:::wa_card("Hello", orientation = "diagonal"),
    "`orientation` must be one of ",
    fixed = TRUE
  )
})

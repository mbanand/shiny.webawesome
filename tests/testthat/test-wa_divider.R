test_that("wa_divider defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_divider()),
    c("<wa-divider></wa-divider>")
  )
})

test_that("wa_divider override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_divider(
        id = "divider",
        dir = "rtl",
        lang = "en",
        orientation = "vertical"
      )
    ),
    c(
      paste0(
        '<wa-divider id="divider" dir="rtl" lang="en" ',
        'orientation="vertical"></wa-divider>'
      )
    )
  )
})

test_that("wa_divider orientation validates exactly", {
  expect_error(
    shiny.webawesome:::wa_divider(orientation = "diagonal"),
    "`orientation` must be one of ",
    fixed = TRUE
  )
})

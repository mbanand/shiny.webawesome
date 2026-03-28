test_that("wa_spinner defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_spinner()),
    c("<wa-spinner></wa-spinner>")
  )
})

test_that("wa_spinner override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_spinner(
        id = "spinner",
        dir = "rtl",
        lang = "en"
      )
    ),
    c('<wa-spinner id="spinner" dir="rtl" lang="en"></wa-spinner>')
  )
})

test_that("wa_radio defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_radio("Alpha")),
    c("<wa-radio>Alpha</wa-radio>")
  )
})

test_that("wa_radio override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_radio(
        "Alpha",
        id = "radio",
        value = "alpha",
        disabled = TRUE,
        name = "group",
        appearance = "button",
        dir = "rtl",
        lang = "en",
        size = "large"
      )
    ),
    c(
      paste0(
        '<wa-radio id="radio" value="alpha" disabled name="group" ',
        'appearance="button" dir="rtl" lang="en" size="large">',
        "Alpha</wa-radio>"
      )
    )
  )
})

test_that("wa_radio boolean and enum args validate exactly", {
  expect_error(
    shiny.webawesome:::wa_radio("Alpha", disabled = "yes"),
    "`disabled` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome:::wa_radio("Alpha", appearance = "filled"),
    "`appearance` must be one of ",
    fixed = TRUE
  )
})

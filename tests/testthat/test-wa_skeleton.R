test_that("wa_skeleton defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_skeleton()),
    c("<wa-skeleton></wa-skeleton>")
  )
})

test_that("wa_skeleton override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_skeleton(
        id = "skeleton",
        dir = "rtl",
        effect = "pulse",
        lang = "en"
      )
    ),
    c(
      paste0(
        '<wa-skeleton id="skeleton" dir="rtl" effect="pulse" ',
        'lang="en"></wa-skeleton>'
      )
    )
  )
})

test_that("wa_skeleton effect validates exactly", {
  expect_error(
    shiny.webawesome:::wa_skeleton(effect = "blink"),
    "`effect` must be one of ",
    fixed = TRUE
  )
})

test_that("wa_popover defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_popover("Popover body")),
    c("<wa-popover>Popover body</wa-popover>")
  )
})

test_that("wa_popover override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_popover(
        "Popover body",
        id = "popover",
        distance = 12,
        `for` = "popover_target",
        open = TRUE,
        placement = "top-start",
        skidding = 4,
        without_arrow = TRUE
      )
    ),
    c(
      paste0(
        '<wa-popover id="popover" distance="12" for="popover_target" ',
        'open placement="top-start" skidding="4" without-arrow>',
        "Popover body</wa-popover>"
      )
    )
  )
})

test_that("wa_popover boolean and enum args validate exactly", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_popover("Popover body", open = TRUE)),
    c("<wa-popover open>Popover body</wa-popover>")
  )

  expect_error(
    shiny.webawesome:::wa_popover("Popover body", without_arrow = "yes"),
    "`without_arrow` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome:::wa_popover("Popover body", placement = "center"),
    "`placement` must be one of ",
    fixed = TRUE
  )
})

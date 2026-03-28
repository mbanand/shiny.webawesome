test_that("wa_tooltip defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_tooltip("Tooltip body")),
    c("<wa-tooltip>Tooltip body</wa-tooltip>")
  )
})

test_that("wa_tooltip override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tooltip(
        "Tooltip body",
        id = "tooltip",
        disabled = TRUE,
        distance = 12,
        `for` = "tooltip_target",
        hide_delay = 50,
        open = TRUE,
        placement = "bottom-end",
        show_delay = 25,
        skidding = 4,
        trigger = "manual",
        without_arrow = TRUE
      )
    ),
    c(
      paste0(
        '<wa-tooltip id="tooltip" disabled distance="12" ',
        'for="tooltip_target" hide-delay="50" open ',
        'placement="bottom-end" show-delay="25" skidding="4" ',
        'trigger="manual" without-arrow>',
        "Tooltip body</wa-tooltip>"
      )
    )
  )
})

test_that("wa_tooltip boolean and enum args validate exactly", {
  expect_error(
    shiny.webawesome:::wa_tooltip("Tooltip body", disabled = "yes"),
    "`disabled` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tooltip("Tooltip body", placement = "top-start")
    ),
    c('<wa-tooltip placement="top-start">Tooltip body</wa-tooltip>')
  )

  expect_error(
    shiny.webawesome:::wa_tooltip("Tooltip body", placement = "center"),
    "`placement` must be one of ",
    fixed = TRUE
  )
})

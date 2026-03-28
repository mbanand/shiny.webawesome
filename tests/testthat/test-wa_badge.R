test_that("wa_badge defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_badge("Beta")),
    c("<wa-badge>Beta</wa-badge>")
  )
})

test_that("wa_badge override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_badge(
        "Beta",
        id = "badge",
        appearance = "filled",
        attention = "pulse",
        dir = "rtl",
        lang = "en",
        pill = TRUE,
        variant = "brand",
        end = "End",
        start = "Start"
      )
    ),
    c(
      paste0(
        '<wa-badge id="badge" appearance="filled" attention="pulse" ',
        'dir="rtl" lang="en" pill variant="brand">'
      ),
      "  Beta",
      '  <span slot="end">End</span>',
      '  <span slot="start">Start</span>',
      "</wa-badge>"
    )
  )
})

test_that("wa_badge boolean and enum args validate exactly", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_badge("Beta", pill = TRUE)),
    c("<wa-badge pill>Beta</wa-badge>")
  )

  expect_error(
    shiny.webawesome:::wa_badge("Beta", pill = "yes"),
    "`pill` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )

  enum_cases <- list(
    list(
      arg = "appearance",
      attr = "appearance",
      valid = "outlined",
      invalid = "glass"
    ),
    list(
      arg = "attention",
      attr = "attention",
      valid = "bounce",
      invalid = "blink"
    ),
    list(arg = "variant", attr = "variant", valid = "warning", invalid = "info")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_badge,
      c(list("Beta"), stats::setNames(list(case$valid), case$arg))
    )

    expect_exact_html(
      render_html(valid_tag),
      c(sprintf('<wa-badge %s="%s">Beta</wa-badge>', case$attr, case$valid))
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_badge,
        c(list("Beta"), stats::setNames(list(case$invalid), case$arg))
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

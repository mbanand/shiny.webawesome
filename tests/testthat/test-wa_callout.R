test_that("wa_callout defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_callout("Heads up")),
    c("<wa-callout>Heads up</wa-callout>")
  )
})

test_that("wa_callout override render includes attrs and icon slot", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_callout(
        "Heads up",
        id = "callout",
        appearance = "outlined",
        dir = "rtl",
        lang = "en",
        size = "large",
        variant = "danger",
        icon = "Icon"
      )
    ),
    c(
      paste0(
        '<wa-callout id="callout" appearance="outlined" dir="rtl" ',
        'lang="en" size="large" variant="danger">'
      ),
      "  Heads up",
      '  <span slot="icon">Icon</span>',
      "</wa-callout>"
    )
  )
})

test_that("wa_callout enum args validate exactly", {
  enum_cases <- list(
    list(
      arg = "appearance",
      attr = "appearance",
      valid = "plain",
      invalid = "glass"
    ),
    list(arg = "size", attr = "size", valid = "small", invalid = "tiny"),
    list(arg = "variant", attr = "variant", valid = "success", invalid = "info")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_callout,
      c(list("Heads up"), stats::setNames(list(case$valid), case$arg))
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf(
          '<wa-callout %s="%s">Heads up</wa-callout>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_callout,
        c(list("Heads up"), stats::setNames(list(case$invalid), case$arg))
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

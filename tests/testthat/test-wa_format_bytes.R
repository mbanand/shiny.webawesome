test_that("wa_format_bytes defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_format_bytes()),
    c("<wa-format-bytes></wa-format-bytes>")
  )
})

test_that("wa_format_bytes override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_format_bytes(
        id = "bytes",
        value = 2048,
        dir = "rtl",
        display = "long",
        lang = "en",
        unit = "bit"
      )
    ),
    c(
      paste0(
        '<wa-format-bytes id="bytes" value="2048" dir="rtl" ',
        'display="long" lang="en" unit="bit"></wa-format-bytes>'
      )
    )
  )
})

test_that("wa_format_bytes enum arguments validate exactly", {
  enum_cases <- list(
    list(arg = "display", attr = "display", valid = "narrow", invalid = "wide"),
    list(arg = "unit", attr = "unit", valid = "byte", invalid = "kilobyte")
  )

  for (case in enum_cases) {
    tag <- do.call(
      shiny.webawesome:::wa_format_bytes,
      stats::setNames(list(case$valid), case$arg)
    )

    expect_exact_html(
      render_html(tag),
      c(
        sprintf(
          '<wa-format-bytes %s="%s"></wa-format-bytes>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_format_bytes,
        stats::setNames(list(case$invalid), case$arg)
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

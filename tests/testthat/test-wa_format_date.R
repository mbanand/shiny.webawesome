test_that("wa_format_date defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_format_date()),
    c("<wa-format-date></wa-format-date>")
  )
})

test_that("wa_format_date override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_format_date(
        id = "date",
        date = "2026-03-28T12:34:56Z",
        day = "2-digit",
        dir = "rtl",
        era = "short",
        hour = "numeric",
        hour_format = "24",
        lang = "en",
        minute = "2-digit",
        month = "long",
        second = "2-digit",
        time_zone = "UTC",
        time_zone_name = "short",
        weekday = "long",
        year = "numeric"
      )
    ),
    c(
      paste0(
        '<wa-format-date id="date" date="2026-03-28T12:34:56Z" ',
        'day="2-digit" dir="rtl" era="short" hour="numeric" ',
        'hour-format="24" lang="en" minute="2-digit" month="long" ',
        'second="2-digit" time-zone="UTC" time-zone-name="short" ',
        'weekday="long" year="numeric"></wa-format-date>'
      )
    )
  )
})

test_that("wa_format_date enum arguments validate exactly", {
  enum_cases <- list(
    list(arg = "day", attr = "day", valid = "numeric", invalid = "wide"),
    list(arg = "era", attr = "era", valid = "narrow", invalid = "full"),
    list(arg = "hour", attr = "hour", valid = "2-digit", invalid = "full"),
    list(
      arg = "hour_format",
      attr = "hour-format",
      valid = "12",
      invalid = "36"
    ),
    list(arg = "minute", attr = "minute", valid = "numeric", invalid = "full"),
    list(arg = "month", attr = "month", valid = "short", invalid = "wide"),
    list(arg = "second", attr = "second", valid = "2-digit", invalid = "full"),
    list(
      arg = "time_zone_name",
      attr = "time-zone-name",
      valid = "long",
      invalid = "medium"
    ),
    list(arg = "weekday", attr = "weekday", valid = "short", invalid = "wide"),
    list(arg = "year", attr = "year", valid = "2-digit", invalid = "full")
  )

  for (case in enum_cases) {
    tag <- do.call(
      shiny.webawesome:::wa_format_date,
      stats::setNames(list(case$valid), case$arg)
    )

    expect_exact_html(
      render_html(tag),
      c(
        sprintf(
          '<wa-format-date %s="%s"></wa-format-date>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_format_date,
        stats::setNames(list(case$invalid), case$arg)
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

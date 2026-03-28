test_that("wa_format_number defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_format_number()),
    c("<wa-format-number></wa-format-number>")
  )
})

test_that("wa_format_number override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_format_number(
        id = "number",
        value = 1234.56,
        currency = "EUR",
        currency_display = "code",
        dir = "rtl",
        lang = "de",
        maximum_fraction_digits = 2,
        maximum_significant_digits = 6,
        minimum_fraction_digits = 1,
        minimum_integer_digits = 2,
        minimum_significant_digits = 3,
        type = "currency",
        without_grouping = TRUE
      )
    ),
    c(
      paste0(
        '<wa-format-number id="number" value="1234.56" currency="EUR" ',
        'currency-display="code" dir="rtl" lang="de" ',
        'maximum-fraction-digits="2" maximum-significant-digits="6" ',
        'minimum-fraction-digits="1" minimum-integer-digits="2" ',
        'minimum-significant-digits="3" type="currency" ',
        "without-grouping></wa-format-number>"
      )
    )
  )
})

test_that("wa_format_number without_grouping validates and renders correctly", {
  default_html <- render_html(shiny.webawesome:::wa_format_number())

  expect_exact_html(
    render_html(shiny.webawesome:::wa_format_number(without_grouping = TRUE)),
    c("<wa-format-number without-grouping></wa-format-number>")
  )

  expect_equal(
    render_html(shiny.webawesome:::wa_format_number(without_grouping = FALSE)),
    default_html
  )

  expect_equal(
    render_html(shiny.webawesome:::wa_format_number(without_grouping = NULL)),
    default_html
  )

  expect_error(
    shiny.webawesome:::wa_format_number(without_grouping = "no"),
    "`without_grouping` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

test_that("wa_format_number enum arguments validate exactly", {
  enum_cases <- list(
    list(
      arg = "currency_display",
      attr = "currency-display",
      valid = "symbol",
      invalid = "long"
    ),
    list(arg = "type", attr = "type", valid = "percent", invalid = "scientific")
  )

  for (case in enum_cases) {
    tag <- do.call(
      shiny.webawesome:::wa_format_number,
      stats::setNames(list(case$valid), case$arg)
    )

    expect_exact_html(
      render_html(tag),
      c(
        sprintf(
          '<wa-format-number %s="%s"></wa-format-number>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_format_number,
        stats::setNames(list(case$invalid), case$arg)
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

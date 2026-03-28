test_that("wa_option defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_option("Option")),
    c("<wa-option>Option</wa-option>")
  )
})

test_that("wa_option override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_option(
        "Option",
        id = "option",
        value = "a",
        disabled = TRUE,
        label = "Option A",
        dir = "rtl",
        lang = "en",
        selected = TRUE,
        end = "End",
        start = "Start"
      )
    ),
    c(
      paste0(
        '<wa-option id="option" value="a" disabled label="Option A" ',
        'dir="rtl" lang="en" selected>'
      ),
      "  Option",
      '  <span slot="end">End</span>',
      '  <span slot="start">Start</span>',
      "</wa-option>"
    )
  )
})

test_that("wa_option boolean args validate and render correctly", {
  default_html <- render_html(shiny.webawesome:::wa_option("Option"))

  for (arg_name in c("disabled", "selected")) {
    tag <- do.call(
      shiny.webawesome:::wa_option,
      c(list("Option"), stats::setNames(list(TRUE), arg_name))
    )

    expect_exact_html(
      render_html(tag),
      c(sprintf("<wa-option %s>Option</wa-option>", arg_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_option,
      c(list("Option"), stats::setNames(list(FALSE), arg_name))
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_option,
      c(list("Option"), stats::setNames(list(NULL), arg_name))
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_option,
        c(list("Option"), stats::setNames(list("yes"), arg_name))
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

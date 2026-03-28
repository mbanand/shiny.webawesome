test_that("wa_tag defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_tag("Tag")),
    c("<wa-tag>Tag</wa-tag>")
  )
})

test_that("wa_tag override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_tag(
        "Tag",
        id = "tag",
        appearance = "filled",
        dir = "rtl",
        lang = "en",
        pill = TRUE,
        size = "large",
        variant = "brand",
        with_remove = TRUE
      )
    ),
    c(
      paste0(
        '<wa-tag id="tag" appearance="filled" dir="rtl" lang="en" ',
        'pill size="large" variant="brand" with-remove>Tag</wa-tag>'
      )
    )
  )
})

test_that("wa_tag boolean and enum args validate exactly", {
  expect_error(
    shiny.webawesome:::wa_tag("Tag", with_remove = "yes"),
    "`with_remove` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )

  enum_cases <- list(
    list(
      arg = "appearance",
      attr = "appearance",
      valid = "outlined",
      invalid = "glass"
    ),
    list(arg = "size", attr = "size", valid = "small", invalid = "tiny"),
    list(arg = "variant", attr = "variant", valid = "warning", invalid = "info")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_tag,
      c(list("Tag"), stats::setNames(list(case$valid), case$arg))
    )

    expect_exact_html(
      render_html(valid_tag),
      c(sprintf('<wa-tag %s="%s">Tag</wa-tag>', case$attr, case$valid))
    )
  }
})

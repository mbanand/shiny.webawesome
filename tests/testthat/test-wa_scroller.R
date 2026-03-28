test_that("wa_scroller defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_scroller("Content")),
    c("<wa-scroller>Content</wa-scroller>")
  )
})

test_that("wa_scroller override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_scroller(
        "Content",
        id = "scroller",
        dir = "rtl",
        lang = "en",
        orientation = "vertical",
        without_scrollbar = TRUE,
        without_shadow = TRUE
      )
    ),
    c(
      paste0(
        '<wa-scroller id="scroller" dir="rtl" lang="en" ',
        'orientation="vertical" without-scrollbar without-shadow>Content',
        "</wa-scroller>"
      )
    )
  )
})

test_that("wa_scroller boolean args validate and render correctly", {
  default_html <- render_html(shiny.webawesome:::wa_scroller("Content"))
  boolean_args <- c(
    without_scrollbar = "without-scrollbar",
    without_shadow = "without-shadow"
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    tag <- do.call(
      shiny.webawesome:::wa_scroller,
      c(list("Content"), stats::setNames(list(TRUE), arg_name))
    )

    expect_exact_html(
      render_html(tag),
      c(sprintf("<wa-scroller %s>Content</wa-scroller>", attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_scroller,
      c(list("Content"), stats::setNames(list(FALSE), arg_name))
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_scroller,
      c(list("Content"), stats::setNames(list(NULL), arg_name))
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_scroller,
        c(list("Content"), stats::setNames(list("yes"), arg_name))
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_scroller orientation enum validates exactly", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_scroller("Content", orientation = "horizontal")
    ),
    c('<wa-scroller orientation="horizontal">Content</wa-scroller>')
  )

  expect_error(
    shiny.webawesome:::wa_scroller("Content", orientation = "diagonal"),
    "`orientation` must be one of ",
    fixed = TRUE
  )
})

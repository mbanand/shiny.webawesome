test_that("wa_zoomable_frame defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_zoomable_frame()),
    c("<wa-zoomable-frame></wa-zoomable-frame>")
  )
})

test_that("wa_zoomable_frame override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_zoomable_frame(
        id = "frame",
        allowfullscreen = TRUE,
        dir = "rtl",
        lang = "en",
        loading = "lazy",
        referrerpolicy = "origin",
        sandbox = "allow-scripts",
        src = "https://example.com",
        srcdoc = "<p>Inline</p>",
        without_controls = TRUE,
        without_interaction = TRUE,
        zoom = 1.5,
        zoom_levels = "100% 150%",
        zoom_in_icon = "Plus",
        zoom_out_icon = "Minus"
      )
    ),
    c(
      paste0(
        '<wa-zoomable-frame id="frame" allowfullscreen dir="rtl" lang="en" ',
        'loading="lazy" referrerpolicy="origin" sandbox="allow-scripts" ',
        'src="https://example.com" srcdoc="&lt;p&gt;Inline&lt;/p&gt;" ',
        'without-controls without-interaction zoom="1.5" ',
        'zoom-levels="100% 150%">'
      ),
      '  <span slot="zoom-in-icon">Plus</span>',
      '  <span slot="zoom-out-icon">Minus</span>',
      "</wa-zoomable-frame>"
    )
  )
})

test_that("wa_zoomable_frame boolean args validate and render correctly", {
  default_html <- render_html(shiny.webawesome:::wa_zoomable_frame())
  boolean_args <- c(
    allowfullscreen = "allowfullscreen",
    without_controls = "without-controls",
    without_interaction = "without-interaction"
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    tag <- do.call(
      shiny.webawesome:::wa_zoomable_frame,
      stats::setNames(list(TRUE), arg_name)
    )

    expect_exact_html(
      render_html(tag),
      c(sprintf("<wa-zoomable-frame %s></wa-zoomable-frame>", attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_zoomable_frame,
      stats::setNames(list(FALSE), arg_name)
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_zoomable_frame,
      stats::setNames(list(NULL), arg_name)
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_zoomable_frame,
        stats::setNames(list("yes"), arg_name)
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_zoomable_frame loading enum validates exactly", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_zoomable_frame(loading = "eager")),
    c('<wa-zoomable-frame loading="eager"></wa-zoomable-frame>')
  )

  expect_error(
    shiny.webawesome:::wa_zoomable_frame(loading = "auto"),
    "`loading` must be one of ",
    fixed = TRUE
  )
})

test_that("wa_resize_observer defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_resize_observer("Tracked")),
    c("<wa-resize-observer>Tracked</wa-resize-observer>")
  )
})

test_that("wa_resize_observer override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_resize_observer(
        "Tracked",
        id = "observer",
        disabled = TRUE,
        dir = "rtl",
        lang = "en"
      )
    ),
    c(paste0(
      '<wa-resize-observer id="observer" disabled dir="rtl" lang="en">',
      "Tracked</wa-resize-observer>"
    ))
  )
})

test_that("wa_resize_observer disabled validates and renders correctly", {
  default_html <- render_html(shiny.webawesome:::wa_resize_observer("Tracked"))

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_resize_observer("Tracked", disabled = TRUE)
    ),
    c("<wa-resize-observer disabled>Tracked</wa-resize-observer>")
  )

  expect_equal(
    render_html(
      shiny.webawesome:::wa_resize_observer("Tracked", disabled = FALSE)
    ),
    default_html
  )

  expect_equal(
    render_html(
      shiny.webawesome:::wa_resize_observer("Tracked", disabled = NULL)
    ),
    default_html
  )

  expect_error(
    shiny.webawesome:::wa_resize_observer("Tracked", disabled = "yes"),
    "`disabled` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

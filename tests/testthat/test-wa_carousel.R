test_that("wa_carousel requires input_id", {
  expect_error(
    shiny.webawesome:::wa_carousel(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_carousel defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_carousel(
        input_id = "carousel",
        htmltools::tag("wa-carousel-item", "Slide 1"),
        htmltools::tag("wa-carousel-item", "Slide 2")
      )
    ),
    c(
      '<wa-carousel id="carousel">',
      "  <wa-carousel-item>Slide 1</wa-carousel-item>",
      "  <wa-carousel-item>Slide 2</wa-carousel-item>",
      "</wa-carousel>"
    )
  )
})

test_that("wa_carousel override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_carousel(
        input_id = "carousel",
        htmltools::tag("wa-carousel-item", "Slide 1"),
        autoplay = TRUE,
        autoplay_interval = 4000,
        current_slide = 2,
        dir = "rtl",
        lang = "en",
        loop = TRUE,
        mouse_dragging = TRUE,
        navigation = TRUE,
        orientation = "vertical",
        pagination = TRUE,
        slides = 3,
        slides_per_move = 2,
        slides_per_page = 1,
        next_icon = "Next",
        previous_icon = "Previous"
      )
    ),
    c(
      paste0(
        '<wa-carousel id="carousel" autoplay autoplay-interval="4000" ',
        'currentSlide="2" dir="rtl" lang="en" loop mouse-dragging ',
        'navigation orientation="vertical" pagination slides="3" ',
        'slides-per-move="2" slides-per-page="1">'
      ),
      "  <wa-carousel-item>Slide 1</wa-carousel-item>",
      '  <span slot="next-icon">Next</span>',
      '  <span slot="previous-icon">Previous</span>',
      "</wa-carousel>"
    )
  )
})

test_that("wa_carousel boolean args validate and render correctly", {
  boolean_args <- c(
    autoplay = "autoplay",
    loop = "loop",
    mouse_dragging = "mouse-dragging",
    navigation = "navigation",
    pagination = "pagination"
  )

  default_html <- render_html(
    shiny.webawesome:::wa_carousel(
      input_id = "carousel",
      htmltools::tag("wa-carousel-item", "Slide 1")
    )
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_carousel,
      c(
        list(
          input_id = "carousel",
          htmltools::tag("wa-carousel-item", "Slide 1")
        ),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(
        sprintf('<wa-carousel id="carousel" %s>', attr_name),
        "  <wa-carousel-item>Slide 1</wa-carousel-item>",
        "</wa-carousel>"
      )
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_carousel,
      c(
        list(
          input_id = "carousel",
          htmltools::tag("wa-carousel-item", "Slide 1")
        ),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_carousel,
      c(
        list(
          input_id = "carousel",
          htmltools::tag("wa-carousel-item", "Slide 1")
        ),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_carousel,
        c(
          list(
            input_id = "carousel",
            htmltools::tag("wa-carousel-item", "Slide 1")
          ),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_carousel orientation enum validates exactly", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_carousel(
        input_id = "carousel",
        htmltools::tag("wa-carousel-item", "Slide 1"),
        orientation = "horizontal"
      )
    ),
    c(
      '<wa-carousel id="carousel" orientation="horizontal">',
      "  <wa-carousel-item>Slide 1</wa-carousel-item>",
      "</wa-carousel>"
    )
  )

  expect_error(
    shiny.webawesome:::wa_carousel(
      input_id = "carousel",
      htmltools::tag("wa-carousel-item", "Slide 1"),
      orientation = "diagonal"
    ),
    "`orientation` must be one of ",
    fixed = TRUE
  )
})

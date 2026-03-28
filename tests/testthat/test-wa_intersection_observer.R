test_that("wa_intersection_observer defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_intersection_observer("Tracked")),
    c("<wa-intersection-observer>Tracked</wa-intersection-observer>")
  )
})

test_that("wa_intersection_observer override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_intersection_observer(
        "Tracked",
        id = "observer",
        disabled = TRUE,
        dir = "rtl",
        intersect_class = "in-view",
        lang = "en",
        once = TRUE,
        root = "viewport",
        root_margin = "8px",
        threshold = "0 0.5 1"
      )
    ),
    c(
      paste0(
        '<wa-intersection-observer id="observer" disabled dir="rtl" ',
        'intersect-class="in-view" lang="en" once root="viewport" ',
        'root-margin="8px" threshold="0 0.5 1">',
        "Tracked</wa-intersection-observer>"
      )
    )
  )
})

test_that(
  "wa_intersection_observer boolean args validate and render correctly",
  {
    default_html <- render_html(
      shiny.webawesome:::wa_intersection_observer("Tracked")
    )

    for (arg_name in c("disabled", "once")) {
      tag <- do.call(
        shiny.webawesome:::wa_intersection_observer,
        c(list("Tracked"), stats::setNames(list(TRUE), arg_name))
      )

      expect_exact_html(
        render_html(tag),
        c(
          sprintf(
            "<wa-intersection-observer %s>Tracked</wa-intersection-observer>",
            arg_name
          )
        )
      )

      false_tag <- do.call(
        shiny.webawesome:::wa_intersection_observer,
        c(list("Tracked"), stats::setNames(list(FALSE), arg_name))
      )
      expect_equal(render_html(false_tag), default_html)

      null_tag <- do.call(
        shiny.webawesome:::wa_intersection_observer,
        c(list("Tracked"), stats::setNames(list(NULL), arg_name))
      )
      expect_equal(render_html(null_tag), default_html)

      expect_error(
        do.call(
          shiny.webawesome:::wa_intersection_observer,
          c(list("Tracked"), stats::setNames(list("yes"), arg_name))
        ),
        sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
        fixed = TRUE
      )
    }
  }
)

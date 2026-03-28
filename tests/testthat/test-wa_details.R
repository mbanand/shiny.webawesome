test_that("wa_details requires input_id", {
  expect_error(
    shiny.webawesome:::wa_details(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_details defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_details("details", "Details body")
    ),
    c('<wa-details id="details">Details body</wa-details>')
  )
})

test_that("wa_details override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_details(
        "details",
        "Details body",
        disabled = TRUE,
        name = "group",
        appearance = "filled",
        dir = "rtl",
        icon_placement = "start",
        lang = "en",
        open = TRUE,
        summary = "More",
        collapse_icon = "Collapse",
        expand_icon = "Expand",
        summary_slot = "Summary slot"
      )
    ),
    c(
      paste0(
        '<wa-details id="details" disabled name="group" appearance="filled" ',
        'dir="rtl" icon-placement="start" lang="en" open summary="More">'
      ),
      "  Details body",
      '  <span slot="collapse-icon">Collapse</span>',
      '  <span slot="expand-icon">Expand</span>',
      '  <span slot="summary">Summary slot</span>',
      "</wa-details>"
    )
  )
})

test_that("wa_details boolean args validate and render correctly", {
  boolean_args <- c(
    disabled = "disabled",
    open = "open"
  )

  default_html <- render_html(
    shiny.webawesome:::wa_details("details", "Details body")
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_details,
      c(
        list(input_id = "details", "Details body"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(
        sprintf(
          '<wa-details id="details" %s>Details body</wa-details>',
          attr_name
        )
      )
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_details,
      c(
        list(input_id = "details", "Details body"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_details,
      c(
        list(input_id = "details", "Details body"),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_details,
        c(
          list(input_id = "details", "Details body"),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_details enum args validate exactly", {
  enum_cases <- list(
    list(
      arg = "appearance",
      attr = "appearance",
      valid = "plain",
      invalid = "glass"
    ),
    list(
      arg = "icon_placement",
      attr = "icon-placement",
      valid = "end",
      invalid = "left"
    )
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_details,
      c(
        list(input_id = "details", "Details body"),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf(
          '<wa-details id="details" %s="%s">Details body</wa-details>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_details,
        c(
          list(input_id = "details", "Details body"),
          stats::setNames(list(case$invalid), case$arg)
        )
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

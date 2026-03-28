test_that("wa_popup defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_popup("Popup body")),
    c("<wa-popup>Popup body</wa-popup>")
  )
})

test_that("wa_popup override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_popup(
        "Popup body",
        id = "popup",
        active = TRUE,
        anchor = "trigger",
        arrow = TRUE,
        arrow_padding = 10,
        arrow_placement = "center",
        auto_size = "both",
        auto_size_padding = 4,
        auto_size_boundary = "viewportBoundary",
        boundary = "scroll",
        dir = "rtl",
        distance = 12,
        flip = TRUE,
        flip_fallback_placements = "top bottom",
        flip_fallback_strategy = "initial",
        flip_padding = 6,
        flip_boundary = "clipBoundary",
        hover_bridge = TRUE,
        lang = "en",
        placement = "bottom-start",
        shift = TRUE,
        shift_padding = 3,
        shift_boundary = "shiftBoundary",
        skidding = 5,
        sync = "width",
        anchor_slot = "Anchor slot"
      )
    ),
    c(
      paste0(
        '<wa-popup id="popup" active anchor="trigger" arrow ',
        'arrow-padding="10" arrow-placement="center" auto-size="both" ',
        'auto-size-padding="4" autoSizeBoundary="viewportBoundary" ',
        'boundary="scroll" dir="rtl" distance="12" flip ',
        'flip-fallback-placements="top bottom" ',
        'flip-fallback-strategy="initial" flip-padding="6" ',
        'flipBoundary="clipBoundary" hover-bridge lang="en" ',
        'placement="bottom-start" shift shift-padding="3" ',
        'shiftBoundary="shiftBoundary" skidding="5" sync="width">'
      ),
      "  Popup body",
      '  <span slot="anchor">Anchor slot</span>',
      "</wa-popup>"
    )
  )
})

test_that("wa_popup boolean args validate and render correctly", {
  default_html <- render_html(shiny.webawesome:::wa_popup("Popup body"))
  boolean_args <- c(
    active = "active",
    arrow = "arrow",
    flip = "flip",
    hover_bridge = "hover-bridge",
    shift = "shift"
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    tag <- do.call(
      shiny.webawesome:::wa_popup,
      c(list("Popup body"), stats::setNames(list(TRUE), arg_name))
    )

    expect_exact_html(
      render_html(tag),
      c(sprintf("<wa-popup %s>Popup body</wa-popup>", attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_popup,
      c(list("Popup body"), stats::setNames(list(FALSE), arg_name))
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_popup,
      c(list("Popup body"), stats::setNames(list(NULL), arg_name))
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_popup,
        c(list("Popup body"), stats::setNames(list("yes"), arg_name))
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_popup enum arguments validate exactly", {
  enum_cases <- list(
    list(
      arg = "arrow_placement",
      attr = "arrow-placement",
      valid = "anchor",
      invalid = "middle"
    ),
    list(
      arg = "auto_size",
      attr = "auto-size",
      valid = "vertical",
      invalid = "auto"
    ),
    list(
      arg = "boundary",
      attr = "boundary",
      valid = "viewport",
      invalid = "page"
    ),
    list(
      arg = "flip_fallback_strategy",
      attr = "flip-fallback-strategy",
      valid = "best-fit",
      invalid = "nearest"
    ),
    list(
      arg = "placement",
      attr = "placement",
      valid = "top-end",
      invalid = "center"
    ),
    list(arg = "sync", attr = "sync", valid = "both", invalid = "auto")
  )

  for (case in enum_cases) {
    tag <- do.call(
      shiny.webawesome:::wa_popup,
      c(list("Popup body"), stats::setNames(list(case$valid), case$arg))
    )

    expect_exact_html(
      render_html(tag),
      c(
        sprintf(
          '<wa-popup %s="%s">Popup body</wa-popup>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_popup,
        c(list("Popup body"), stats::setNames(list(case$invalid), case$arg))
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

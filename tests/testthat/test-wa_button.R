test_that("wa_button requires input_id", {
  expect_error(
    shiny.webawesome:::wa_button(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_button defaults render the minimal action wrapper", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_button("button", "Run")
    ),
    c('<wa-button id="button">Run</wa-button>')
  )
})

test_that("wa_button override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_button(
        "button",
        "Run",
        disabled = TRUE,
        appearance = "filled",
        loading = TRUE,
        size = "small",
        title = "Launch",
        type = "submit",
        variant = "brand",
        with_caret = TRUE,
        end = "After",
        start = "Before"
      )
    ),
    c(
      paste0(
        '<wa-button id="button" disabled appearance="filled" loading ',
        'size="small" title="Launch" type="submit" variant="brand" ',
        "with-caret>"
      ),
      "  Run",
      '  <span slot="end">After</span>',
      '  <span slot="start">Before</span>',
      "</wa-button>"
    )
  )
})

test_that("wa_button includes package-level class and style attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_button(
        "button",
        "Run",
        class = "wa-gap-s button-shell",
        style = "margin-inline: 1rem;"
      )
    ),
    c(
      paste0(
        '<wa-button id="button" class="wa-gap-s button-shell" ',
        'style="margin-inline: 1rem;">Run</wa-button>'
      )
    )
  )
})

test_that("wa_button boolean args validate and render correctly", {
  boolean_args <- c(
    disabled = "disabled",
    formnovalidate = "formnovalidate",
    loading = "loading",
    pill = "pill",
    with_caret = "with-caret"
  )

  default_html <- render_html(shiny.webawesome:::wa_button("button", "Run"))

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    true_tag <- do.call(
      shiny.webawesome:::wa_button,
      c(
        list(input_id = "button", "Run"),
        stats::setNames(list(TRUE), arg_name)
      )
    )
    expect_exact_html(
      render_html(true_tag),
      c(sprintf('<wa-button id="button" %s>Run</wa-button>', attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_button,
      c(
        list(input_id = "button", "Run"),
        stats::setNames(list(FALSE), arg_name)
      )
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_button,
      c(
        list(input_id = "button", "Run"),
        stats::setNames(list(NULL), arg_name)
      )
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_button,
        c(
          list(input_id = "button", "Run"),
          stats::setNames(list("yes"), arg_name)
        )
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_button enum arguments validate exactly", {
  enum_cases <- list(
    list(
      arg = "appearance",
      attr = "appearance",
      valid = "plain",
      invalid = "invalid"
    ),
    list(
      arg = "formenctype",
      attr = "formenctype",
      valid = "text/plain",
      invalid = "bad/type"
    ),
    list(
      arg = "formmethod",
      attr = "formmethod",
      valid = "post",
      invalid = "patch"
    ),
    list(arg = "size", attr = "size", valid = "large", invalid = "tiny"),
    list(arg = "target", attr = "target", valid = "_blank", invalid = "_new"),
    list(arg = "type", attr = "type", valid = "reset", invalid = "menu"),
    list(arg = "variant", attr = "variant", valid = "warning", invalid = "info")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_button,
      c(
        list(input_id = "button", "Run"),
        stats::setNames(list(case$valid), case$arg)
      )
    )

    expect_exact_html(
      render_html(valid_tag),
      c(
        sprintf(
          '<wa-button id="button" %s="%s">Run</wa-button>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_button,
        c(
          list(input_id = "button", "Run"),
          stats::setNames(list(case$invalid), case$arg)
        )
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

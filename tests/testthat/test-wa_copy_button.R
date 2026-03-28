test_that("wa_copy_button defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_copy_button("Copy")),
    c("<wa-copy-button>Copy</wa-copy-button>")
  )
})

test_that("wa_copy_button override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_copy_button(
        "Copy",
        id = "copy_button",
        value = "Copy me",
        disabled = TRUE,
        copy_label = "Copy now",
        error_label = "Failed",
        feedback_duration = 2000,
        from = "target.value",
        success_label = "Copied",
        tooltip_placement = "left",
        copy_icon = "Copy icon",
        error_icon = "Error icon",
        success_icon = "Success icon"
      )
    ),
    c(
      paste0(
        '<wa-copy-button id="copy_button" value="Copy me" disabled ',
        'copy-label="Copy now" error-label="Failed" ',
        'feedback-duration="2000" from="target.value" ',
        'success-label="Copied" tooltip-placement="left">'
      ),
      "  Copy",
      '  <span slot="copy-icon">Copy icon</span>',
      '  <span slot="error-icon">Error icon</span>',
      '  <span slot="success-icon">Success icon</span>',
      "</wa-copy-button>"
    )
  )
})

test_that("wa_copy_button boolean and enum args validate exactly", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_copy_button("Copy", disabled = TRUE)),
    c("<wa-copy-button disabled>Copy</wa-copy-button>")
  )

  expect_error(
    shiny.webawesome:::wa_copy_button("Copy", disabled = "yes"),
    "`disabled` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )

  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_copy_button(
        "Copy",
        tooltip_placement = "right"
      )
    ),
    c('<wa-copy-button tooltip-placement="right">Copy</wa-copy-button>')
  )

  expect_error(
    shiny.webawesome:::wa_copy_button("Copy", tooltip_placement = "center"),
    "`tooltip_placement` must be one of ",
    fixed = TRUE
  )
})

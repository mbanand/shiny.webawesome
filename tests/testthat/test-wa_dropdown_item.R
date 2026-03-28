test_that("wa_dropdown_item defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_dropdown_item("Item")),
    c("<wa-dropdown-item>Item</wa-dropdown-item>")
  )
})

test_that("wa_dropdown_item override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_dropdown_item(
        "Item",
        id = "item",
        value = "save",
        checked = TRUE,
        disabled = TRUE,
        dir = "rtl",
        lang = "en",
        submenu_open = TRUE,
        type = "checkbox",
        variant = "danger",
        details = "Ctrl+S",
        icon = "Disk",
        submenu = "Nested"
      )
    ),
    c(
      paste0(
        '<wa-dropdown-item id="item" value="save" checked disabled dir="rtl" ',
        'lang="en" submenuOpen type="checkbox" variant="danger">'
      ),
      "  Item",
      '  <span slot="details">Ctrl+S</span>',
      '  <span slot="icon">Disk</span>',
      '  <span slot="submenu">Nested</span>',
      "</wa-dropdown-item>"
    )
  )
})

test_that("wa_dropdown_item boolean args validate and render correctly", {
  default_html <- render_html(shiny.webawesome:::wa_dropdown_item("Item"))
  boolean_args <- c(
    checked = "checked",
    disabled = "disabled",
    submenu_open = "submenuOpen"
  )

  for (arg_name in names(boolean_args)) {
    attr_name <- boolean_args[[arg_name]]

    tag <- do.call(
      shiny.webawesome:::wa_dropdown_item,
      c(list("Item"), stats::setNames(list(TRUE), arg_name))
    )

    expect_exact_html(
      render_html(tag),
      c(sprintf("<wa-dropdown-item %s>Item</wa-dropdown-item>", attr_name))
    )

    false_tag <- do.call(
      shiny.webawesome:::wa_dropdown_item,
      c(list("Item"), stats::setNames(list(FALSE), arg_name))
    )
    expect_equal(render_html(false_tag), default_html)

    null_tag <- do.call(
      shiny.webawesome:::wa_dropdown_item,
      c(list("Item"), stats::setNames(list(NULL), arg_name))
    )
    expect_equal(render_html(null_tag), default_html)

    expect_error(
      do.call(
        shiny.webawesome:::wa_dropdown_item,
        c(list("Item"), stats::setNames(list("yes"), arg_name))
      ),
      sprintf("`%s` must be TRUE, FALSE, or NULL.", arg_name),
      fixed = TRUE
    )
  }
})

test_that("wa_dropdown_item enum arguments validate exactly", {
  enum_cases <- list(
    list(arg = "type", attr = "type", valid = "normal", invalid = "radio"),
    list(
      arg = "variant",
      attr = "variant",
      valid = "default",
      invalid = "warning"
    )
  )

  for (case in enum_cases) {
    tag <- do.call(
      shiny.webawesome:::wa_dropdown_item,
      c(list("Item"), stats::setNames(list(case$valid), case$arg))
    )

    expect_exact_html(
      render_html(tag),
      c(
        sprintf(
          '<wa-dropdown-item %s="%s">Item</wa-dropdown-item>',
          case$attr,
          case$valid
        )
      )
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_dropdown_item,
        c(list("Item"), stats::setNames(list(case$invalid), case$arg))
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

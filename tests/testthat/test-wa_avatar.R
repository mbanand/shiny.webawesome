test_that("wa_avatar defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_avatar()),
    c("<wa-avatar></wa-avatar>")
  )
})

test_that("wa_avatar override render includes attrs and icon slot", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_avatar(
        id = "avatar",
        label = "Avatar",
        dir = "rtl",
        image = "avatar.png",
        initials = "AV",
        lang = "en",
        loading = "lazy",
        shape = "square",
        icon = "Icon"
      )
    ),
    c(
      paste0(
        '<wa-avatar id="avatar" label="Avatar" dir="rtl" ',
        'image="avatar.png" initials="AV" lang="en" loading="lazy" ',
        'shape="square">'
      ),
      '  <span slot="icon">Icon</span>',
      "</wa-avatar>"
    )
  )
})

test_that("wa_avatar enum args validate exactly", {
  enum_cases <- list(
    list(arg = "loading", attr = "loading", valid = "eager", invalid = "auto"),
    list(arg = "shape", attr = "shape", valid = "rounded", invalid = "hex")
  )

  for (case in enum_cases) {
    valid_tag <- do.call(
      shiny.webawesome:::wa_avatar,
      stats::setNames(list(case$valid), case$arg)
    )

    expect_exact_html(
      render_html(valid_tag),
      c(sprintf('<wa-avatar %s="%s"></wa-avatar>', case$attr, case$valid))
    )

    expect_error(
      do.call(
        shiny.webawesome:::wa_avatar,
        stats::setNames(list(case$invalid), case$arg)
      ),
      sprintf("`%s` must be one of ", case$arg),
      fixed = TRUE
    )
  }
})

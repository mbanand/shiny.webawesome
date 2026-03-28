test_that("wa_icon defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_icon()),
    c("<wa-icon></wa-icon>")
  )
})

test_that("wa_icon override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_icon(
        id = "icon",
        label = "Settings",
        name = "gear",
        animation = "spin",
        auto_width = TRUE,
        family = "classic",
        flip = "both",
        library = "default",
        rotate = 90,
        src = "/icon.svg",
        swap_opacity = TRUE,
        variant = "solid"
      )
    ),
    c(
      paste0(
        '<wa-icon id="icon" label="Settings" name="gear" animation="spin" ',
        'auto-width family="classic" flip="both" library="default" ',
        'rotate="90" src="/icon.svg" swap-opacity variant="solid"></wa-icon>'
      )
    )
  )
})

test_that("wa_icon boolean attrs validate exactly", {
  expect_error(
    shiny.webawesome:::wa_icon(auto_width = "yes"),
    "`auto_width` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

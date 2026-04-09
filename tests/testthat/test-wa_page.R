test_that("wa_page defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_page()),
    c("<wa-page></wa-page>")
  )
})

test_that("wa_page override render includes attrs and named slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_page(
        "Main content",
        id = "page",
        class = "shell",
        style = "min-height: 100vh;",
        disable_navigation_toggle = TRUE,
        mobile_breakpoint = "50em",
        nav_open = TRUE,
        navigation_placement = "end",
        view = "mobile",
        aside = "Aside",
        banner = "Banner",
        footer = "Footer",
        header = "Header",
        main_footer = "Main footer",
        main_header = "Main header",
        menu = "Menu",
        navigation = "Navigation",
        navigation_footer = "Navigation footer",
        navigation_header = "Navigation header",
        navigation_toggle = "Toggle",
        navigation_toggle_icon = "Toggle icon",
        skip_to_content = "Skip",
        subheader = "Subheader"
      )
    ),
    c(
      paste0(
        '<wa-page id="page" class="shell" style="min-height: 100vh;" ',
        'disable-navigation-toggle mobile-breakpoint="50em" nav-open ',
        'navigation-placement="end" view="mobile">'
      ),
      "  Main content",
      '  <span slot="aside">Aside</span>',
      '  <span slot="banner">Banner</span>',
      '  <span slot="footer">Footer</span>',
      '  <span slot="header">Header</span>',
      '  <span slot="main-footer">Main footer</span>',
      '  <span slot="main-header">Main header</span>',
      '  <span slot="menu">Menu</span>',
      '  <span slot="navigation">Navigation</span>',
      '  <span slot="navigation-footer">Navigation footer</span>',
      '  <span slot="navigation-header">Navigation header</span>',
      '  <span slot="navigation-toggle">Toggle</span>',
      '  <span slot="navigation-toggle-icon">Toggle icon</span>',
      '  <span slot="skip-to-content">Skip</span>',
      '  <span slot="subheader">Subheader</span>',
      "</wa-page>"
    )
  )
})

test_that("wa_page enum args validate exactly", {
  expect_error(
    shiny.webawesome:::wa_page(navigation_placement = "left"),
    '`navigation_placement` must be one of "end", "start".',
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome:::wa_page(view = "tablet"),
    '`view` must be one of "desktop", "mobile".',
    fixed = TRUE
  )
})

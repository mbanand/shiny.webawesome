test_that("wa_relative_time defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_relative_time()),
    c("<wa-relative-time></wa-relative-time>")
  )
})

test_that("wa_relative_time override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_relative_time(
        id = "rt",
        date = "2026-03-01T00:00:00Z",
        format = "short",
        numeric = "always",
        sync = TRUE
      )
    ),
    c(
      paste0(
        '<wa-relative-time id="rt" date="2026-03-01T00:00:00Z" ',
        'format="short" numeric="always" sync></wa-relative-time>'
      )
    )
  )
})

test_that("wa_relative_time boolean and enum args validate exactly", {
  expect_error(
    shiny.webawesome:::wa_relative_time(sync = "yes"),
    "`sync` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
  expect_error(
    shiny.webawesome:::wa_relative_time(format = "wide"),
    "`format` must be one of ",
    fixed = TRUE
  )
})

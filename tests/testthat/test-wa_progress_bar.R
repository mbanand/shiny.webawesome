test_that("wa_progress_bar defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_progress_bar()),
    c("<wa-progress-bar></wa-progress-bar>")
  )
})

test_that("wa_progress_bar override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_progress_bar(
        id = "bar",
        value = 40,
        label = "Progress",
        indeterminate = TRUE
      )
    ),
    c(
      paste0(
        '<wa-progress-bar id="bar" value="40" label="Progress" ',
        "indeterminate></wa-progress-bar>"
      )
    )
  )
})

test_that("wa_progress_bar indeterminate validates exactly", {
  expect_error(
    shiny.webawesome:::wa_progress_bar(indeterminate = "yes"),
    "`indeterminate` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

test_that("wa_progress_ring defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_progress_ring()),
    c("<wa-progress-ring></wa-progress-ring>")
  )
})

test_that("wa_progress_ring override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_progress_ring(
        id = "ring",
        value = 60,
        label = "Progress"
      )
    ),
    c(
      paste0(
        '<wa-progress-ring id="ring" value="60" label="Progress">',
        "</wa-progress-ring>"
      )
    )
  )
})

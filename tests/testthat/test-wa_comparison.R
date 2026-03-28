test_that("wa_comparison requires input_id", {
  expect_error(
    shiny.webawesome:::wa_comparison(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_comparison defaults render the minimal semantic wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_comparison(input_id = "comparison")),
    c('<wa-comparison id="comparison"></wa-comparison>')
  )
})

test_that("wa_comparison override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_comparison(
        input_id = "comparison",
        dir = "rtl",
        lang = "en",
        position = 75,
        after = "After",
        before = "Before",
        handle = "Handle"
      )
    ),
    c(
      '<wa-comparison id="comparison" dir="rtl" lang="en" position="75">',
      '  <span slot="after">After</span>',
      '  <span slot="before">Before</span>',
      '  <span slot="handle">Handle</span>',
      "</wa-comparison>"
    )
  )
})

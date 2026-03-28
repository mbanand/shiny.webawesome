test_that("wa_rating requires input_id", {
  expect_error(
    shiny.webawesome:::wa_rating(),
    'argument "input_id" is missing',
    fixed = TRUE
  )
})

test_that("wa_rating defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_rating("rating")),
    c('<wa-rating id="rating"></wa-rating>')
  )
})

test_that("wa_rating override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_rating(
        "rating",
        value = 3,
        disabled = TRUE,
        label = "Stars",
        max = 7,
        precision = 0.5,
        readonly = TRUE,
        size = "large"
      )
    ),
    c(
      paste0(
        '<wa-rating id="rating" value="3" disabled label="Stars" ',
        'max="7" precision="0.5" readonly size="large"></wa-rating>'
      )
    )
  )
})

test_that("wa_rating boolean and enum args validate exactly", {
  expect_error(
    shiny.webawesome:::wa_rating("rating", disabled = "yes"),
    "`disabled` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
  expect_error(
    shiny.webawesome:::wa_rating("rating", size = "tiny"),
    "`size` must be one of ",
    fixed = TRUE
  )
})

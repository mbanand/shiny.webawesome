test_that("wa_animation defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_animation()),
    c("<wa-animation></wa-animation>")
  )
})

test_that("wa_animation override render includes attrs", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_animation(
        id = "animation",
        name = "bounce",
        delay = 100,
        direction = "alternate",
        duration = 2000,
        easing = "ease-in-out",
        end_delay = 50,
        fill = "forwards",
        iteration_start = 0.5,
        iterations = 3,
        play = TRUE,
        playback_rate = 2
      )
    ),
    c(
      paste0(
        '<wa-animation id="animation" name="bounce" delay="100" ',
        'direction="alternate" duration="2000" easing="ease-in-out" ',
        'end-delay="50" fill="forwards" iteration-start="0.5" ',
        'iterations="3" play playback-rate="2"></wa-animation>'
      )
    )
  )
})

test_that("wa_animation play validates exactly", {
  expect_error(
    shiny.webawesome:::wa_animation(play = "yes"),
    "`play` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

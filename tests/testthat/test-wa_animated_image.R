test_that("wa_animated_image defaults render the minimal wrapper", {
  expect_exact_html(
    render_html(shiny.webawesome:::wa_animated_image()),
    c("<wa-animated-image></wa-animated-image>")
  )
})

test_that("wa_animated_image override render includes attrs and slots", {
  expect_exact_html(
    render_html(
      shiny.webawesome:::wa_animated_image(
        id = "anim",
        alt = "Animated",
        play = TRUE,
        src = "/anim.gif",
        pause_icon = "Pause",
        play_icon = "Play"
      )
    ),
    c(
      '<wa-animated-image id="anim" alt="Animated" play src="/anim.gif">',
      '  <span slot="pause-icon">Pause</span>',
      '  <span slot="play-icon">Play</span>',
      "</wa-animated-image>"
    )
  )
})

test_that("wa_animated_image play validates exactly", {
  expect_error(
    shiny.webawesome:::wa_animated_image(play = "yes"),
    "`play` must be TRUE, FALSE, or NULL.",
    fixed = TRUE
  )
})

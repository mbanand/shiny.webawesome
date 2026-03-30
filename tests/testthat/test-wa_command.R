test_that("wa_set_property sends one custom command message", {
  recorder <- new_custom_message_recorder()

  expect_invisible(
    shiny.webawesome::wa_set_property(
      id = "dialog",
      property = "open",
      value = TRUE,
      session = recorder$session
    )
  )

  expect_equal(
    recorder$seen$calls,
    list(
      list(
        type = "shiny.webawesome.command",
        message = list(
          id = "dialog",
          command = "set_property",
          payload = list(name = "open", value = TRUE)
        )
      )
    )
  )
})

test_that("wa_set_property validates property and session", {
  recorder <- new_custom_message_recorder()

  expect_error(
    shiny.webawesome::wa_set_property(
      id = "dialog",
      property = NA_character_,
      value = TRUE,
      session = recorder$session
    ),
    "`property` must be one non-missing string.",
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome::wa_set_property(
      id = "dialog",
      property = "open",
      value = TRUE,
      session = NULL
    ),
    "`session` must be an active Shiny session",
    fixed = TRUE
  )
})

test_that("wa_call_method sends one custom command message", {
  recorder <- new_custom_message_recorder()

  expect_invisible(
    shiny.webawesome::wa_call_method(
      id = "dialog",
      method = "show",
      args = list("alpha", 1),
      session = recorder$session
    )
  )

  expect_equal(
    recorder$seen$calls,
    list(
      list(
        type = "shiny.webawesome.command",
        message = list(
          id = "dialog",
          command = "call_method",
          payload = list(name = "show", args = list("alpha", 1))
        )
      )
    )
  )
})

test_that("wa_call_method validates method, args, and session", {
  recorder <- new_custom_message_recorder()

  expect_error(
    shiny.webawesome::wa_call_method(
      id = "dialog",
      method = "",
      session = recorder$session
    ),
    "`method` must be one non-missing string.",
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome::wa_call_method(
      id = "dialog",
      method = "show",
      args = "alpha",
      session = recorder$session
    ),
    "`args` must be a list.",
    fixed = TRUE
  )

  expect_error(
    shiny.webawesome::wa_call_method(
      id = "dialog",
      method = "show",
      session = NULL
    ),
    "`session` must be an active Shiny session",
    fixed = TRUE
  )
})

source(file.path("..", "..", "check_interactive.R"))

testthat::test_that("check_interactive prints help", {
  result <- paste(
    capture.output(run_check_interactive("--help")),
    collapse = "\n"
  )

  testthat::expect_match(result, "Usage: ./tools/check_interactive.R")
  testthat::expect_match(result, "--host")
  testthat::expect_match(result, "--port")
})

testthat::test_that("check_interactive rejects invalid port values", {
  testthat::expect_error(
    .parse_check_interactive_args(c("--port", "abc")),
    "`--port` must be a positive integer"
  )
})

testthat::test_that("interactive app source includes wa_js copy coverage", {
  file_text <- paste(
    readLines(file.path("..", "..", "check_interactive.R"), warn = FALSE),
    collapse = "\n"
  )

  testthat::expect_match(file_text, "App-local JS Category", fixed = TRUE)
  testthat::expect_match(file_text, "wa_copy_button", fixed = TRUE)
  testthat::expect_match(file_text, "copy_button_js_event", fixed = TRUE)
  testthat::expect_match(file_text, "wa-copy", fixed = TRUE)
})

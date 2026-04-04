source(file.path("..", "..", "cli_ui.R"))

testthat::test_that("plain CLI lines can include trailing comments", {
  testthat::expect_equal(
    .cli_plain_line(
      label = "Pruning Web Awesome",
      status = "Done",
      status_col = 40L,
      comment = "[report: reports/prune/3.3.1/summary.md]"
    ),
    paste0(
      "Pruning Web Awesome ",
      strrep(".", 16L),
      " Done    [report: reports/prune/3.3.1/summary.md]"
    )
  )
})

testthat::test_that("cli child env preserves PATH while applying overrides", {
  child_env <- .cli_child_env(c(SHINY_WEBAWESOME_CLI_MODE = "plain"))

  testthat::expect_true(is.character(child_env))
  testthat::expect_true("PATH" %in% names(child_env))
  testthat::expect_true(nzchar(child_env[["PATH"]]))
  testthat::expect_identical(
    child_env[["SHINY_WEBAWESOME_CLI_MODE"]],
    "plain"
  )
})

testthat::test_that("cli run_command applies merged env to child processes", {
  testthat::skip_if_not_installed("processx")

  ui <- .cli_ui_new()
  ui$quiet <- TRUE
  ui$fancy <- FALSE

  result <- .cli_run_command(
    ui = ui,
    label = "Checking child env",
    command = "Rscript",
    args = c("-e", paste(
      "cat(Sys.getenv(\"SHINY_WEBAWESOME_CLI_MODE\"), \"\\n\")",
      "cat(nzchar(Sys.getenv(\"PATH\")), \"\\n\")",
      sep = "; "
    )),
    env = c(SHINY_WEBAWESOME_CLI_MODE = "plain")
  )

  testthat::expect_identical(result$status, 0L)
  output <- strsplit(result$stdout, "\n", fixed = TRUE)[[1]]
  output <- trimws(output[nzchar(output)])
  testthat::expect_identical(output[[1]], "plain")
  testthat::expect_identical(output[[2]], "TRUE")
})

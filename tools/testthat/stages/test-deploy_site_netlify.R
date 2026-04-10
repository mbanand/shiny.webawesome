source(file.path("..", "..", "deploy_site_netlify.R"))

# nolint start: object_usage_linter
.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root) {
  dir.create(
    file.path(root, "projectdocs"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "website"), recursive = TRUE, showWarnings = FALSE)

  .write_file(file.path(root, "DESCRIPTION"), c(
    "Package: fake",
    "Version: 0.1.0"
  ))
  .write_file(file.path(root, "projectdocs", "README.md"), "docs")
  .write_file(file.path(root, "website", "index.html"), "<html></html>")
}

.fake_netlify_runner <- function(log = NULL) {
  force(log)

  function(command, args = character(), wd = ".", env = character()) {
    if (!is.null(log)) {
      log$calls <- c(
        log$calls,
        list(list(command = command, args = args, wd = wd, env = env))
      )
    }

    if (any(args == "sites:list")) {
      return(list(
        status = 0L,
        stdout = '[{"id":"site-123","name":"shiny-webawesome"}]',
        stderr = character()
      ))
    }

    if (any(args == "deploy")) {
      return(list(
        status = 0L,
        stdout = '{"site_id":"site-123","deploy_url":"https://example.netlify.app"}',
        stderr = character()
      ))
    }

    list(status = 0L, stdout = character(), stderr = character())
  }
}

testthat::test_that(
  "deploy_site_netlify dry-run verifies auth and site visibility without deploy",
  {
    testthat::skip_if_not_installed("jsonlite")

    root <- withr::local_tempdir()
    .create_fake_repo(root)
    withr::local_envvar(c(
      NETLIFY_AUTH_TOKEN = "token-123",
      NETLIFY_SITE_ID = "site-123"
    ))

    call_log <- new.env(parent = emptyenv())
    call_log$calls <- list()

    result <- deploy_site_netlify(
      root = root,
      dry_run = TRUE,
      verbose = FALSE,
      runner = .fake_netlify_runner(log = call_log)
    )

    command_args <- lapply(call_log$calls, function(call) call$args)

    testthat::expect_true(any(vapply(
      command_args,
      function(args) any(args == "sites:list"),
      logical(1)
    )))
    testthat::expect_false(any(vapply(
      command_args,
      function(args) any(args == "deploy"),
      logical(1)
    )))
    testthat::expect_false(isTRUE(result$deployed))
    testthat::expect_identical(result$site_id, "site-123")
  }
)

testthat::test_that(
  "deploy_site_netlify runs production deploy after readiness verification",
  {
    testthat::skip_if_not_installed("jsonlite")

    root <- withr::local_tempdir()
    .create_fake_repo(root)
    withr::local_envvar(c(
      NETLIFY_AUTH_TOKEN = "token-123",
      NETLIFY_SITE_ID = "site-123"
    ))

    call_log <- new.env(parent = emptyenv())
    call_log$calls <- list()

    result <- deploy_site_netlify(
      root = root,
      dry_run = FALSE,
      verbose = FALSE,
      runner = .fake_netlify_runner(log = call_log)
    )

    command_args <- lapply(call_log$calls, function(call) call$args)

    testthat::expect_true(any(vapply(
      command_args,
      function(args) any(args == "deploy"),
      logical(1)
    )))
    testthat::expect_true(isTRUE(result$deployed))
  }
)

testthat::test_that("deploy_site_netlify requires auth token", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  withr::local_envvar(c(
    NETLIFY_AUTH_TOKEN = NA_character_,
    NETLIFY_SITE_ID = "site-123"
  ))

  testthat::expect_error(
    deploy_site_netlify(root = root, dry_run = TRUE, verbose = FALSE),
    "NETLIFY_AUTH_TOKEN"
  )
})
# nolint end: object_usage_linter

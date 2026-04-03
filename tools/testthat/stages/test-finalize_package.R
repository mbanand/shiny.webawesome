source(file.path("..", "..", "finalize_package.R"))

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

  .write_file(file.path(root, "DESCRIPTION"), c(
    "Package: fake",
    "Version: 0.1.0",
    "Imports: shiny",
    "Suggests: testthat"
  ))
  .write_file(file.path(root, "projectdocs", "README.md"), "docs")
  .write_file(file.path(root, "tools", "placeholder.R"), "x <- 1")
  .write_file(file.path(root, "tools", "finalize_package.R"), "x <- 1")
}

.fake_git_runner <- function(command,
                             args = character(),
                             wd = ".",
                             env = character()) {
  if (identical(command, "git") && identical(args, "ls-files")) {
    return(list(
      status = 0L,
      stdout = c("DESCRIPTION\nprojectdocs/README.md\nwebsite/index.html"),
      stderr = character()
    ))
  }

  if (identical(command, "git") && identical(args, c("rev-parse", "HEAD"))) {
    return(list(status = 0L, stdout = "abc123", stderr = character()))
  }

  list(status = 0L, stdout = character(), stderr = character())
}

testthat::test_that(
  "finalize_package writes handoff artifacts and records non-strict warnings",
  {
    testthat::skip_if_not_installed("digest")
    testthat::skip_if_not_installed("yaml")

    root <- withr::local_tempdir()
    .create_fake_repo(root)

    .write_file(file.path(root, "website", "index.html"), "<html></html>")
    .write_file(file.path(root, "fake_0.1.0.tar.gz"), "tarball")

    steps <- list(
      cleanup = list(
        label = "Cleaning finalize outputs",
        fatal = TRUE,
        run = function(context) list(ok = TRUE, details = "clean")
      ),
      optional_check = list(
        label = "Optional check",
        fatal = function(context) isTRUE(context$strict),
        run = function(context) {
          list(ok = FALSE, details = "Optional check failed.")
        }
      ),
      build = list(
        label = "Building package tarball",
        fatal = TRUE,
        run = function(context) {
          list(
            ok = TRUE,
            data = list(
              tarball_path = file.path(context$root, "fake_0.1.0.tar.gz")
            )
          )
        }
      )
    )

    result <- finalize_package(
      root = root,
      strict = FALSE,
      verbose = FALSE,
      runner = .fake_git_runner,
      steps = steps
    )

    testthat::expect_true(
      file.exists(
        file.path(root, "manifests", "finalize", "release-handoff.yaml")
      )
    )
    testthat::expect_true(
      file.exists(file.path(root, "reports", "finalize", "summary.md"))
    )
    testthat::expect_equal(result$handoff$status, "warn")
    testthat::expect_equal(
      result$warnings$optional_check,
      "Optional check failed."
    )

    handoff <- yaml::read_yaml(
      file.path(root, "manifests", "finalize", "release-handoff.yaml")
    )
    testthat::expect_equal(handoff$mode, "default")
    testthat::expect_equal(handoff$git_head, "abc123")
    testthat::expect_equal(handoff$artifacts$website$path, "website")
  }
)

testthat::test_that("strict finalize failures stop the run", {
  testthat::skip_if_not_installed("digest")
  testthat::skip_if_not_installed("yaml")

  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .write_file(file.path(root, "fake_0.1.0.tar.gz"), "tarball")

  steps <- list(
    cleanup = list(
      label = "Cleaning finalize outputs",
      fatal = TRUE,
      run = function(context) list(ok = TRUE)
    ),
    confirmations = list(
      label = "Checking external confirmations",
      fatal = function(context) isTRUE(context$strict),
      run = function(context) {
        list(ok = FALSE, details = "Strict finalize requires confirmations.")
      }
    ),
    build = list(
      label = "Building package tarball",
      fatal = TRUE,
      run = function(context) {
        list(
          ok = TRUE,
          data = list(
            tarball_path = file.path(context$root, "fake_0.1.0.tar.gz")
          )
        )
      }
    )
  )

  testthat::expect_error(
    finalize_package(
      root = root,
      strict = TRUE,
      verbose = FALSE,
      runner = .fake_git_runner,
      steps = steps
    ),
    "Strict finalize requires confirmations."
  )
})

testthat::test_that(
  "finalize_package accumulates multiple non-strict warnings",
  {
    testthat::skip_if_not_installed("digest")
    testthat::skip_if_not_installed("yaml")

    root <- withr::local_tempdir()
    .create_fake_repo(root)

    .write_file(file.path(root, "website", "index.html"), "<html></html>")
    .write_file(file.path(root, "fake_0.1.0.tar.gz"), "tarball")

    steps <- list(
      cleanup = list(
        label = "Cleaning finalize outputs",
        fatal = TRUE,
        run = function(context) list(ok = TRUE)
      ),
      style = list(
        label = "Checking R style",
        fatal = function(context) isTRUE(context$strict),
        run = function(context) list(ok = FALSE, details = "Style warning.")
      ),
      lint = list(
        label = "Checking R lint",
        fatal = function(context) isTRUE(context$strict),
        run = function(context) list(ok = FALSE, details = "Lint warning.")
      ),
      build = list(
        label = "Building package tarball",
        fatal = TRUE,
        run = function(context) {
          list(
            ok = TRUE,
            data = list(
              tarball_path = file.path(context$root, "fake_0.1.0.tar.gz")
            )
          )
        }
      )
    )

    result <- finalize_package(
      root = root,
      strict = FALSE,
      verbose = FALSE,
      runner = .fake_git_runner,
      steps = steps
    )

    testthat::expect_equal(sort(names(result$warnings)), c("lint", "style"))
    testthat::expect_equal(result$handoff$status, "warn")
  }
)

testthat::test_that(
  paste(
    "finalize confirmations are advisory in default mode and",
    "strict in strict mode"
  ),
  {
    steps <- .finalize_steps()

    default_result <- steps$confirmations$run(list(
      strict = FALSE,
      confirmed_rhub_pass = FALSE,
      confirmed_visual_review = FALSE
    ))
    strict_result <- steps$confirmations$run(list(
      strict = TRUE,
      confirmed_rhub_pass = FALSE,
      confirmed_visual_review = FALSE
    ))

    testthat::expect_true(default_result$ok)
    testthat::expect_match(
      paste(default_result$details, collapse = "\n"),
      "Run external pre-release checks"
    )
    testthat::expect_match(
      paste(default_result$details, collapse = "\n"),
      "./tools/check_interactive.R"
    )
    testthat::expect_false(strict_result$ok)
    testthat::expect_match(
      paste(strict_result$details, collapse = "\n"),
      "--confirmed-rhub-pass"
    )
    testthat::expect_match(
      paste(strict_result$details, collapse = "\n"),
      "--confirmed-visual-review"
    )
  }
)

testthat::test_that(
  "dependency audit reports missing imports and support deps",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)

    dir.create(file.path(root, "R"), recursive = TRUE, showWarnings = FALSE)
    dir.create(file.path(root, "tests"), recursive = TRUE, showWarnings = FALSE)
    dir.create(
      file.path(root, "vignettes"),
      recursive = TRUE,
      showWarnings = FALSE
    )

    .write_file(
      file.path(root, "R", "helper.R"),
      "devtools::load_all()"
    )
    .write_file(
      file.path(root, "tests", "testthat.R"),
      "library(withr)\nrequireNamespace('pkgdown')"
    )

    audit <- .audit_dependencies(root)

    testthat::expect_false(audit$ok)
    testthat::expect_match(
      paste(audit$details, collapse = "\n"),
      "devtools"
    )
    testthat::expect_match(
      paste(audit$details, collapse = "\n"),
      "pkgdown"
    )
  }
)

testthat::test_that("strict finalize validates clean start state directly", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  dir.create(file.path(root, "vendor", "webawesome"), recursive = TRUE)

  testthat::expect_error(
    finalize_package(
      root = root,
      strict = TRUE,
      verbose = FALSE,
      runner = .fake_git_runner,
      steps = list()
    ),
    "Strict finalize requires a clean release-build starting state"
  )
})

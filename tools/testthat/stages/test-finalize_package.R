source(file.path("..", "..", "finalize_package.R"))

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.capture_stderr <- function(expr) {
  path <- tempfile(fileext = ".log")
  con <- file(path, open = "wt")
  sink(con, type = "message")
  on.exit(
    {
      sink(type = "message")
      close(con)
    },
    add = TRUE
  )

  force(expr)
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
  .write_file(file.path(root, "NEWS.md"), "# Version 0.1.0")
  .write_file(file.path(root, "dev", "webawesome-version.txt"), "3.5.0")
  .write_file(file.path(root, "inst", "SHINY.WEBAWESOME_VERSION"), "3.5.0")
  .write_file(file.path(root, "_pkgdown.yml"), c(
    "home:",
    "  description: >-",
    paste(
      "    Fake package. Package version 0.1.0;",
      "bundled upstream Web Awesome version 3.5.0."
    ),
    "  strip:",
    "    subtitle: >-",
    "      Fake package. Package 0.1.0 with bundled Web Awesome 3.5.0.",
    "navbar:",
    "  components:",
    "    upstream:",
    "      text: Web Awesome 3.5.0"
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

.fake_urlchecker_db <- function(problems = NULL) {
  if (is.null(problems)) {
    problems <- data.frame(
      URL = character(),
      From = I(list()),
      Status = character(),
      Message = character(),
      New = character(),
      CRAN = character(),
      Spaces = character(),
      R = character(),
      root = character(),
      stringsAsFactors = FALSE
    )
  }

  class(problems) <- c("urlchecker_db", "check_url_db", "data.frame")
  problems
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
      coverage = list(
        label = "Computing package test coverage",
        fatal = FALSE,
        run = function(context) {
          list(
            ok = TRUE,
            details = "Package test coverage: 91.2%",
            data = list(
              package_coverage = list(
                available = TRUE,
                percent = 91.2
              )
            )
          )
        }
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

    result <- .capture_stderr(
      finalize_package(
        root = root,
        strict = FALSE,
        verbose = FALSE,
        runner = .fake_git_runner,
        steps = steps
      )
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
    testthat::expect_true(isTRUE(handoff$coverage$package$available))
    testthat::expect_equal(handoff$coverage$package$percent, 91.2)

    summary_lines <- readLines(
      file.path(root, "reports", "finalize", "summary.md"),
      warn = FALSE
    )
    testthat::expect_true(any(grepl(
      "^Generated by tools/finalize_package\\.R\\. Do not edit by hand\\.$",
      summary_lines
    )))
    testthat::expect_true(any(grepl(
      "^Generated at: [0-9]{4}-[0-9]{2}-[0-9]{2}T",
      summary_lines
    )))
    testthat::expect_true(any(grepl(
      "Advisory package test coverage: `91.2%`",
      summary_lines,
      fixed = TRUE
    )))
  }
)

testthat::test_that("audit_package_urls passes clean package URL results", {
  result <- .audit_package_urls(
    ".",
    checker = function(path) .fake_urlchecker_db()
  )

  testthat::expect_true(result$ok)
  testthat::expect_null(result$details)
})

testthat::test_that("audit_package_urls reports URL problems", {
  problems <- .fake_urlchecker_db(data.frame(
    URL = "https://example.com/llms.txt",
    From = I(list("README.md:99:47")),
    Status = "404",
    Message = "Not Found",
    New = "",
    CRAN = "",
    Spaces = "",
    R = "",
    root = "/tmp/fake",
    stringsAsFactors = FALSE
  ))

  result <- .audit_package_urls(
    ".",
    checker = function(path) problems
  )

  testthat::expect_false(result$ok)
  testthat::expect_true(length(result$details) > 0L)
  testthat::expect_match(
    paste(result$details, collapse = "\n"),
    "README\\.md|example\\.com/llms\\.txt"
  )
  testthat::expect_equal(result$data$url_problems$Status[[1]], "404")
})

testthat::test_that(
  paste(
    "audit_package_urls accepts package-owned site URLs",
    "present in website output"
  ),
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)
    .write_file(file.path(root, "website", "llms.txt"), "ok")
    .write_file(file.path(root, "_pkgdown.yml"), c(
      "url: https://www.shiny-webawesome.org",
      "destination: website"
    ))

    problems <- .fake_urlchecker_db(data.frame(
      URL = "https://www.shiny-webawesome.org/llms.txt",
      From = I(list("README.md:99:47")),
      Status = "404",
      Message = "Not Found",
      New = "",
      CRAN = "",
      Spaces = "",
      R = "",
      root = root,
      stringsAsFactors = FALSE
    ))

    result <- .audit_package_urls(
      root,
      checker = function(path) problems
    )

    testthat::expect_true(result$ok)
    testthat::expect_equal(nrow(result$data$url_problems), 0L)
    testthat::expect_equal(nrow(result$data$local_site_url_problems), 0L)
  }
)

testthat::test_that(
  "audit_package_urls reports missing package-owned site artifact paths",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)
    .write_file(file.path(root, "_pkgdown.yml"), c(
      "url: https://www.shiny-webawesome.org",
      "destination: website"
    ))

    problems <- .fake_urlchecker_db(data.frame(
      URL = "https://www.shiny-webawesome.org/llms.txt",
      From = I(list("README.md:99:47")),
      Status = "404",
      Message = "Not Found",
      New = "",
      CRAN = "",
      Spaces = "",
      R = "",
      root = root,
      stringsAsFactors = FALSE
    ))

    result <- .audit_package_urls(
      root,
      checker = function(path) problems
    )

    testthat::expect_false(result$ok)
    testthat::expect_match(
      paste(result$details, collapse = "\n"),
      "missing from built website artifact"
    )
    testthat::expect_equal(nrow(result$data$url_problems), 0L)
    testthat::expect_equal(nrow(result$data$local_site_url_problems), 1L)
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
    .capture_stderr(
      finalize_package(
        root = root,
        strict = TRUE,
        verbose = FALSE,
        runner = .fake_git_runner,
        steps = steps
      )
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

    result <- .capture_stderr(
      finalize_package(
        root = root,
        strict = FALSE,
        verbose = FALSE,
        runner = .fake_git_runner,
        steps = steps
      )
    )

    testthat::expect_equal(sort(names(result$warnings)), c("lint", "style"))
    testthat::expect_equal(result$handoff$status, "warn")
  }
)

testthat::test_that(
  "finalize_package warns on handwritten version metadata mismatch",
  {
    testthat::skip_if_not_installed("digest")
    testthat::skip_if_not_installed("yaml")

    root <- withr::local_tempdir()
    .create_fake_repo(root)
    .write_file(file.path(root, "website", "index.html"), "<html></html>")
    .write_file(file.path(root, "fake_0.1.0.tar.gz"), "tarball")
    .write_file(file.path(root, "NEWS.md"), "# shiny.webawesome 0.0.9")
    .write_file(file.path(root, "_pkgdown.yml"), c(
      "home:",
      "  description: >-",
      paste(
        "    Fake package. Package version 0.0.8;",
        "bundled upstream Web Awesome version 3.3.1."
      ),
      "  strip:",
      "    subtitle: >-",
      "      Fake package. Package 0.0.8 with bundled Web Awesome 3.3.1.",
      "navbar:",
      "  components:",
      "    upstream:",
      "      text: Web Awesome 3.3.1"
    ))

    steps <- list(
      cleanup = list(
        label = "Cleaning finalize outputs",
        fatal = TRUE,
        run = function(context) list(ok = TRUE)
      ),
      version_consistency = .finalize_steps()$version_consistency,
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

    result <- .capture_stderr(
      finalize_package(
        root = root,
        strict = FALSE,
        verbose = FALSE,
        runner = .fake_git_runner,
        steps = steps
      )
    )

    testthat::expect_equal(result$handoff$status, "warn")
    testthat::expect_true("version_consistency" %in% names(result$warnings))
    testthat::expect_true(any(grepl(
      "_pkgdown\\.yml",
      result$warnings$version_consistency,
      perl = TRUE
    )))
    testthat::expect_true(any(grepl(
      "NEWS\\.md",
      result$warnings$version_consistency,
      perl = TRUE
    )))
    testthat::expect_error(
      .capture_stderr(
        finalize_package(
          root = root,
          strict = TRUE,
          verbose = FALSE,
          runner = .fake_git_runner,
          steps = steps
        )
      ),
      "does not match"
    )
  }
)

testthat::test_that(
  "finalize_package checks each mirrored _pkgdown.yml version field explicitly",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)

    .write_file(file.path(root, "_pkgdown.yml"), c(
      "home:",
      "  description: >-",
      paste(
        "    Fake package. Package version 0.1.0;",
        "bundled upstream Web Awesome version 3.5.0."
      ),
      "  strip:",
      "    subtitle: >-",
      "      Fake package. Package 0.0.8 with bundled Web Awesome 3.5.0.",
      "navbar:",
      "  components:",
      "    upstream:",
      "      text: Web Awesome 3.5.0"
    ))

    result <- .check_version_consistency(root)

    testthat::expect_false(result$ok)
    testthat::expect_true(any(grepl(
      "home\\.strip\\.subtitle",
      result$details,
      perl = TRUE
    )))
    testthat::expect_false(any(grepl(
      "home\\.description",
      result$details,
      perl = TRUE
    )))
    testthat::expect_false(any(grepl(
      "navbar\\.components\\.upstream\\.text",
      result$details,
      perl = TRUE
    )))
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

testthat::test_that("package coverage helper degrades to unavailable", {
  failing_runner <- function(command,
                             args = character(),
                             wd = ".",
                             env = character()) {
    list(
      status = 1L,
      stdout = character(),
      stderr = "coverage failed"
    )
  }

  result <- .run_package_coverage_step(
    root = ".",
    runner = failing_runner
  )

  testthat::expect_true(result$ok)
  testthat::expect_false(isTRUE(result$data$package_coverage$available))
  testthat::expect_null(result$data$package_coverage$percent)
  testthat::expect_match(result$details, "Package test coverage unavailable.")
})

testthat::test_that(
  "run_site_step promotes non-strict site warnings into finalize warnings",
  {
    context <- list(
      root = normalizePath(".", winslash = "/", mustWork = TRUE),
      strict = FALSE
    )

    result <- .run_site_step(
      context,
      stage_runner = function(root,
                              install,
                              live_examples,
                              preview,
                              strict_link_audit,
                              verbose) {
        list(
          ok = FALSE,
          warning = TRUE,
          details = "Could not find `lychee` on PATH.",
          destination = file.path(root, "website"),
          audit = list(
            ok = FALSE,
            fatal = FALSE
          )
        )
      }
    )

    testthat::expect_false(result$ok)
    testthat::expect_equal(result$details, "Could not find `lychee` on PATH.")
    testthat::expect_equal(result$data$destination, "website")
    testthat::expect_false(isTRUE(result$data$audit$ok))
  }
)

testthat::test_that(
  paste(
    "finalize_package records non-strict site warnings",
    "from structured stage tools"
  ),
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
      site = list(
        label = "Building website",
        fatal = function(context) isTRUE(context$strict),
        run = function(context) {
          .run_site_step(
            context,
            stage_runner = function(root,
                                    install,
                                    live_examples,
                                    preview,
                                    strict_link_audit,
                                    verbose) {
              list(
                ok = FALSE,
                warning = TRUE,
                details = paste(
                  "Could not find `lychee` on PATH for website link auditing.",
                  "Install a standalone `lychee` binary or set",
                  "`SHINY_WEBAWESOME_LYCHEE=/path/to/lychee`."
                ),
                destination = file.path(root, "website"),
                audit = list(
                  ok = FALSE,
                  fatal = FALSE
                )
              )
            }
          )
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

    result <- .capture_stderr(
      finalize_package(
        root = root,
        strict = FALSE,
        verbose = FALSE,
        runner = .fake_git_runner,
        steps = steps
      )
    )

    testthat::expect_equal(result$handoff$status, "warn")
    testthat::expect_true("site" %in% names(result$warnings))
    testthat::expect_match(
      paste(result$warnings$site, collapse = "\n"),
      "Could not find `lychee` on PATH"
    )

    handoff <- yaml::read_yaml(
      file.path(root, "manifests", "finalize", "release-handoff.yaml")
    )
    testthat::expect_equal(handoff$status, "warn")
    testthat::expect_true("site" %in% names(handoff$warnings))
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

testthat::test_that("strict finalize no longer asserts a clean build start", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  dir.create(file.path(root, "vendor", "webawesome"), recursive = TRUE)
  .write_file(file.path(root, "website", "index.html"), "<html></html>")
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
      run = function(context) list(ok = TRUE)
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

  testthat::expect_no_error(
    .capture_stderr(
      finalize_package(
        root = root,
        strict = TRUE,
        confirmed_rhub_pass = TRUE,
        confirmed_visual_review = TRUE,
        verbose = FALSE,
        runner = .fake_git_runner,
        steps = steps
      )
    )
  )
})

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
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")

  file.copy(
    normalizePath(file.path("..", "..", "build_package.R"), mustWork = TRUE),
    file.path(root, "tools", "build_package.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )
  .write_file(file.path(root, "tools", "build_tools.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('build tools invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "fetch_webawesome.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('fetch invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "prune_webawesome.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('prune invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "generate_components.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('generate invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "review_binding_candidates.R"), c(
    "#!/usr/bin/env Rscript",
    "review_binding_candidates <- function(root = '.', verbose = FALSE) {",
    "  list(",
    "    candidates = list(),",
    "    watch_list = list(),",
    "    report_path = 'reports/review/binding-candidates.md'",
    "  )",
    "}"
  ))
  .write_file(file.path(root, "tools", "report_components.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('report invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "check_integrity.R"), c(
    "#!/usr/bin/env Rscript",
    "cat('integrity invoked\\n')"
  ))
  .write_file(file.path(root, "tools", "finalize_package.R"), c(
    "#!/usr/bin/env Rscript",
    "finalize_package <- function(root = '.', strict = FALSE,",
    "                             confirmed_rhub_pass = FALSE,",
    "                             confirmed_visual_review = FALSE,",
    "                             verbose = FALSE) {",
    "  list(",
    "    warnings = list(),",
    "    handoff = list(",
    "      status = 'pass'",
    "    )",
    "  )",
    "}"
  ))

  scripts <- c(
    "build_package.R",
    "build_tools.R",
    "fetch_webawesome.R",
    "prune_webawesome.R",
    "generate_components.R",
    "review_binding_candidates.R",
    "report_components.R",
    "check_integrity.R",
    "finalize_package.R"
  )

  for (script in scripts) {
    Sys.chmod(file.path(root, "tools", script), mode = "0755")
  }
}

.run_build_package_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/build_package.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("build_package prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_package_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/build_package.R")
  testthat::expect_match(result$stdout, "--skip-tools")
  testthat::expect_match(result$stdout, "--finalize-strict")
  testthat::expect_match(result$stdout, "--confirmed-rhub-pass")
  testthat::expect_match(result$stdout, "--confirmed-visual-review")
})

testthat::test_that("build_package runs build_tools first when present", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_package_script(root)

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stderr, "Building tools \\.{2,} Done")
  testthat::expect_match(
    result$stderr,
    "Running fetch_webawesome\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running prune_webawesome\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running generate_components\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running review_binding_candidates\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Review report: reports/review/binding-candidates\\.md"
  )
  testthat::expect_match(
    result$stderr,
    "Running report_components\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running check_integrity\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running finalize_package\\.R \\.{2,} Done"
  )
  testthat::expect_match(result$stderr, "Finalize status: pass")
})

testthat::test_that("build_package supports skipping the tool workflow", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_package_script(root, "--skip-tools")

  testthat::expect_equal(result$status, 0)
  testthat::expect_no_match(result$stderr, "Building tools")
  testthat::expect_match(
    result$stderr,
    "Running fetch_webawesome\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running prune_webawesome\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running generate_components\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running review_binding_candidates\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Review report: reports/review/binding-candidates\\.md"
  )
  testthat::expect_match(
    result$stderr,
    "Running report_components\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running check_integrity\\.R \\.{2,} Done"
  )
  testthat::expect_match(
    result$stderr,
    "Running finalize_package\\.R \\.{2,} Done"
  )
  testthat::expect_match(result$stderr, "Finalize status: pass")
})

testthat::test_that("build_package passes strict mode only to finalize", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_package_script(root, "--finalize-strict")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stderr, "Finalize status: pass")
})

testthat::test_that(
  "build_package passes finalize confirmation flags through",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)

    result <- .run_build_package_script(root, c(
      "--finalize-strict",
      "--confirmed-rhub-pass",
      "--confirmed-visual-review"
    ))

    testthat::expect_equal(result$status, 0)
    testthat::expect_match(result$stderr, "Finalize status: pass")
  }
)

testthat::test_that(
  "build_package marks advisory review candidates as warnings",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)
    .write_file(file.path(root, "tools", "review_binding_candidates.R"), c(
      "#!/usr/bin/env Rscript",
      "review_binding_candidates <- function(root = '.', verbose = FALSE) {",
      "  list(",
      "    candidates = list(list(tag = 'wa-trigger')),",
      "    watch_list = list(),",
      "    report_path = 'reports/review/binding-candidates.md'",
      "  )",
      "}"
    ))
    Sys.chmod(
      file.path(root, "tools", "review_binding_candidates.R"),
      mode = "0755"
    )

    result <- .run_build_package_script(root)

    testthat::expect_equal(result$status, 0)
    testthat::expect_match(
      result$stderr,
      "Running review_binding_candidates\\.R \\.{2,} Warn"
    )
    testthat::expect_match(
      result$stderr,
      "High-confidence binding review candidates: 1"
    )
  }
)

testthat::test_that(
  "build_package marks non-strict finalize warnings as warnings",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)
    .write_file(file.path(root, "tools", "finalize_package.R"), c(
      "#!/usr/bin/env Rscript",
      "finalize_package <- function(root = '.', strict = FALSE,",
      "                             confirmed_rhub_pass = FALSE,",
      "                             confirmed_visual_review = FALSE,",
      "                             verbose = FALSE) {",
      "  list(",
      "    warnings = list(site = 'Could not find `lychee` on PATH.'),",
      "    handoff = list(",
      "      status = 'warn'",
      "    )",
      "  )",
      "}"
    ))
    Sys.chmod(
      file.path(root, "tools", "finalize_package.R"),
      mode = "0755"
    )

    result <- .run_build_package_script(root)

    testthat::expect_equal(result$status, 0)
    testthat::expect_match(
      result$stderr,
      "Running finalize_package\\.R \\.{2,} Warn"
    )
    testthat::expect_match(result$stderr, "Finalize status: warn")
    testthat::expect_match(
      result$stderr,
      "Could not find `lychee` on PATH"
    )
  }
)

testthat::test_that(
  "build_package strict mode rejects pre-existing stage-owned artifacts",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)
    dir.create(file.path(root, "vendor", "webawesome"), recursive = TRUE)

    result <- .run_build_package_script(root, "--finalize-strict")

    testthat::expect_false(identical(result$status, 0L))
    testthat::expect_match(
      result$stderr,
      "Strict build_package requires a clean release-build starting state"
    )
  }
)

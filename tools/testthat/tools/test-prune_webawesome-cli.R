# nolint start: object_usage_linter.
.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root, version = "3.3.1") {
  dir.create(file.path(root, "dev"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "projectdocs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  .write_file(file.path(root, "dev", "webawesome-version.txt"), version)

  file.copy(
    normalizePath(file.path("..", "..", "prune_webawesome.R"), mustWork = TRUE),
    file.path(root, "tools", "prune_webawesome.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "integrity.R"), mustWork = TRUE),
    file.path(root, "tools", "integrity.R")
  )

  Sys.chmod(file.path(root, "tools", "prune_webawesome.R"), mode = "0755")
}

.create_fake_dist <- function(root, version = "3.3.1") {
  dist_root <- file.path(root, "vendor", "webawesome", version, "dist-cdn")
  version_root <- file.path(root, "vendor", "webawesome", version)
  .write_file(file.path(version_root, "VERSION"), version)
  .write_file(file.path(dist_root, "custom-elements.json"), "{}")
  .write_file(
    file.path(dist_root, "webawesome.loader.js"),
    "import \"./chunks/chunk.loader.js\";"
  )
  .write_file(
    file.path(dist_root, "chunks", "chunk.loader.js"),
    "export const x = true;"
  )
  .write_file(
    file.path(dist_root, "components", "wa-button.js"),
    "export const button = true;"
  )
  .write_file(
    file.path(dist_root, "events", "events.js"),
    "export const events = true;"
  )
  .write_file(file.path(dist_root, "styles", "webawesome.css"), "body {}")
  .write_file(
    file.path(dist_root, "translations", "en.js"),
    "export const en = true;"
  )
  .write_file(
    file.path(dist_root, "utilities", "set-base-path.js"),
    "export const base = true;"
  )
}

.run_prune_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/prune_webawesome.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

.run_prune_script_absolute <- function(root,
                                       args = character(),
                                       wd = tempdir()) {
  processx::run(
    command = normalizePath(
      file.path(root, "tools", "prune_webawesome.R"),
      mustWork = TRUE
    ),
    args = args,
    wd = wd,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("prune tool prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)

  result <- .run_prune_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/prune_webawesome.R")
  testthat::expect_match(result$stdout, "--version")
  testthat::expect_match(result$stdout, "--root")
})

testthat::test_that("prune tool uses the pinned version and reports success", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)

  result <- .run_prune_script(root)

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(
    result$stderr,
    paste0(
      "Pruning Web Awesome \\.{2,} Done    ",
      "\\[report: reports/prune/3.3.1/summary.md\\]"
    )
  )
  testthat::expect_match(
    result$stderr,
    paste0(
      "Prune complete: version=3.3.1, runtime=inst/www/wa, report=",
      "reports/prune/3.3.1/summary.md"
    )
  )
})

testthat::test_that("prune tool supports explicit version override", {
  root <- withr::local_tempdir()
  .create_fake_repo(root, version = "9.9.9")
  .create_fake_dist(root, version = "3.3.1")

  result <- .run_prune_script(root, c("--version", "3.3.1"))

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(
    result$stderr,
    "Prune complete: version=3.3.1, runtime=inst/www/wa"
  )
})

testthat::test_that("prune tool supports absolute-path CLI invocation", {
  root <- withr::local_tempdir()
  run_dir <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)

  result <- .run_prune_script_absolute(root, c("--root", root), wd = run_dir)

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(
    result$stderr,
    "Prune complete: version=3.3.1, runtime=inst/www/wa"
  )
})

testthat::test_that("prune tool fails cleanly when outputs already exist", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .create_fake_dist(root)
  .write_file(file.path(root, "inst", "www", "wa", "stale.js"), "stale")

  result <- .run_prune_script(root)

  testthat::expect_true(result$status != 0)
  testthat::expect_match(result$stderr, "Pruning Web Awesome \\.{2,} Fail")
  testthat::expect_match(
    result$stderr,
    "Prune output directories already contain content"
  )
  testthat::expect_no_match(result$stderr, "^Error:", perl = TRUE)
})
# nolint end

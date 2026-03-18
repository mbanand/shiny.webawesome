write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

create_fake_repo <- function(root, version = "3.0.0-beta.4") {
  dir.create(file.path(root, "dev"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  write_file(file.path(root, "dev", "webawesome-version.txt"), version)

  file.copy(
    normalizePath(file.path("..", "..", "fetch_webawesome.R"), mustWork = TRUE),
    file.path(root, "tools", "fetch_webawesome.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )

  npm_script <- c(
    "#!/usr/bin/env bash",
    "set -eu",
    "if [ \"$1\" != \"pack\" ]; then",
    "  echo \"unexpected command\" >&2",
    "  exit 1",
    "fi",
    "pkgdir=\"$PWD/package\"",
    "mkdir -p \"$pkgdir/dist/components\" \"$pkgdir/dist/styles\"",
    "printf 'button\\n' > \"$pkgdir/dist/components/wa-button.js\"",
    "printf 'css\\n' > \"$pkgdir/dist/styles/webawesome.css\"",
    "tarball=\"webawesome-cli.tgz\"",
    "tar -czf \"$tarball\" -C \"$PWD\" package",
    "printf '%s\\n' \"$tarball\""
  )
  write_file(file.path(root, "bin", "npm"), npm_script)

  Sys.chmod(file.path(root, "tools", "fetch_webawesome.R"), mode = "0755")
  Sys.chmod(file.path(root, "bin", "npm"), mode = "0755")
}

run_fetch_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/fetch_webawesome.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE,
    env = c(
      SHINY_WEBAWESOME_NPM = normalizePath(
        file.path(root, "bin", "npm"),
        mustWork = TRUE
      )
    )
  )
}

testthat::test_that("fetch tool prints help", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  result <- run_fetch_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/fetch_webawesome.R")
  testthat::expect_match(result$stdout, "--version")
  testthat::expect_match(result$stdout, "--root")
})

testthat::test_that("fetch tool uses the pinned version and reports success", {
  root <- withr::local_tempdir()
  create_fake_repo(root, version = "3.0.0-beta.4")

  result <- run_fetch_script(root)

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stderr, "Fetching Web Awesome \\.{2,} Done")
  testthat::expect_match(
    result$stderr,
    "Fetch complete: version=3.0.0-beta.4, path=vendor/webawesome/3.0.0-beta.4"
  )
  testthat::expect_true(
    file.exists(
      file.path(root, "vendor", "webawesome", "3.0.0-beta.4", "dist", "components", "wa-button.js")
    )
  )
})

testthat::test_that("fetch tool supports explicit version override", {
  root <- withr::local_tempdir()
  create_fake_repo(root, version = "3.0.0-beta.4")

  result <- run_fetch_script(root, c("--version", "3.0.0-beta.5"))

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(
    result$stderr,
    "Fetch complete: version=3.0.0-beta.5, path=vendor/webawesome/3.0.0-beta.5"
  )
})

testthat::test_that("fetch tool fails when the target version already exists", {
  root <- withr::local_tempdir()
  create_fake_repo(root)
  dir.create(file.path(root, "vendor", "webawesome", "3.0.0-beta.4"), recursive = TRUE)

  result <- run_fetch_script(root)

  testthat::expect_true(result$status != 0)
  testthat::expect_match(result$stderr, "Fetched upstream version already exists")
})

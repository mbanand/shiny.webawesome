# nolint start: object_usage_linter.
# Locate the repository-pinned version file from the current test context.
.repo_pinned_version_path <- function() {
  ofiles <- vapply(
    sys.frames(),
    function(frame) if (is.null(frame$ofile)) "" else frame$ofile,
    character(1)
  )
  current_file <- tail(ofiles[nzchar(ofiles)], 1)
  current_dir <- if (length(current_file) == 0L) "." else dirname(current_file)

  candidates <- c(
    file.path("dev", "webawesome-version.txt"),
    file.path(current_dir, "..", "..", "..", "dev", "webawesome-version.txt")
  )
  existing <- unique(candidates[file.exists(candidates)])

  if (length(existing) == 0L) {
    stop("Could not locate dev/webawesome-version.txt for the fetch CLI tests.")
  }

  existing[[1]]
}

# Read the repository-pinned Web Awesome version for CLI test fixtures.
.repo_pinned_version <- function() {
  trimws(readLines(.repo_pinned_version_path(), warn = FALSE)[[1]])
}

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root,
                              version = .repo_pinned_version(),
                              npm_lines = NULL) {
  dir.create(file.path(root, "dev"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "docs"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  .write_file(file.path(root, "dev", "webawesome-version.txt"), version)

  file.copy(
    normalizePath(file.path("..", "..", "fetch_webawesome.R"), mustWork = TRUE),
    file.path(root, "tools", "fetch_webawesome.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )

  npm_script <- npm_lines %||% c(
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
  .write_file(file.path(root, "bin", "npm"), npm_script)

  Sys.chmod(file.path(root, "tools", "fetch_webawesome.R"), mode = "0755")
  Sys.chmod(file.path(root, "bin", "npm"), mode = "0755")
}

.run_fetch_script <- function(root, args = character()) {
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
  .create_fake_repo(root)

  result <- .run_fetch_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/fetch_webawesome.R")
  testthat::expect_match(result$stdout, "--version")
  testthat::expect_match(result$stdout, "--root")
})

testthat::test_that("fetch tool uses the pinned version and reports success", {
  root <- withr::local_tempdir()
  pinned_version <- .repo_pinned_version()
  .create_fake_repo(root, version = pinned_version)

  result <- .run_fetch_script(root)

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stderr, "Fetching Web Awesome \\.{2,} Done")
  testthat::expect_match(
    result$stderr,
    paste0(
      "Fetch complete: version=",
      pinned_version,
      ", path=vendor/webawesome/",
      pinned_version
    )
  )
  testthat::expect_true(
    file.exists(
      file.path(
        root,
        "vendor",
        "webawesome",
        pinned_version,
        "dist",
        "components",
        "wa-button.js"
      )
    )
  )
})

testthat::test_that("fetch tool supports explicit version override", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_fetch_script(root, c("--version", "3.2.1"))

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(
    result$stderr,
    "Fetch complete: version=3.2.1, path=vendor/webawesome/3.2.1"
  )
})

testthat::test_that("fetch tool fails when the target version already exists", {
  root <- withr::local_tempdir()
  pinned_version <- .repo_pinned_version()
  .create_fake_repo(root)
  dir.create(
    file.path(root, "vendor", "webawesome", pinned_version),
    recursive = TRUE
  )

  result <- .run_fetch_script(root)

  testthat::expect_true(result$status != 0)
  testthat::expect_match(
    result$stderr,
    "Fetched upstream version already exists"
  )
})

testthat::test_that("fetch tool prints handled npm failures only once", {
  root <- withr::local_tempdir()
  .create_fake_repo(
    root,
    npm_lines = c(
      "#!/usr/bin/env bash",
      "set -eu",
      "echo 'npm ERR! code ETARGET' >&2",
      "echo 'npm ERR! notarget No matching version found.' >&2",
      "exit 1"
    )
  )

  result <- .run_fetch_script(root)

  testthat::expect_true(result$status != 0)
  testthat::expect_match(result$stderr, "Fetching Web Awesome \\.{2,} Fail")
  testthat::expect_equal(
    length(
      gregexpr(
        "Failed to fetch Web Awesome with npm pack\\.",
        result$stderr
      )[[1]]
    ),
    1L
  )
  testthat::expect_equal(
    length(gregexpr("npm ERR! code ETARGET", result$stderr)[[1]]),
    1L
  )
  testthat::expect_no_match(result$stderr, "^Error:", perl = TRUE)
})
# nolint end

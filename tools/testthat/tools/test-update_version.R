source(file.path("..", "..", "update_version.R"))

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
  dir.create(file.path(root, "dev"), recursive = TRUE, showWarnings = FALSE)

  .write_file(file.path(root, "DESCRIPTION"), c(
    "Package: fake",
    "Title: Fake",
    "Version: 1.0.0",
    "Description: Fake package."
  ))
  .write_file(file.path(root, "NEWS.md"), c(
    "# Version 1.0.0",
    "",
    "- Initial release."
  ))
  .write_file(file.path(root, "dev", "webawesome-version.txt"), "3.5.0")
  .write_file(file.path(root, "_pkgdown.yml"), c(
    "home:",
    "  description: >-",
    "    Shiny bindings for Web Awesome components. Package version 1.0.0;",
    "    bundled upstream Web Awesome version 3.5.0.",
    "  strip:",
    "    title: shiny.webawesome",
    "    subtitle: >-",
    "      Shiny bindings for Web Awesome components. Package 1.0.0 with",
    "      bundled Web Awesome 3.5.0.",
    "navbar:",
    "  components:",
    "    upstream:",
    "      text: Web Awesome 3.5.0",
    "      href: https://webawesome.com/"
  ))

  file.copy(
    normalizePath(file.path("..", "..", "update_version.R"), mustWork = TRUE),
    file.path(root, "tools", "update_version.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )

  Sys.chmod(file.path(root, "tools", "update_version.R"), mode = "0755")
}

.git_runner <- function(branch = "feature/version-tool", dirty = FALSE) {
  force(branch)
  force(dirty)

  function(command, args = character(), wd = ".", env = character()) {
    key <- paste(c(command, args), collapse = " ")

    if (identical(key, "git rev-parse --abbrev-ref HEAD")) {
      return(list(status = 0L, stdout = branch, stderr = ""))
    }

    if (identical(key, "git status --porcelain")) {
      return(list(
        status = 0L,
        stdout = if (isTRUE(dirty)) " M DESCRIPTION" else "",
        stderr = ""
      ))
    }

    list(
      status = 1L,
      stdout = "",
      stderr = sprintf("Unhandled command: %s", key)
    )
  }
}

.run_update_version_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/update_version.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

testthat::test_that("update_version prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_update_version_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/update_version.R")
  testthat::expect_match(result$stdout, "--package-ver")
  testthat::expect_match(result$stdout, "--upstream-ver")
  testthat::expect_match(result$stdout, "--allow-main")
  testthat::expect_match(result$stdout, "--allow-dirty")
  testthat::expect_match(result$stdout, "--check")
})

testthat::test_that("update_version rejects unknown arguments", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_update_version_script(root, "--bogus")

  testthat::expect_false(identical(result$status, 0L))
  testthat::expect_match(result$stderr, "Unknown argument: --bogus")
})

testthat::test_that("update_version rejects missing target versions", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    update_version(root = root, git_runner = .git_runner()),
    "Supply at least one of `package_ver` or `upstream_ver`"
  )
})

testthat::test_that("update_version rewrites package version mirrors", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  update_version(
    root = root,
    package_ver = "1.0.1",
    verbose = FALSE,
    git_runner = .git_runner()
  )

  testthat::expect_identical(.description_version(root), "1.0.1")
  testthat::expect_identical(.news_version(root), "1.0.1")

  pkgdown <- .pkgdown_mirrors(root)
  testthat::expect_identical(
    pkgdown$description,
    .pkgdown_description_text("1.0.1", "3.5.0")
  )
  testthat::expect_identical(
    pkgdown$subtitle,
    .pkgdown_subtitle_text("1.0.1", "3.5.0")
  )
  testthat::expect_identical(pkgdown$upstream_text, "Web Awesome 3.5.0")
})

testthat::test_that("update_version rewrites upstream version mirrors", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  update_version(
    root = root,
    upstream_ver = "3.6.0",
    verbose = FALSE,
    git_runner = .git_runner()
  )

  testthat::expect_identical(.upstream_version(root), "3.6.0")

  pkgdown <- .pkgdown_mirrors(root)
  testthat::expect_identical(
    pkgdown$description,
    .pkgdown_description_text("1.0.0", "3.6.0")
  )
  testthat::expect_identical(
    pkgdown$subtitle,
    .pkgdown_subtitle_text("1.0.0", "3.6.0")
  )
  testthat::expect_identical(pkgdown$upstream_text, "Web Awesome 3.6.0")
})

testthat::test_that("update_version check mode reports without writing", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  before <- .read_lines_utf8(file.path(root, "DESCRIPTION"))

  result <- update_version(
    root = root,
    package_ver = "1.1.0",
    upstream_ver = "3.6.0",
    check = TRUE,
    verbose = FALSE,
    git_runner = .git_runner()
  )

  after <- .read_lines_utf8(file.path(root, "DESCRIPTION"))
  testthat::expect_identical(after, before)
  testthat::expect_true(isTRUE(result$check))
  testthat::expect_true(
    any(vapply(result$records, `[[`, logical(1), "changed"))
  )
})

testthat::test_that("update_version refuses main without override", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    update_version(
      root = root,
      package_ver = "1.0.1",
      git_runner = .git_runner(branch = "main")
    ),
    "Refusing to run from `main` without `allow_main = TRUE`"
  )
})

testthat::test_that("update_version refuses dirty worktrees without override", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    update_version(
      root = root,
      package_ver = "1.0.1",
      git_runner = .git_runner(dirty = TRUE)
    ),
    "Refusing to run with a dirty git worktree without `allow_dirty = TRUE`"
  )
})

testthat::test_that(
  "update_version rewrites on main and dirty with overrides",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)

    update_version(
      root = root,
      package_ver = "1.0.2",
      allow_main = TRUE,
      allow_dirty = TRUE,
      verbose = FALSE,
      git_runner = .git_runner(branch = "main", dirty = TRUE)
    )

    testthat::expect_identical(.description_version(root), "1.0.2")
  }
)

testthat::test_that("update_version fails when NEWS heading is missing", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)
  .write_file(file.path(root, "NEWS.md"), c("Not a heading", "", "- body"))

  testthat::expect_error(
    update_version(
      root = root,
      package_ver = "1.0.1",
      verbose = FALSE,
      git_runner = .git_runner()
    ),
    "Could not find the latest release heading in `NEWS.md`"
  )
})

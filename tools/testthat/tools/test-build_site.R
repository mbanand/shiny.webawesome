source(file.path("..", "..", "build_site.R"))

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
  dir.create(file.path(root, "R"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "man"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), c(
    "Package: fakepkgdown",
    "Title: Fake pkgdown package",
    "Version: 0.0.0.9000",
    "Description: Fake package for build_site tests.",
    "License: MIT + file LICENSE",
    "Encoding: UTF-8"
  ))
  .write_file(file.path(root, "LICENSE"), "MIT")
  .write_file(file.path(root, "NAMESPACE"), "exportPattern(\"^[^\\\\.]\")")
  .write_file(file.path(root, "README.md"), c(
    "# fakepkgdown",
    "",
    "Test package."
  ))
  .write_file(file.path(root, "NEWS.md"), c(
    "# fakepkgdown 0.0.0.9000",
    "",
    "- Initial release."
  ))
  .write_file(file.path(root, "_pkgdown.yml"), c(
    "url: https://example.com",
    "destination: website"
  ))
  .write_file(file.path(root, "R", "hello.R"), c(
    "hello <- function() {",
    "  'hello'",
    "}"
  ))
  .write_file(file.path(root, "man", "hello.Rd"), c(
    "\\name{hello}",
    "\\alias{hello}",
    "\\title{Say hello}",
    "\\usage{",
    "hello()",
    "}",
    "\\value{",
    "A greeting string.",
    "}",
    "\\description{",
    "Return a small greeting string.",
    "}"
  ))
  dir.create(
    file.path(root, "tools", "man"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  .write_file(
    file.path(root, "tools", "man", "build_site.html"),
    "<html><body>tool doc</body></html>"
  )
  .write_file(
    file.path(root, "tools", "man", "build_site.txt"),
    "build_site tool doc"
  )
  .write_file(
    file.path(root, "tools", "man", "build_site.Rd"),
    c(
      "\\name{build_site}",
      "\\alias{build_site}",
      "\\title{Build site}",
      "\\description{Test tool documentation.}"
    )
  )

  file.copy(
    normalizePath(file.path("..", "..", "build_site.R"), mustWork = TRUE),
    file.path(root, "tools", "build_site.R")
  )
  file.copy(
    normalizePath(file.path("..", "..", "cli_ui.R"), mustWork = TRUE),
    file.path(root, "tools", "cli_ui.R")
  )

  Sys.chmod(file.path(root, "tools", "build_site.R"), mode = "0755")
}

.create_fake_shinylive_example <- function(root, name = "demo") {
  .write_file(
    file.path(root, "vignettes", "shinylive-examples", name, "app.R"),
    c(
      "library(shiny)",
      "ui <- fluidPage('demo')",
      "server <- function(input, output, session) {}",
      "shinyApp(ui, server)"
    )
  )
}

.run_build_site_script <- function(root, args = character()) {
  processx::run(
    command = "./tools/build_site.R",
    args = args,
    wd = root,
    echo = FALSE,
    error_on_status = FALSE
  )
}

.capture_stderr <- function(expr) {
  path <- tempfile(fileext = ".log")
  con <- file(path, open = "wt")
  sink(con, type = "message")
  sink(con, type = "output")
  on.exit(
    {
      sink(type = "output")
      sink(type = "message")
      close(con)
    },
    add = TRUE
  )

  force(expr)
}

testthat::test_that("build_site prints help", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- .run_build_site_script(root, "--help")

  testthat::expect_equal(result$status, 0)
  testthat::expect_match(result$stdout, "Usage: ./tools/build_site.R")
  testthat::expect_match(result$stdout, "--no-install")
  testthat::expect_match(result$stdout, "--with-live-examples")
  testthat::expect_match(result$stdout, "--preview")
  testthat::expect_match(result$stdout, "--strict-link-audit")
})

testthat::test_that("build_site validates the repository root", {
  root <- withr::local_tempdir()
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)

  testthat::expect_error(
    build_site(root = root, install = FALSE, verbose = FALSE),
    "checked-in _pkgdown.yml"
  )
})

testthat::test_that(
  "lychee excludes generated article package-support help trees",
  {
    patterns <- .lychee_exclude_patterns(".")
    path_patterns <- .lychee_exclude_paths(".")

    testthat::expect_true(any(grepl("/blob/HEAD/", patterns, fixed = TRUE)))
    testthat::expect_true(
      any(grepl("articles/.+_files/shiny\\\\.webawesome-", patterns))
    )
    testthat::expect_true(any(grepl("NEWS", patterns, fixed = TRUE)))
    testthat::expect_true(any(grepl("html", patterns, fixed = TRUE)))
    testthat::expect_true(
      any(grepl("articles/.+_files/shiny\\\\.webawesome-", path_patterns))
    )
    testthat::expect_true(any(grepl("NEWS", path_patterns, fixed = TRUE)))
    testthat::expect_true(any(grepl("html", path_patterns, fixed = TRUE)))
  }
)

testthat::test_that("build_site builds the configured pkgdown destination", {
  testthat::skip_if_not_installed("pkgdown")
  withr::local_envvar(c(SHINY_WEBAWESOME_CLI_MODE = "quiet"))

  root <- normalizePath(file.path("..", "..", ".."), mustWork = TRUE)
  dir.create(
    file.path(root, "website", "live-examples", "stale"),
    recursive = TRUE,
    showWarnings = FALSE
  )

  build_env <- environment(build_site)
  old_build <- get(".run_pkgdown_site_build", envir = build_env)
  assign(
    ".run_pkgdown_site_build",
    function(root, install, preview, verbose) {
      dir.create(
        file.path(root, "website"),
        recursive = TRUE,
        showWarnings = FALSE
      )
      .write_file(file.path(root, "website", "index.html"), "<html></html>")
      .write_file(
        file.path(root, "website", "pkgdown.yml"),
        "destination: website"
      )
      invisible(NULL)
    },
    envir = build_env
  )
  withr::defer(
    assign(".run_pkgdown_site_build", old_build, envir = build_env)
  )

  result <- .capture_stderr(
    build_site(root = root, install = FALSE, verbose = FALSE)
  )

  testthat::expect_equal(result$destination, "website")
  testthat::expect_true(file.exists(file.path(root, "website", "index.html")))
  testthat::expect_true(file.exists(file.path(root, "website", "pkgdown.yml")))
  testthat::expect_true(
    file.exists(file.path(root, "website", "tool-docs", "build_site.html"))
  )
  testthat::expect_false(
    dir.exists(file.path(root, "website", "live-examples"))
  )
})

testthat::test_that("build_site warns on non-strict lychee audit failures", {
  testthat::skip_if_not_installed("pkgdown")

  root <- normalizePath(file.path("..", "..", ".."), mustWork = TRUE)
  build_env <- environment(build_site)
  old_build <- get(".run_pkgdown_site_build", envir = build_env)
  old_audit <- get(".audit_website_links", envir = build_env)

  assign(
    ".run_pkgdown_site_build",
    function(root, install, preview, verbose) {
      dir.create(
        file.path(root, "website"),
        recursive = TRUE,
        showWarnings = FALSE
      )
      .write_file(file.path(root, "website", "index.html"), "<html></html>")
      invisible(NULL)
    },
    envir = build_env
  )
  assign(
    ".audit_website_links",
    function(root, destination_dir, strict, runner = NULL) {
      list(ok = FALSE, details = "lychee warning")
    },
    envir = build_env
  )
  withr::defer({
    assign(".run_pkgdown_site_build", old_build, envir = build_env)
    assign(".audit_website_links", old_audit, envir = build_env)
  })

  testthat::expect_no_error(
    .capture_stderr(
      build_site(
        root = root,
        install = FALSE,
        strict_link_audit = FALSE,
        verbose = FALSE
      )
    )
  )
})

testthat::test_that(
  "build_site_stage reports non-strict lychee audit failures structurally",
  {
    testthat::skip_if_not_installed("pkgdown")

    root <- normalizePath(file.path("..", "..", ".."), mustWork = TRUE)
    build_env <- environment(build_site)
    old_build <- get(".run_pkgdown_site_build", envir = build_env)
    old_audit <- get(".audit_website_links", envir = build_env)

    assign(
      ".run_pkgdown_site_build",
      function(root, install, preview, verbose) {
        dir.create(
          file.path(root, "website"),
          recursive = TRUE,
          showWarnings = FALSE
        )
        .write_file(file.path(root, "website", "index.html"), "<html></html>")
        invisible(NULL)
      },
      envir = build_env
    )
    assign(
      ".audit_website_links",
      function(root, destination_dir, strict, runner = NULL) {
        list(ok = FALSE, details = "lychee warning", fatal = FALSE)
      },
      envir = build_env
    )
    withr::defer({
      assign(".run_pkgdown_site_build", old_build, envir = build_env)
      assign(".audit_website_links", old_audit, envir = build_env)
    })

    result <- .build_site_stage(
      root = root,
      install = FALSE,
      strict_link_audit = FALSE,
      verbose = FALSE
    )

    testthat::expect_false(result$ok)
    testthat::expect_true(result$warning)
    testthat::expect_equal(result$details, "lychee warning")
  }
)

testthat::test_that("build_site fails on strict lychee audit failures", {
  testthat::skip_if_not_installed("pkgdown")

  root <- normalizePath(file.path("..", "..", ".."), mustWork = TRUE)
  build_env <- environment(build_site)
  old_build <- get(".run_pkgdown_site_build", envir = build_env)
  old_audit <- get(".audit_website_links", envir = build_env)

  assign(
    ".run_pkgdown_site_build",
    function(root, install, preview, verbose) {
      dir.create(
        file.path(root, "website"),
        recursive = TRUE,
        showWarnings = FALSE
      )
      .write_file(file.path(root, "website", "index.html"), "<html></html>")
      invisible(NULL)
    },
    envir = build_env
  )
  assign(
    ".audit_website_links",
    function(root, destination_dir, strict, runner = NULL) {
      list(ok = FALSE, details = "lychee failure", fatal = TRUE)
    },
    envir = build_env
  )
  withr::defer({
    assign(".run_pkgdown_site_build", old_build, envir = build_env)
    assign(".audit_website_links", old_audit, envir = build_env)
  })

  testthat::expect_error(
    .capture_stderr(
      build_site(
        root = root,
        install = FALSE,
        strict_link_audit = TRUE,
        verbose = FALSE
      )
    ),
    "lychee failure"
  )
})

testthat::test_that("shinylive helper exports example directories", {
  root <- withr::local_tempdir()
  destination_dir <- file.path(root, "website")

  .create_fake_repo(root)
  .create_fake_shinylive_example(root, "demo")

  export_calls <- list()
  fake_export <- function(appdir, destdir, quiet = TRUE) {
    export_calls[[length(export_calls) + 1L]] <<- list(
      appdir = appdir,
      destdir = destdir,
      quiet = quiet
    )
    dir.create(destdir, recursive = TRUE, showWarnings = FALSE)
    writeLines("demo", file.path(destdir, "index.html"))
  }

  .publish_live_examples(
    root = root,
    destination_dir = destination_dir,
    export_fun = fake_export,
    fallback_to_installed = FALSE
  )

  testthat::expect_length(export_calls, 1L)
  testthat::expect_match(export_calls[[1]]$appdir, "shinylive-examples/demo$")
  testthat::expect_true(
    file.exists(
      file.path(destination_dir, "live-examples", "demo", "index.html")
    )
  )
})

testthat::test_that(
  "shinylive helper writes placeholders when export is unavailable",
  {
    root <- withr::local_tempdir()
    destination_dir <- file.path(root, "website")

    .create_fake_repo(root)
    .create_fake_shinylive_example(root, "demo")

    .publish_live_examples(
      root = root,
      destination_dir = destination_dir,
      export_fun = NULL,
      fallback_to_installed = FALSE
    )

    target_file <- file.path(
      destination_dir,
      "live-examples",
      "demo",
      "index.html"
    )

    testthat::expect_true(file.exists(target_file))
    testthat::expect_match(
      paste(readLines(target_file), collapse = "\n"),
      "This live demo was not exported for the current site build"
    )
  }
)

testthat::test_that(
  "shinylive helper downgrades warning exports to placeholders",
  {
    root <- withr::local_tempdir()
    destination_dir <- file.path(root, "website")

    .create_fake_repo(root)
    .create_fake_shinylive_example(root, "demo")

    warning_export <- function(appdir, destdir, quiet = TRUE) {
      dir.create(destdir, recursive = TRUE, showWarnings = FALSE)
      writeLines("demo", file.path(destdir, "index.html"))
      warning("demo export warning", call. = FALSE)
    }

    .publish_live_examples(
      root = root,
      destination_dir = destination_dir,
      export_fun = warning_export,
      fallback_to_installed = FALSE
    )

    target_file <- file.path(
      destination_dir,
      "live-examples",
      "demo",
      "index.html"
    )

    testthat::expect_true(file.exists(target_file))
    testthat::expect_match(
      paste(readLines(target_file), collapse = "\n"),
      "The export step completed with warnings"
    )
  }
)

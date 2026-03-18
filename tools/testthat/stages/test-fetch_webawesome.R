source(file.path("..", "..", "fetch_webawesome.R"))

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
}

create_fake_webawesome_tarball <- function(output_dir,
                                           tarball_name = "webawesome.tgz",
                                           dist_files = c(
                                             "components/wa-button.js",
                                             "styles/webawesome.css"
                                           )) {
  package_root <- file.path(output_dir, "package")
  dir.create(package_root, recursive = TRUE, showWarnings = FALSE)
  for (dist_file in dist_files) {
    write_file(file.path(package_root, "dist", dist_file), dist_file)
  }

  tarball_path <- file.path(output_dir, tarball_name)
  old_wd <- setwd(output_dir)
  on.exit(setwd(old_wd), add = TRUE)
  utils::tar(tarfile = tarball_path, files = "package", compression = "gzip")

  tarball_path
}

fake_fetch_runner <- function(tarball_name = "webawesome.tgz",
                              dist_files = c(
                                "components/wa-button.js",
                                "styles/webawesome.css"
                              ),
                              status = 0L,
                              stdout = NULL,
                              stderr = "") {
  force(tarball_name)
  force(dist_files)
  force(status)
  force(stdout)
  force(stderr)

  function(command, args, wd, env) {
    if (identical(status, 0L)) {
      create_fake_webawesome_tarball(
        output_dir = wd,
        tarball_name = tarball_name,
        dist_files = dist_files
      )
    }

    list(
      status = status,
      stdout = stdout %||% tarball_name,
      stderr = stderr
    )
  }
}

testthat::test_that("fetch uses the pinned version by default", {
  root <- withr::local_tempdir()
  create_fake_repo(root, version = "3.0.0-beta.4")

  result <- fetch_webawesome(
    root = root,
    command_runner = fake_fetch_runner(),
    verbose = FALSE
  )

  testthat::expect_equal(result$version, "3.0.0-beta.4")
  testthat::expect_true(
    dir.exists(file.path(root, "vendor", "webawesome", "3.0.0-beta.4", "dist"))
  )
  testthat::expect_true(
    file.exists(file.path(root, "vendor", "webawesome", "3.0.0-beta.4", "VERSION"))
  )
  testthat::expect_equal(
    readLines(
      file.path(root, "vendor", "webawesome", "3.0.0-beta.4", "VERSION"),
      warn = FALSE
    ),
    "3.0.0-beta.4"
  )
})

testthat::test_that("fetch creates versioned vendor directories and copies only dist", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  result <- fetch_webawesome(
    version = "3.0.0-beta.5",
    root = root,
    command_runner = fake_fetch_runner(),
    verbose = FALSE
  )

  version_root <- file.path(root, "vendor", "webawesome", "3.0.0-beta.5")

  testthat::expect_equal(result$target_dir, "vendor/webawesome/3.0.0-beta.5")
  testthat::expect_true(
    file.exists(file.path(version_root, "dist", "components", "wa-button.js"))
  )
  testthat::expect_true(
    file.exists(file.path(version_root, "dist", "styles", "webawesome.css"))
  )
  testthat::expect_false(file.exists(file.path(version_root, "package")))
})

testthat::test_that("fetch rejects existing fetched versions", {
  root <- withr::local_tempdir()
  create_fake_repo(root)
  dir.create(
    file.path(root, "vendor", "webawesome", "3.0.0-beta.4"),
    recursive = TRUE
  )

  testthat::expect_error(
    fetch_webawesome(
      version = "3.0.0-beta.4",
      root = root,
      command_runner = fake_fetch_runner(),
      verbose = FALSE
    ),
    "Fetched upstream version already exists"
  )
})

testthat::test_that("fetch reports npm pack failures", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  testthat::expect_error(
    fetch_webawesome(
      root = root,
      command_runner = fake_fetch_runner(
        status = 1L,
        stdout = "",
        stderr = "npm exploded"
      ),
      verbose = FALSE
    ),
    "Failed to fetch Web Awesome with npm pack.\nnpm exploded"
  )
})

testthat::test_that("fetch fails if dist is absent from the tarball", {
  root <- withr::local_tempdir()
  create_fake_repo(root)

  testthat::expect_error(
    fetch_webawesome(
      root = root,
      command_runner = fake_fetch_runner(dist_files = character()),
      verbose = FALSE
    ),
    "Fetched package did not contain a dist/ directory."
  )
})

testthat::test_that("fetch rejects non-repository roots", {
  root <- withr::local_tempdir()

  testthat::expect_error(
    fetch_webawesome(root = root, verbose = FALSE),
    "`root` does not appear to be the repository root."
  )
})

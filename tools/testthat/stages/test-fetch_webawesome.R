# nolint start: object_usage_linter.
source(file.path("..", "..", "fetch_webawesome.R"))

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
    stop("Could not locate dev/webawesome-version.txt for the fetch tests.")
  }

  existing[[1]]
}

# Read the repository-pinned Web Awesome version for test fixtures.
.repo_pinned_version <- function() {
  trimws(readLines(.repo_pinned_version_path(), warn = FALSE)[[1]])
}

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root, version = .repo_pinned_version()) {
  dir.create(file.path(root, "dev"), recursive = TRUE, showWarnings = FALSE)
  dir.create(
    file.path(root, "projectdocs"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)
  .write_file(file.path(root, "DESCRIPTION"), "Package: fake")
  .write_file(file.path(root, "dev", "webawesome-version.txt"), version)
}

.create_fake_tarball <- function(output_dir,
                                 tarball_name = "webawesome.tgz",
                                 dist_files = c(
                                   "components/wa-button.js",
                                   "styles/webawesome.css"
                                 ),
                                 dist_cdn_files = dist_files) {
  package_root <- file.path(output_dir, "package")
  dir.create(package_root, recursive = TRUE, showWarnings = FALSE)
  for (dist_file in dist_files) {
    .write_file(file.path(package_root, "dist", dist_file), dist_file)
  }
  for (dist_file in dist_cdn_files) {
    .write_file(file.path(package_root, "dist-cdn", dist_file), dist_file)
  }

  tarball_path <- file.path(output_dir, tarball_name)
  old_wd <- setwd(output_dir)
  on.exit(setwd(old_wd), add = TRUE)
  utils::tar(tarfile = tarball_path, files = "package", compression = "gzip")

  tarball_path
}

.fake_fetch_runner <- function(tarball_name = "webawesome.tgz",
                               dist_files = c(
                                 "components/wa-button.js",
                                 "styles/webawesome.css"
                               ),
                               dist_cdn_files = dist_files,
                               status = 0L,
                               stdout = NULL,
                               stderr = "") {
  force(tarball_name)
  force(dist_files)
  force(dist_cdn_files)
  force(status)
  force(stdout)
  force(stderr)

  function(command, args, wd, env) {
    if (identical(status, 0L)) {
      .create_fake_tarball(
        output_dir = wd,
        tarball_name = tarball_name,
        dist_files = dist_files,
        dist_cdn_files = dist_cdn_files
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
  pinned_version <- .repo_pinned_version()
  .create_fake_repo(root, version = pinned_version)

  result <- fetch_webawesome(
    root = root,
    command_runner = .fake_fetch_runner(),
    verbose = FALSE
  )

  testthat::expect_equal(result$version, pinned_version)
  testthat::expect_true(
    dir.exists(file.path(
      root, "vendor", "webawesome", pinned_version, "dist-cdn"
    ))
  )
  testthat::expect_true(
    file.exists(
      file.path(root, "vendor", "webawesome", pinned_version, "VERSION")
    )
  )
  testthat::expect_equal(
    readLines(
      file.path(root, "vendor", "webawesome", pinned_version, "VERSION"),
      warn = FALSE
    ),
    pinned_version
  )
})

testthat::test_that(
  "fetch creates versioned vendor directories and copies only dist-cdn",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)

    result <- fetch_webawesome(
      version = "3.0.0-beta.5",
      root = root,
      command_runner = .fake_fetch_runner(),
      verbose = FALSE
    )

    version_root <- file.path(root, "vendor", "webawesome", "3.0.0-beta.5")

    testthat::expect_equal(result$target_dir, "vendor/webawesome/3.0.0-beta.5")
    testthat::expect_true(
      file.exists(file.path(
        version_root, "dist-cdn", "components", "wa-button.js"
      ))
    )
    testthat::expect_true(
      file.exists(file.path(
        version_root, "dist-cdn", "styles", "webawesome.css"
      ))
    )
    testthat::expect_false(file.exists(file.path(version_root, "package")))
  }
)

testthat::test_that("fetch requires dist-cdn when the tarball provides both", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  result <- fetch_webawesome(
    version = "3.0.0-beta.5",
    root = root,
    command_runner = .fake_fetch_runner(
      dist_files = c("components/from-dist.js"),
      dist_cdn_files = c("components/from-dist-cdn.js")
    ),
    verbose = FALSE
  )

  version_root <- file.path(root, "vendor", "webawesome", "3.0.0-beta.5")

  testthat::expect_equal(result$target_dir, "vendor/webawesome/3.0.0-beta.5")
  testthat::expect_true(
    file.exists(file.path(
      version_root, "dist-cdn", "components", "from-dist-cdn.js"
    ))
  )
  testthat::expect_false(
    file.exists(file.path(
      version_root, "dist-cdn", "components", "from-dist.js"
    ))
  )
})

testthat::test_that("fetch rejects existing fetched versions", {
  root <- withr::local_tempdir()
  pinned_version <- .repo_pinned_version()
  .create_fake_repo(root)
  dir.create(
    file.path(root, "vendor", "webawesome", pinned_version),
    recursive = TRUE
  )

  testthat::expect_error(
    fetch_webawesome(
      version = pinned_version,
      root = root,
      command_runner = .fake_fetch_runner(),
      verbose = FALSE
    ),
    "Fetched upstream version already exists"
  )
})

testthat::test_that("fetch reports npm pack failures", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    fetch_webawesome(
      root = root,
      command_runner = .fake_fetch_runner(
        status = 1L,
        stdout = "",
        stderr = "npm exploded"
      ),
      verbose = FALSE
    ),
    "Failed to fetch Web Awesome with npm pack.\nnpm exploded"
  )
})

testthat::test_that("fetch fails if dist-cdn is absent from the tarball", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    fetch_webawesome(
      root = root,
      command_runner = .fake_fetch_runner(dist_files = character()),
      verbose = FALSE
    ),
    "Fetched package did not contain a dist-cdn/ directory."
  )
})

testthat::test_that("fetch rejects non-repository roots", {
  root <- withr::local_tempdir()

  testthat::expect_error(
    fetch_webawesome(root = root, verbose = FALSE),
    "`root` does not appear to be the repository root."
  )
})
# nolint end

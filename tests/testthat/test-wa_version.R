test_that("internal version reader validates the shipped version file", {
  path <- withr::local_tempfile(fileext = ".txt")
  writeLines("3.5.0", path)

  expect_identical(
    shiny.webawesome:::.wa_read_version_file(path),
    "3.5.0"
  )

  writeLines(character(), path)
  expect_error(
    shiny.webawesome:::.wa_read_version_file(path),
    "must contain exactly one version"
  )

  expect_error(
    shiny.webawesome:::.wa_read_version_file(
      file.path(tempdir(), "missing-version-file.txt")
    ),
    "Could not find the bundled Web Awesome version file.",
    fixed = TRUE
  )
})

test_that("wa_version reports the bundled Web Awesome version in-source", {
  version_path <- shiny.webawesome:::.wa_version_path()

  expect_identical(
    shiny.webawesome:::.wa_read_version_file(version_path),
    readLines(version_path, warn = FALSE)[[1]]
  )
})

test_that("wa_version_path resolves to an existing shipped version file", {
  version_path <- shiny.webawesome:::.wa_version_path()

  expect_true(file.exists(version_path))
  expect_match(basename(version_path), "^SHINY\\.WEBAWESOME_VERSION$")
})

test_that(
  "wa_version uses the shipped version file when package lookup fails",
  {
    expect_identical(
      shiny.webawesome::wa_version(),
      shiny.webawesome:::.wa_read_version_file(
        shiny.webawesome:::.wa_version_path()
      )
    )
  }
)

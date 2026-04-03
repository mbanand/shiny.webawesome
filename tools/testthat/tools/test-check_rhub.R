source(file.path("..", "..", "check_rhub.R"))

.write_file <- function(path, lines = "x") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path)
}

.create_fake_repo <- function(root, with_workflow = TRUE) {
  dir.create(
    file.path(root, "projectdocs"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(file.path(root, "tools"), recursive = TRUE, showWarnings = FALSE)

  .write_file(file.path(root, "DESCRIPTION"), c(
    "Package: fake",
    "Version: 0.1.0"
  ))

  if (isTRUE(with_workflow)) {
    .write_file(
      file.path(root, ".github", "workflows", "rhub.yaml"),
      "name: rhub"
    )
  }
}

.make_git_runner <- function(branch = "release-candidate",
                             dirty = FALSE,
                             upstream = "origin/release-candidate",
                             default_branch = "main") {
  function(command, args = character(), wd = ".", env = character()) {
    key <- paste(command, paste(args, collapse = " "))

    if (identical(key, "git rev-parse --abbrev-ref HEAD")) {
      return(list(status = 0L, stdout = branch, stderr = ""))
    }

    if (identical(
      key,
      "git rev-parse --abbrev-ref --symbolic-full-name @{u}"
    )) {
      if (is.null(upstream)) {
        return(list(status = 1L, stdout = "", stderr = "no upstream"))
      }

      return(list(status = 0L, stdout = upstream, stderr = ""))
    }

    if (identical(key, "git symbolic-ref refs/remotes/origin/HEAD")) {
      if (is.null(default_branch)) {
        return(list(status = 1L, stdout = "", stderr = "no origin HEAD"))
      }

      return(list(
        status = 0L,
        stdout = paste0("refs/remotes/origin/", default_branch),
        stderr = ""
      ))
    }

    if (identical(key, "git status --porcelain")) {
      return(list(
        status = 0L,
        stdout = if (isTRUE(dirty)) " M file" else "",
        stderr = ""
      ))
    }

    stop("Unexpected git invocation: ", key, call. = FALSE)
  }
}

testthat::test_that("check_rhub prints help", {
  result <- paste(capture.output(run_check_rhub("--help")), collapse = "\n")

  testthat::expect_match(result, "Usage: ./tools/check_rhub.R")
  testthat::expect_match(result, "--platform")
  testthat::expect_match(result, "--allow-main")
  testthat::expect_match(result, "--skip-doctor")
})

testthat::test_that("check_rhub uses defaults when no platform is supplied", {
  options <- .parse_rhub_args(character())

  testthat::expect_identical(
    options$platforms,
    c("linux", "macos", "macos-arm64", "windows")
  )
})

testthat::test_that("check_rhub platform arguments override defaults", {
  options <- .parse_rhub_args(c(
    "--platform", "linux",
    "--platform=windows"
  ))

  testthat::expect_identical(
    options$platforms,
    c("linux", "windows")
  )
})

testthat::test_that("check_rhub refuses to run from main by default", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  doctor_called <- FALSE
  check_called <- FALSE

  testthat::expect_error(
    check_rhub(
      root = root,
      verbose = FALSE,
      git_runner = .make_git_runner(branch = "main", upstream = "origin/main"),
      doctor_fun = function() {
        doctor_called <<- TRUE
      },
      check_fun = function(branch, platforms) {
        check_called <<- TRUE
      }
    ),
    "Main-branch rhub runs require explicit override"
  )

  testthat::expect_false(doctor_called)
  testthat::expect_false(check_called)
})

testthat::test_that("check_rhub also guards master when it is default", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    check_rhub(
      root = root,
      verbose = FALSE,
      git_runner = .make_git_runner(
        branch = "master",
        upstream = "origin/master",
        default_branch = "master"
      ),
      doctor_fun = function() NULL,
      check_fun = function(branch, platforms) NULL
    ),
    "Main-branch rhub runs require explicit override"
  )
})

testthat::test_that("check_rhub requires a pushed upstream branch", {
  root <- withr::local_tempdir()
  .create_fake_repo(root)

  testthat::expect_error(
    check_rhub(
      root = root,
      verbose = FALSE,
      git_runner = .make_git_runner(upstream = NULL),
      doctor_fun = function() NULL,
      check_fun = function(branch, platforms) NULL
    ),
    "Rhub checks require a pushed branch"
  )
})

testthat::test_that(
  "check_rhub runs doctor then check for the current branch",
  {
    root <- withr::local_tempdir()
    .create_fake_repo(root)

    calls <- list()

    result <- check_rhub(
      root = root,
      verbose = FALSE,
      git_runner = .make_git_runner(),
      doctor_fun = function() {
        calls[[length(calls) + 1L]] <<- "doctor"
        invisible(NULL)
      },
      check_fun = function(branch, platforms) {
        calls[[length(calls) + 1L]] <<- list(
          type = "check",
          branch = branch,
          platforms = platforms
        )
        invisible(NULL)
      }
    )

    testthat::expect_identical(
      calls,
      list(
        "doctor",
        list(
          type = "check",
          branch = "release-candidate",
          platforms = c("linux", "macos", "macos-arm64", "windows")
        )
      )
    )
    testthat::expect_identical(result$branch, "release-candidate")
    testthat::expect_identical(result$upstream, "origin/release-candidate")
    testthat::expect_identical(
      result$platforms,
      c("linux", "macos", "macos-arm64", "windows")
    )
    testthat::expect_true(isTRUE(result$ran_doctor))
  }
)

testthat::test_that("check_rhub requires the rhub workflow file", {
  root <- withr::local_tempdir()
  .create_fake_repo(root, with_workflow = FALSE)

  testthat::expect_error(
    check_rhub(
      root = root,
      verbose = FALSE,
      git_runner = .make_git_runner(),
      doctor_fun = function() NULL,
      check_fun = function(branch, platforms) NULL
    ),
    "Rhub workflow file is not present in the repository"
  )
})

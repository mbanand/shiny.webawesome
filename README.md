# shiny.webawesome <a href="https://www.shiny-webawesome.org"><img src="man/figures/logo.svg" align="right" height="139" alt="shiny.webawesome website" /></a>

<!-- badges: start -->
<!--
[![CRAN status](https://www.r-pkg.org/badges/version/shiny.webawesome)](https://CRAN.R-project.org/package=shiny.webawesome)
-->
![CRAN status](https://img.shields.io/badge/CRAN-not%20published-lightgrey)
[![R-CMD-check](https://github.com/mbanand/shiny.webawesome/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mbanand/shiny.webawesome/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/mbanand/shiny.webawesome/graph/badge.svg)](https://app.codecov.io/gh/mbanand/shiny.webawesome)
<!-- badges: end -->

`shiny.webawesome` provides an R and [Shiny](https://shiny.posit.co)
interface to the [Web Awesome](https://webawesome.com) component library.

The package is largely generated from the upstream Web Awesome metadata file
`custom-elements.json`, which the package treats as the primary source of
truth for component wrappers and related generated surface. It also bundles
the Web Awesome runtime it needs, so package users do not need to install Web
Awesome assets separately in their Shiny apps. To report the bundled Web
Awesome version in your current installation, use `wa_version()`.

The package design aims to stay as close as practical to upstream Web Awesome
names, conventions, and component APIs, while adopting normal R naming
conventions such as `snake_case`. Because Web Awesome lives in the browser
and Shiny spans both server and client, the package also includes a curated
set of Shiny bindings plus a narrow helper/command layer for cases where a
pure wrapper mirror is not enough.

See the package documentation for the details of the generated wrapper
surface, Shiny bindings, and advanced browser-glue helpers.

## Installation

To install from CRAN, use either of the following:

```r
install.packages("shiny.webawesome")
```

```r
pak::pak("shiny.webawesome")
```

To install the development version from GitHub, use either of the following:

```r
pak::pak("mbanand/shiny.webawesome")
```

```r
remotes::install_github("mbanand/shiny.webawesome")
```

## Usage

```r
library(shiny)
library(shiny.webawesome)

ui <- webawesomePage(
  title = "shiny.webawesome",
  wa_button(
    "example_button",
    "Click me",
    appearance = "filled"
  )
)

server <- function(input, output, session) {
}

shinyApp(ui, server)
```

You can use `shiny.webawesome` in two ways:

- use individual Web Awesome components inside an ordinary Shiny page such as
  `fluidPage()`
- build the whole app page with `webawesomePage()`

If you only need a few components inside an otherwise ordinary Shiny app,
using them inside `fluidPage()` is fine. The package attaches its runtime
dependencies automatically in that case.

```r
library(shiny)
library(shiny.webawesome)

ui <- fluidPage(
  h2("Mixed app"),
  wa_card(
    wa_badge("Beta", appearance = "filled"),
    "This app uses a few Web Awesome components inside fluidPage()."
  )
)

server <- function(input, output, session) {}

shinyApp(ui, server)
```

If Web Awesome is the main UI system for the app, prefer `webawesomePage()`.
It attaches the package dependency once at page level and gives you a cleaner
full-page Web Awesome setup.

When you mix Web Awesome components into `fluidPage()` or another Bootstrap
layout, check the result in the browser. The components will work, but your
app may still need light CSS review for spacing, typography, or theme/style
mismatches between Bootstrap and Web Awesome.

## Documentation

- Package website: <https://www.shiny-webawesome.org>
- Source repository: <https://github.com/mbanand/shiny.webawesome>
- Bug reports: <https://github.com/mbanand/shiny.webawesome/issues>
- Package help pages: use `?topic` in R, for example `?wa_button`
- Long-form package docs: installed vignettes and website articles

## Contributing

Feedback from package users is welcome, both on the package API and on
improvements to documentation for accuracy, clarity, or ease of learning.

Contributions are also welcome, especially from front-end developers and Web
Awesome users who can help improve package ergonomics, examples, and API
coverage.

Please see contributing guidance in [CONTRIBUTING.md](CONTRIBUTING.md).

Repository project and workflow documentation is in the repo's
`projectdocs/` directory.

## Coding Agents

For package users, the published [`llms.txt`](https://www.shiny-webawesome.org/llms.txt)
file provides a machine-readable overview of the package API for coding
agents and other LLM-based tools.

For repository development guidance, including coding-agent workflow and repo
rules, see [CONTRIBUTING.md](CONTRIBUTING.md).

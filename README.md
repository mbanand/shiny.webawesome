# shiny.webawesome

`shiny.webawesome` provides an R and Shiny interface to the Web Awesome
component library.

The package is largely generated from the upstream Web Awesome metadata file
`custom-elements.json`, which the package treats as the primary source of
truth for component wrappers and related generated surface.

The package design aims to stay as close as practical to upstream Web Awesome
names, conventions, and component APIs, while adopting normal R naming
conventions such as `snake_case`. Because Web Awesome lives in the browser
and Shiny spans both server and client, the package also includes a curated
set of Shiny bindings plus a narrow helper/command layer for cases where a
pure wrapper mirror is not enough.

See the package documentation for the details of the generated wrapper
surface, Shiny bindings, and advanced browser-glue helpers.

## Installation

CRAN submission is in progress. Once the package is available on CRAN, install
it with either of the following:

```r
install.packages("shiny.webawesome")
```

```r
pak::pak("shiny.webawesome")
```

To install the development version from GitHub:

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

ui <- wa_page(
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

## Documentation

- Package website: <https://www.shiny-webawesome.org>
- Source repository: <https://github.com/mbanand/shiny.webawesome>
- Bug reports: <https://github.com/mbanand/shiny.webawesome/issues>
- Package help pages: use `?topic` in R, for example `?wa_button`
- Long-form package docs: installed vignettes and website articles

## Contributing

Feedback is welcome, especially from users who notice rough edges in the
documentation or places where the package could be easier to learn.

Contributions are also welcome, especially from front-end developers and Web
Awesome users who can help improve package ergonomics, examples, and API
coverage.

Please see contributing guidance in [CONTRIBUTING.md](CONTRIBUTING.md).

Repository project and workflow documentation is in the repo's
`projectdocs/` directory.

## Coding Agents

For package users, the published `llms.txt` file provides a machine-readable
overview of the package API for coding agents and other LLM-based tools.

For repository development guidance, including coding-agent workflow and repo
rules, see [CONTRIBUTING.md](CONTRIBUTING.md).

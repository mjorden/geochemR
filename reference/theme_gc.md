# The geochemR look: academic parchment, Tufte restraint

Every plot in the package is drawn with `theme_gc()` and the
`scale_*_gc()` scales. The palette is a sibling of the *academic* style
in [econscape](https://github.com/mjorden/econscape): parchment
surfaces, brown ink, a tan-to-espresso categorical palette, a rust
accent, serif type. The furniture follows Tufte rather than a newspaper:
no panel fill behind the data (the parchment is the page, not the
chart), no gridlines unless asked for, hairline axes with outward ticks,
muted axis titles, a legend that reads as a row of labels - or, on depth
profiles, no legend at all and the hole names written at the bottom of
each trace.

## Usage

``` r
theme_gc(
  base_size = 11,
  base_family = "serif",
  grid = c("none", "y", "x", "both"),
  axis = c("both", "x", "y", "none"),
  legend_position = "top",
  panel = c("page", "parchment")
)

gc_colours(...)

gc_pal(palette = "academic", reverse = FALSE)

scale_colour_gc(palette = "academic", reverse = FALSE, ...)

scale_fill_gc(palette = "academic", reverse = FALSE, ...)

scale_colour_gc_c(palette = "browns", reverse = FALSE, ...)

scale_fill_gc_c(palette = "browns", reverse = FALSE, ...)

scale_color_gc(palette = "academic", reverse = FALSE, ...)

scale_color_gc_c(palette = "browns", reverse = FALSE, ...)
```

## Arguments

- base_size:

  Base font size in points.

- base_family:

  Font family; `"serif"` by default.

- grid:

  Major gridlines: `"none"` (default), `"y"`, `"x"` or `"both"`. When
  drawn they are hairlines in the parchment grid colour.

- axis:

  Which axis lines to draw: `"both"` (default), `"x"`, `"y"` or
  `"none"`.

- legend_position:

  Passed to
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html);
  `"top"` by default.

- panel:

  `"page"` (default: transparent panel on a parchment page) or
  `"parchment"` (panel filled too, closer to econscape).

- ...:

  For `gc_colours()`: colour names; none returns the dictionary.

- palette:

  `"academic"` (categorical, 11 colours), or a sequential ramp:
  `"browns"` (default for continuous scales), `"rust"`, `"moss"`.

- reverse:

  Reverse the palette.

## Value

A ggplot2 theme.

`gc_pal()` returns a function of `n`; categorical palettes interpolate
beyond their length rather than error.

## Colours

`gc_colours()` returns the dictionary. Categorical: `espresso`, `tan`,
`sand`, `walnut`, `parchment_dark`, `bark`, `stone`, then `rust`,
`moss`, `slate`, `ochre` for more than seven groups. Surfaces:
`parchment`, `parchment_grid`; ink: `ink`, `muted`; accent: `rust`;
maturity windows: `window_immature`, `window_oil`, `window_gas`.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point(size = 2) +
  scale_colour_gc() +
  labs(title = "Weight and economy", subtitle = "mtcars, 1974", colour = "Cylinders") +
  theme_gc()
```

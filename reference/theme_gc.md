# The geochemR look: academic parchment, Tufte restraint, colour where it counts

Every plot in the package is drawn with `theme_gc()` and the
`scale_*_gc()` scales. The furniture is a sibling of the *academic*
style in [econscape](https://github.com/mjorden/econscape): parchment
surfaces, brown ink, serif type. It follows Tufte rather than a
newspaper: no panel fill behind the data (the parchment is the page, not
the chart), no gridlines unless asked for, hairline axes with outward
ticks, muted axis titles, a legend that reads as a row of labels - or,
on depth profiles of two or three holes, no legend at all and the hole
names written at the bottom of each trace. The furniture being
monochrome is what lets the data carry colour: the categorical palette
rotates through distinct hues muted to sit on parchment, and continuous
scales use a multi-hue ramp so that both level and gradient read.

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

gc_mineral_colours

gc_pal(palette = "academic", reverse = FALSE)

scale_colour_gc(palette = "academic", reverse = FALSE, ...)

scale_fill_gc(palette = "academic", reverse = FALSE, ...)

scale_colour_gc_c(palette = "scholar", reverse = FALSE, ...)

scale_fill_gc_c(palette = "scholar", reverse = FALSE, ...)

scale_fill_minerals(minerals = NULL, ...)

scale_color_gc(palette = "academic", reverse = FALSE, ...)

scale_color_gc_c(palette = "scholar", reverse = FALSE, ...)
```

## Format

`gc_mineral_colours`: fill colours for XRD minerals keyed by canonical
name, grouped by kind so a stacked bar reads at a glance -
tectosilicates in warm yellows and tans, carbonates in blues, clays in
greens, sulfides dark, everything else grey or violet.

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

  For `gc_colours()`: colour names; none returns the dictionary. For the
  scales: passed to the ggplot2 scale.

- palette:

  `"academic"` (categorical: espresso, rust, slate, moss, ochre, plum,
  teal, tan, indigo, brick, sage); sequential ramps `"scholar"` (default
  for continuous scales: sand through ochre and rust to plum and ink),
  `"tide"` (sand through sage and teal to indigo), `"browns"`, `"rust"`,
  `"moss"`; or `"divergent"` (slate - parchment - rust).

- reverse:

  Reverse the palette.

- minerals:

  Mineral names present in the data; any not in `gc_mineral_colours` get
  colours from the categorical palette.

## Value

A ggplot2 theme.

`gc_pal()` returns a function of `n`; the categorical palette
interpolates beyond its length rather than error.

`scale_fill_minerals()` is a manual fill scale keyed by canonical
mineral name.

## Colours

`gc_colours()` returns the dictionary. Categorical hues: `espresso`,
`rust`, `slate`, `moss`, `ochre`, `plum`, `teal`, `tan`, `indigo`,
`brick`, `sage`. Surfaces: `parchment`, `parchment_grid`; ink: `ink`,
`muted`; maturity windows: `window_immature`, `window_oil`,
`window_gas`. `gc_mineral_colours` colours XRD minerals by kind.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point(size = 2) +
  scale_colour_gc() +
  labs(title = "Weight and economy", subtitle = "mtcars, 1974", colour = "Cylinders") +
  theme_gc()
```

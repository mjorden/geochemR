# Hole-by-depth heatmap

Holes across, depth down, tile colour = value of one analyte. Holes are
ordered by `x` (or by `order`) so lateral trends read left to right.

## Usage

``` r
plot_depth_heatmap(
  ds,
  method,
  analyte,
  breaks = NULL,
  order = "x",
  palette = "viridis"
)
```

## Arguments

- ds:

  A `gc_data` object.

- method, analyte:

  Which analyte.

- breaks:

  Depth-bin width (or vector of breaks) passed to
  [`gc_interval_stats()`](https://mjorden.github.io/geochemR/reference/gc_interval_stats.md);
  `NULL` uses each sample's own interval.

- order:

  Hole order: `"x"`, `"y"`, or a character vector.

- palette:

  A viridis option name (`"viridis"`, `"magma"`, …).

## Value

A ggplot.

## Examples

``` r
plot_depth_heatmap(gc_example, "SRA", "TOC")
```

# Stacked mineralogy bars

XRD composition per sample as stacked bars, grouped by mineral group,
one facet per hole, ordered by depth.

## Usage

``` r
plot_mineralogy(
  ds,
  holes = NULL,
  exclude = c("total_clay", "total", "carbonate", "clay", "QFM", "BI_min")
)
```

## Arguments

- ds:

  A `gc_data` object.

- holes:

  Optional subset.

- exclude:

  Analytes to leave out (defaults to totals and derived rows).

## Value

A ggplot.

## Examples

``` r
plot_mineralogy(gc_example, holes = c("H01", "H12"))
```

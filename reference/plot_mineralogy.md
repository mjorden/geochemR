# Stacked mineralogy bars

XRD composition per sample interval as stacked bars, minerals grouped
(tectosilicates, carbonates, clays, sulfides, other), one facet per
hole.

## Usage

``` r
plot_mineralogy(
  ds,
  holes = NULL,
  exclude = c("total_clay", "total", "carbonate", "clay", "QFM", "BI", "BI_min", "BI_w")
)
```

## Arguments

- ds:

  A `gc_data` object.

- holes:

  Optional subset.

- exclude:

  Analytes to leave out (totals and derived sums by default).

## Value

A ggplot.

## Examples

``` r
plot_mineralogy(gc_example, holes = c("H01", "H12"))

plot_mineralogy(gc_cuttings)
```

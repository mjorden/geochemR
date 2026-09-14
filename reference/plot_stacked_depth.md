# Stacked composition against depth

Horizontal stacked bars, one per sample interval, for a set of analytes
that add up to something meaningful: XRD minerals
([`plot_mineralogy()`](https://mjorden.github.io/geochemR/reference/plot_mineralogy.md))
or the PAM pyrolysis fractions
([`plot_pam()`](https://mjorden.github.io/geochemR/reference/plot_pam.md)).
One facet per hole.

## Usage

``` r
plot_stacked_depth(
  ds,
  method,
  analytes,
  holes = NULL,
  normalize = FALSE,
  xlab = NULL,
  fill_scale = NULL
)
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  Method.

- analytes:

  Analytes to stack, bottom to top of the legend.

- holes:

  Optional subset.

- normalize:

  Rescale each sample to 100 %.

- xlab:

  x-axis label.

- fill_scale:

  A ggplot2 fill scale to use instead of
  [`scale_fill_gc()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  (e.g.
  [`scale_fill_minerals()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)).

## Value

A ggplot.

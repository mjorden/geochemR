# Planar map of one analyte

Summarises each hole over a depth window
([`gc_hole_summary()`](https://mjorden.github.io/geochemR/reference/gc_hole_summary.md))
and draws the holes as points coloured by the value, optionally over an
IDW surface with contours.

## Usage

``` r
plot_map(
  ds,
  method,
  analyte,
  depth = NULL,
  fun = mean,
  interp = TRUE,
  n = 80,
  power = 2,
  nmax = 12,
  maxdist = Inf,
  contours = 6,
  label = TRUE,
  palette = "viridis"
)
```

## Arguments

- ds:

  A `gc_data` object.

- method, analyte:

  Which analyte.

- depth:

  Optional `c(top, base)` window; default: whole hole.

- fun:

  Summary function per hole (default `mean`; `max` for a "hottest
  sample" map).

- interp:

  Draw an IDW surface (`TRUE`) under the points.

- n, power, nmax, maxdist:

  Grid resolution and IDW controls.

- contours:

  Number of contour bins on the surface (0 for none).

- label:

  Label the points with the hole id.

- palette:

  Viridis option.

## Value

A ggplot with `coord_equal()`.

## Examples

``` r
plot_map(gc_example, "SRA", "TOC", depth = c(60, 120))

plot_map(gc_example, "XRD", "quartz", interp = FALSE)
```

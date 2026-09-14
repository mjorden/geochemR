# Ternary diagram

Three parts of a composition (renormalised to 100 per sample) plotted in
barycentric coordinates — no extra package needed. Typical uses:
`c("quartz", "carbonate", "clay")` after
[`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md),
or `c("SiO2", "Al2O3", "CaO")`.

## Usage

``` r
plot_ternary(ds, method, parts, colour = "hole_id", holes = NULL)
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  Method.

- parts:

  Three analyte names, in order bottom-left, top, bottom-right.

- colour:

  Column of the sample table (or `"hole_id"`, `"depth_mid"`) to colour
  by.

- holes:

  Optional subset.

## Value

A ggplot.

## Examples

``` r
plot_ternary(gc_indices(gc_example), "XRD", c("quartz", "carbonate", "clay"), colour = "depth_mid")
#> Warning: Removed 69 rows containing missing values or values outside the scale range
#> (`geom_point()`).
```

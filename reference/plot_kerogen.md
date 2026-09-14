# Kerogen-type and maturity plots from pyrolysis

`type = "hi_oi"` - pseudo-van Krevelen (HI vs OI) with the conventional
Type I / II / III trend lines; `type = "hi_tmax"` - HI vs Tmax with
maturity windows (immature \< 435 degC, oil 435-470, gas \> 470);
`type = "s2_toc"` - S2 vs TOC, whose slope is the HI of the sample set
(and whose intercept exposes a mineral-matrix effect). Needs
[`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
to have been run for HI / OI.

## Usage

``` r
plot_kerogen(
  ds,
  type = c("hi_oi", "hi_tmax", "s2_toc"),
  colour = "hole_id",
  holes = NULL
)
```

## Arguments

- ds:

  A `gc_data` object.

- type:

  Which plot.

- colour:

  Column to colour by (`"hole_id"`, `"depth_mid"`, `"formation"`, ...).

- holes:

  Optional subset.

## Value

A ggplot.

## Examples

``` r
ds <- gc_indices(gc_example)
plot_kerogen(ds, "hi_oi")
#> Warning: Removed 116 rows containing missing values or values outside the scale range
#> (`geom_point()`).

plot_kerogen(gc_indices(gc_cuttings), "hi_tmax", colour = "formation")
#> Warning: Removed 22 rows containing missing values or values outside the scale range
#> (`geom_point()`).
```

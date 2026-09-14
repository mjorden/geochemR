# Inverse-distance-weighted interpolation to a grid

Plain IDW in one or two dimensions with an optional search radius and
neighbour cap; used by
[`plot_map()`](https://mjorden.github.io/geochemR/reference/plot_map.md)
and
[`plot_section()`](https://mjorden.github.io/geochemR/reference/plot_section.md).
Exact at data points.

## Usage

``` r
gc_idw(x, y = NULL, v, gx, gy = NULL, power = 2, nmax = Inf, maxdist = Inf)
```

## Arguments

- x, y, v:

  Coordinates and values of the data points (`y` may be `NULL` for a 1-D
  problem).

- gx, gy:

  Grid coordinates to predict at (`gy` `NULL` for 1-D).

- power:

  Distance exponent (2 = classic IDW).

- nmax:

  Use only the `nmax` nearest points.

- maxdist:

  Ignore points farther than this; grid cells with no point inside
  `maxdist` get `NA`.

## Value

A numeric vector of predictions, one per grid point.

## Examples

``` r
gc_idw(c(0, 1, 2), c(0, 0, 0), c(1, 2, 3), gx = 0.5, gy = 0)
#> [1] 1.578947
```

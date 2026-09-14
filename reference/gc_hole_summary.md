# Per-hole (or per-formation) summary

Per-hole (or per-formation) summary

## Usage

``` r
gc_hole_summary(
  ds,
  method,
  depth = NULL,
  fun = mean,
  analytes = NULL,
  by = "hole_id"
)
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  Method.

- depth:

  Optional `c(top, base)` window.

- fun:

  Summary function.

- analytes:

  Optional subset.

- by:

  Grouping: `"hole_id"` (default), or `c("hole_id", "formation")`,
  `c("hole_id", "zone")` ... for stratigraphic summaries of a cuttings
  well.

## Value

One row per group with `x`, `y`, `n`, `depth_top`, `depth_base` and one
column per analyte.

## Examples

``` r
gc_hole_summary(gc_example, "SRA", analytes = c("TOC", "Tmax"))
#> # A tibble: 12 × 8
#>    hole_id       x        y     n depth_top depth_base   TOC  Tmax
#>    <chr>     <dbl>    <dbl> <int>     <dbl>      <dbl> <dbl> <dbl>
#>  1 H01     500019. 4199999.    15         0        150  1.26  434.
#>  2 H02     500415. 4199999.    15         2        152  1.27  433.
#>  3 H03     500773. 4199989.    15         0        150  1.13  436.
#>  4 H04     501230. 4199966.    15         1        151  1.80  440.
#>  5 H05     500011. 4200389.    15         1        151  1.01  435.
#>  6 H06     500427. 4200410.    15         3        153  1.23  439.
#>  7 H07     500812. 4200448.    15         4        154  1.50  438.
#>  8 H08     501190. 4200400.    15         0        150  2.00  440.
#>  9 H09     500007. 4200776.    15         3        153  1.38  433.
#> 10 H10     500420. 4200792.    15         2        152  1.27  437.
#> 11 H11     500814. 4200799.    15         3        153  1.96  439.
#> 12 H12     501203. 4200768.    15         3        153  1.76  440.
```

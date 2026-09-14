# Per-hole summary

Per-hole summary

## Usage

``` r
gc_hole_summary(ds, method, depth = NULL, fun = mean, analytes = NULL)
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

## Value

One row per hole with `x`, `y`, `n` and one column per analyte.

## Examples

``` r
gc_hole_summary(gc_example, "SRA", analytes = c("TOC", "Tmax"))
#> # A tibble: 12 × 6
#>    hole_id       x        y     n   TOC  Tmax
#>    <chr>     <dbl>    <dbl> <int> <dbl> <dbl>
#>  1 H01     500019. 4199999.    15  1.26  434.
#>  2 H02     500415. 4199999.    15  1.27  433.
#>  3 H03     500773. 4199989.    15  1.13  436.
#>  4 H04     501230. 4199966.    15  1.80  440.
#>  5 H05     500011. 4200389.    15  1.01  435.
#>  6 H06     500427. 4200410.    15  1.23  439.
#>  7 H07     500812. 4200448.    15  1.50  438.
#>  8 H08     501190. 4200400.    15  2.00  440.
#>  9 H09     500007. 4200776.    15  1.38  433.
#> 10 H10     500420. 4200792.    15  1.27  437.
#> 11 H11     500814. 4200799.    15  1.96  439.
#> 12 H12     501203. 4200768.    15  1.76  440.
```

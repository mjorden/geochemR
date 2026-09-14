# Interval statistics per hole

Aggregates one method's analytes into depth bins per hole - the step
between sample tables and anything gridded or mapped.

## Usage

``` r
gc_interval_stats(ds, method, breaks = 10, fun = mean, analytes = NULL)
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  Method to aggregate.

- breaks:

  Depth-bin breaks (a numeric vector), or a single bin width.

- fun:

  Summary function (default `mean`).

- analytes:

  Optional subset.

## Value

A tibble: `hole_id`, `x`, `y`, `bin_top`, `bin_base`, `n` (samples whose
midpoint falls in the bin), then one column per analyte. A bin with no
observation of an analyte is `NA`, never `NaN` or `-Inf`.

## Examples

``` r
gc_interval_stats(gc_example, "SRA", breaks = 50)
#> # A tibble: 36 × 11
#>    hole_id      x      y bin_top bin_base     n   TOC     S1      S2    S3  Tmax
#>    <chr>    <dbl>  <dbl>   <dbl>    <dbl> <int> <dbl>  <dbl>   <dbl> <dbl> <dbl>
#>  1 H01     5.00e5 4.20e6       0       50     5 0.36  0.03    0.367  0.67   429 
#>  2 H01     5.00e5 4.20e6      50      100     5 2.50  1.14   12.8    0.216  434.
#>  3 H01     5.00e5 4.20e6     100      150     5 0.566 0.264   2.63   0.622  442 
#>  4 H02     5.00e5 4.20e6       0       50     5 0.262 0.044   0.308  0.636  426 
#>  5 H02     5.00e5 4.20e6      50      100     5 3.32  1.42   15.4    0.387  436 
#>  6 H02     5.00e5 4.20e6     100      150     5 0.98  0.362   3.88   0.545  436 
#>  7 H03     5.01e5 4.20e6       0       50     5 0.37  0.0467  0.353  0.65   430.
#>  8 H03     5.01e5 4.20e6      50      100     5 3.80  1.47   16.1    0.335  442.
#>  9 H03     5.01e5 4.20e6     100      150     5 0.103 0.03    0.0833 0.797   NA 
#> 10 H04     5.01e5 4.20e6       0       50     5 1.40  0.452   4.72   0.538  435.
#> # ℹ 26 more rows
```

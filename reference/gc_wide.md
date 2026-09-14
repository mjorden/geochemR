# Wide table of one method's results joined to the sample table

Wide table of one method's results joined to the sample table

## Usage

``` r
gc_wide(ds, method, analytes = NULL, values = "value")
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  Which method to widen (one of the values in
  `gc_measurements(ds)$method`).

- analytes:

  Optional subset of analytes.

- values:

  Which column to spread: `"value"` (default) or `"qualifier"`.

## Value

A tibble: sample columns, then one column per analyte.

## Examples

``` r
head(gc_wide(gc_example, "SRA"))
#> # A tibble: 6 × 15
#>   sample_id hole_id       x        y     z depth_top depth_base sample_type
#>   <chr>     <chr>     <dbl>    <dbl> <dbl>     <dbl>      <dbl> <chr>      
#> 1 H01-000   H01     500019. 4199999. 1254.         0         10 core       
#> 2 H01-010   H01     500019. 4199999. 1254.        10         20 cuttings   
#> 3 H01-020   H01     500019. 4199999. 1254.        20         30 cuttings   
#> 4 H01-030   H01     500019. 4199999. 1254.        30         40 core       
#> 5 H01-040   H01     500019. 4199999. 1254.        40         50 cuttings   
#> 6 H01-050   H01     500019. 4199999. 1254.        50         60 cuttings   
#> # ℹ 7 more variables: date <date>, depth_mid <dbl>, TOC <dbl>, S1 <dbl>,
#> #   S2 <dbl>, S3 <dbl>, Tmax <dbl>
```

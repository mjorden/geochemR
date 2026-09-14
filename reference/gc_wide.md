# Wide table of one method's results joined to the sample table

One row per sample, one column per analyte. A (sample, analyte) key that
has more than one row is resolved by `prefer`: the first origin in the
vector that is present wins (so a laboratory's own HI beats the one
[`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
computed, and both beat nothing). Rows that still collide after that -
the same analyte from two labs, or exact duplicates - are an error
unless `fun` says how to combine them; `gc_wide()` never averages
silently. Analytes reported in more than one unit across the surviving
rows are an error too: convert with
[`gc_convert_units()`](https://mjorden.github.io/geochemR/reference/gc_convert_units.md)
first.

## Usage

``` r
gc_wide(
  ds,
  method,
  analytes = NULL,
  values = "value",
  prefer = c("measured", "reported", "derived"),
  fun = NULL
)
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

- prefer:

  Origins in order of preference when a key has rows of more than one
  origin (default `c("measured", "reported", "derived")`).

- fun:

  Function to combine rows that remain duplicated after `prefer` (e.g.
  `mean`); `NULL` (default) makes them an error.

## Value

A tibble: sample columns, then one column per analyte.

## Examples

``` r
head(gc_wide(gc_example, "SRA"))
#> # A tibble: 6 × 17
#>   sample_id hole_id       x        y     z depth_top depth_base sample_type
#>   <chr>     <chr>     <dbl>    <dbl> <dbl>     <dbl>      <dbl> <chr>      
#> 1 H01-000   H01     500019. 4199999. 1254.         0         10 core       
#> 2 H01-010   H01     500019. 4199999. 1254.        10         20 cuttings   
#> 3 H01-020   H01     500019. 4199999. 1254.        20         30 cuttings   
#> 4 H01-030   H01     500019. 4199999. 1254.        30         40 core       
#> 5 H01-040   H01     500019. 4199999. 1254.        40         50 cuttings   
#> 6 H01-050   H01     500019. 4199999. 1254.        50         60 cuttings   
#> # ℹ 9 more variables: formation <lgl>, zone <lgl>, date <date>,
#> #   depth_mid <dbl>, TOC <dbl>, S1 <dbl>, S2 <dbl>, S3 <dbl>, Tmax <dbl>
```

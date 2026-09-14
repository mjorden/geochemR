# Oxide / element conversion for XRF

`gc_oxide_to_element()` rewrites oxide rows (`SiO2`, `Al2O3`, …) as
their element (`Si`, `Al`, …) using the mass factors in
[gc_oxides](https://mjorden.github.io/geochemR/reference/dictionaries.md);
`gc_element_to_oxide()` does the reverse for elements that have a
conventional oxide. Units are unchanged (a wt% oxide gives a wt%
element).

## Usage

``` r
gc_oxide_to_element(ds, keep = FALSE)

gc_element_to_oxide(ds, keep = FALSE)
```

## Arguments

- ds:

  A `gc_data` object.

- keep:

  Keep the original rows as well (default `FALSE`: replace).

## Value

`ds`.

## Examples

``` r
gc_measurements(gc_oxide_to_element(gc_example), "XRF")
#> # A tibble: 2,340 × 9
#>    sample_id method analyte value unit    lod qualifier lab             source  
#>    <chr>     <chr>  <chr>   <dbl> <chr> <dbl> <chr>     <chr>           <chr>   
#>  1 H01-000   XRF    LOI      7.54 wt%      NA NA        Example XRF Lab synthet…
#>  2 H01-010   XRF    LOI      0.27 wt%      NA NA        Example XRF Lab synthet…
#>  3 H01-020   XRF    LOI      4.25 wt%      NA NA        Example XRF Lab synthet…
#>  4 H01-030   XRF    LOI      4.92 wt%      NA NA        Example XRF Lab synthet…
#>  5 H01-040   XRF    LOI      1.08 wt%      NA NA        Example XRF Lab synthet…
#>  6 H01-050   XRF    LOI     17.0  wt%      NA NA        Example XRF Lab synthet…
#>  7 H01-060   XRF    LOI     17.8  wt%      NA NA        Example XRF Lab synthet…
#>  8 H01-070   XRF    LOI     18.3  wt%      NA NA        Example XRF Lab synthet…
#>  9 H01-080   XRF    LOI     17.6  wt%      NA NA        Example XRF Lab synthet…
#> 10 H01-090   XRF    LOI     19.2  wt%      NA NA        Example XRF Lab synthet…
#> # ℹ 2,330 more rows
```

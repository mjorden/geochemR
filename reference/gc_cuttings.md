# Synthetic cuttings-analysis well

One well, 65 cuttings samples at 30-ft intervals from 6,000 to 7,950 ft
through four formations (an upper shale, an organic-rich target shale
with two zones, a carbonate, a lower sand), carrying everything a
commercial cuttings-analysis deliverable does: LECO and pyrolysis TOC,
traditional pyrolysis (S1, S2, S3, Tmax), multi-ramp PAM pyrolysis
fractions with their Tmax, XRD bulk mineralogy, XRD clay speciation
(reported relative to total clay and converted on read), and XRF
elements in % with traces in ppm (Mo, As, U, Co partly censored).

## Usage

``` r
gc_cuttings
```

## Format

A `gc_data` object with `formation` and `zone` on the samples.

## Details

The same data is shipped as an Excel workbook in the deliverable's
three-row-header layout -
`system.file("extdata", "cuttings_workbook.xlsx", package = "geochemR")` -
and `gc_cuttings` is simply
[`read_workbook()`](https://mjorden.github.io/geochemR/reference/read_workbook.md)
of that file. Built by `data-raw/make_cuttings.R`; every value is
invented.

## Examples

``` r
gc_cuttings
#> <gc_data> 65 samples in 1 holes; 3640 measurements
#>   methods: PAM (650), SRA (390), XRD (780), XRF (1820)
#>   analytes per method: PAM=10, SRA=6, XRD=12, XRF=28
#>   censored (<LOD): 55
#>   depth: 6000-7950 ft
#>   x: 512300-512300  y: 3898200-3898200  (EPSG:26914)
#>   sources: cuttings_workbook.xlsx [2c5a48ef]; synthetic example built by data-raw/make_cuttings.R
#>   history: 2 step(s), last read_workbook
gc_hole_summary(gc_cuttings, "SRA", by = c("hole_id", "formation"), analytes = c("TOC", "Tmax"))
#> # A tibble: 4 × 9
#>   hole_id formation         x       y     n depth_top depth_base   TOC  Tmax
#>   <chr>   <chr>         <dbl>   <dbl> <int>     <dbl>      <dbl> <dbl> <dbl>
#> 1 EX-1    Carbonate    512300 3898200    17      7080       7590 0.351  448.
#> 2 EX-1    Lower Sand   512300 3898200    12      7590       7950 0.365  454.
#> 3 EX-1    Target Shale 512300 3898200    20      6480       7080 4.75   442.
#> 4 EX-1    Upper Shale  512300 3898200    16      6000       6480 1.11   435.
```

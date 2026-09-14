# Read a laboratory results table into long measurements

`read_xrd()`, `read_xrf()` and `read_sra()` read a *wide* table - one
row per sample, one column per mineral / element / pyrolysis parameter -
and return the long `measurements` form used by
[`gc_data()`](https://mjorden.github.io/geochemR/reference/gc_data.md).
`read_geochem()` is the generic behind them.

## Usage

``` r
read_geochem(
  path,
  method,
  analytes,
  sample_id = NULL,
  units = "wt%",
  lab = NA_character_,
  source = NA_character_,
  sheet = 1,
  decimal_mark = ".",
  grouping_mark = ","
)

read_xrd(
  path,
  sample_id = NULL,
  lab = NA_character_,
  source = NA_character_,
  sheet = 1,
  decimal_mark = ".",
  grouping_mark = ","
)

read_xrf(
  path,
  sample_id = NULL,
  units = "wt%",
  lab = NA_character_,
  source = NA_character_,
  sheet = 1,
  decimal_mark = ".",
  grouping_mark = ","
)

read_sra(
  path,
  sample_id = NULL,
  lab = NA_character_,
  source = NA_character_,
  sheet = 1,
  decimal_mark = ".",
  grouping_mark = ","
)
```

## Arguments

- path:

  File path (CSV or Excel) or a data frame.

- method:

  Method label for the rows (`"XRD"`, `"XRF"`, `"SRA"`).

- analytes:

  For `read_geochem()`: a function mapping column names to analyte names
  (`NA` = not an analyte).

- sample_id:

  Name of the sample-id column (default: auto-detect).

- units:

  For XRF: a named character vector `c(Zr = "ppm")` overriding the
  suffix detection; a single unnamed string sets the default for columns
  without a suffix (default `"wt%"`).

- lab, source:

  Filled into every row; `source` defaults to the file path, which
  [`gc_data()`](https://mjorden.github.io/geochemR/reference/gc_data.md)
  hashes into `meta$sources`.

- sheet:

  Excel sheet.

- decimal_mark, grouping_mark:

  Number format of the file (see
  [`.parse_values()`](https://mjorden.github.io/geochemR/reference/dot-parse_values.md));
  a decimal-comma sheet needs `decimal_mark = ","`.

## Value

A tibble of measurements (see
[`gc_data()`](https://mjorden.github.io/geochemR/reference/gc_data.md)).

## Details

- **XRD** columns are matched to canonical minerals with
  [`gc_mineral_name()`](https://mjorden.github.io/geochemR/reference/gc_mineral_name.md);
  values are weight percent.

- **XRF** columns are elements (`Si`, `Fe`, `Zr`) or oxides (`SiO2`,
  `Fe2O3`); the unit is taken from a suffix (`Zr_ppm`, `SiO2_wt%`,
  `Ba (ppm)`) or from `units`. Censored values written as `"<5"` become
  `value = 5`, `lod = 5`, `qualifier = "<"`; `"n.d."`, `"bdl"`, `"-"`
  become `NA`.

- **SRA** columns are `TOC`, `S1`, `S2`, `S3`, `Tmax` (aliases such as
  `T max`, `TOC (wt%)` are accepted).

Columns that are not recognised as analytes and are not the sample id
are ignored, and named in a message so a typo cannot silently drop a
column.

## Examples

``` r
xrd <- data.frame(sample = c("A1", "A2"), Quartz = c(40, 12), "Illite/Mica" = c(25, 3),
                  Calcite = c(20, 80), Pyrite = c(2, 1), check.names = FALSE)
read_xrd(xrd)
#> # A tibble: 8 × 9
#>   sample_id method analyte value unit    lod qualifier lab   source
#>   <chr>     <chr>  <chr>   <dbl> <chr> <dbl> <chr>     <chr> <chr> 
#> 1 A1        XRD    quartz     40 wt%      NA NA        NA    NA    
#> 2 A2        XRD    quartz     12 wt%      NA NA        NA    NA    
#> 3 A1        XRD    illite     25 wt%      NA NA        NA    NA    
#> 4 A2        XRD    illite      3 wt%      NA NA        NA    NA    
#> 5 A1        XRD    calcite    20 wt%      NA NA        NA    NA    
#> 6 A2        XRD    calcite    80 wt%      NA NA        NA    NA    
#> 7 A1        XRD    pyrite      2 wt%      NA NA        NA    NA    
#> 8 A2        XRD    pyrite      1 wt%      NA NA        NA    NA    
xrf <- data.frame(sample = c("A1", "A2"), SiO2 = c(62.1, 8.3), CaO = c(9.9, 48.2),
                  Zr_ppm = c(180, "<5"), check.names = FALSE)
read_xrf(xrf)
#> # A tibble: 6 × 9
#>   sample_id method analyte value unit    lod qualifier lab   source
#>   <chr>     <chr>  <chr>   <dbl> <chr> <dbl> <chr>     <chr> <chr> 
#> 1 A1        XRF    SiO2     62.1 wt%      NA NA        NA    NA    
#> 2 A2        XRF    SiO2      8.3 wt%      NA NA        NA    NA    
#> 3 A1        XRF    CaO       9.9 wt%      NA NA        NA    NA    
#> 4 A2        XRF    CaO      48.2 wt%      NA NA        NA    NA    
#> 5 A1        XRF    Zr      180   ppm      NA NA        NA    NA    
#> 6 A2        XRF    Zr        5   ppm       5 <         NA    NA    
```

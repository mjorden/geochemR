# The geochemR data model

A `gc_data` object is two tibbles and a little metadata:

## Usage

``` r
gc_data(
  samples,
  measurements,
  crs = NA,
  depth_unit = "ft",
  sources = character()
)
```

## Arguments

- samples:

  A data frame with at least `sample_id`; `hole_id`, `x`, `y`,
  `depth_top`, `depth_base` are used where present.

- measurements:

  A data frame with at least `sample_id`, `method`, `analyte`, `value`;
  `unit`, `lod`, `qualifier`, `lab` are filled with `NA` and `origin`
  with `"measured"` when absent. A `source` column (the readers fill it
  with the file name) is harvested into `meta$sources`.

- crs:

  Coordinate reference system of `x`/`y` as an EPSG code, or `NA`.

- depth_unit:

  `"ft"` or `"m"` - only carried as metadata.

- sources:

  Where the data came from: file paths (hashed when they exist), free
  text, or a data frame with a `path` column.

## Value

An object of class `gc_data`.

## Details

- `samples` - one row per physical sample: `sample_id`, `hole_id`, `x`,
  `y` (map coordinates), `z` (surface elevation, optional), `depth_top`,
  `depth_base`, `depth_mid`, `sample_type`, `formation` and `zone`
  (optional stratigraphic labels), `date` (optional).

- `measurements` - one row per (sample, analyte): `sample_id`, `method`
  (`"XRD"`, `"XRF"`, `"SRA"` or your own), `analyte`, `value`, `unit`,
  `lod` (detection limit, `NA` if none), `qualifier` (`"<"` when
  censored below `lod`, `">"` above range, `NA` otherwise), `lab` (who
  measured it), `origin` (`"measured"`, `"reported"` for a value the
  laboratory calculated from others, `"derived"` for one
  [`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
  computed).

- `meta` - a list: `crs` (EPSG code or `NA`), `depth_unit`, `sources` (a
  tibble of input files with `md5`, `size` and `mtime` when the file
  exists), `schema_version`, `package_version`, `created`, and `history`
  (the processing steps applied so far; see
  [`gc_history()`](https://mjorden.github.io/geochemR/reference/gc_history.md)).

Lab results are *samples*, not curves: tens per hole, at a depth or over
an interval, from a lab by a method. Keeping every method in one long
table means one set of tools for validation, joins and plotting.

Objects saved by geochemR \< 0.3.0 (no `origin` column, `lab` holding
`"derived"` / `"reported"`) are upgraded in place the first time any
function touches them.

## Examples

``` r
ds <- gc_example
ds
#> <gc_data> 180 samples in 12 holes; 4951 measurements
#>   methods: SRA (631), XRD (1980), XRF (2340)
#>   analytes per method: SRA=5, XRD=11, XRF=13
#>   censored (<LOD): 85
#>   depth: 0-154 ft
#>   x: 500007-501230  y: 4199966-4200799  (EPSG:26914)
#>   sources: synthetic example built by data-raw/make_example.R; synthetic
#>   history: 1 step(s), last gc_data
head(gc_samples(ds))
#> # A tibble: 6 × 12
#>   sample_id hole_id       x        y     z depth_top depth_base sample_type
#>   <chr>     <chr>     <dbl>    <dbl> <dbl>     <dbl>      <dbl> <chr>      
#> 1 H01-000   H01     500019. 4199999. 1254.         0         10 core       
#> 2 H01-010   H01     500019. 4199999. 1254.        10         20 cuttings   
#> 3 H01-020   H01     500019. 4199999. 1254.        20         30 cuttings   
#> 4 H01-030   H01     500019. 4199999. 1254.        30         40 core       
#> 5 H01-040   H01     500019. 4199999. 1254.        40         50 cuttings   
#> 6 H01-050   H01     500019. 4199999. 1254.        50         60 cuttings   
#> # ℹ 4 more variables: formation <lgl>, zone <lgl>, date <date>, depth_mid <dbl>
head(gc_measurements(ds))
#> # A tibble: 6 × 10
#>   sample_id method analyte value unit    lod qualifier lab         origin source
#>   <chr>     <chr>  <chr>   <dbl> <chr> <dbl> <chr>     <chr>       <chr>  <chr> 
#> 1 H01-000   XRD    quartz   60   wt%      NA NA        Example XR… measu… synth…
#> 2 H01-010   XRD    quartz   70.2 wt%      NA NA        Example XR… measu… synth…
#> 3 H01-020   XRD    quartz   67.5 wt%      NA NA        Example XR… measu… synth…
#> 4 H01-030   XRD    quartz   65.2 wt%      NA NA        Example XR… measu… synth…
#> 5 H01-040   XRD    quartz   68.3 wt%      NA NA        Example XR… measu… synth…
#> 6 H01-050   XRD    quartz   21.1 wt%      NA NA        Example XR… measu… synth…
gc_history(ds)
#> # A tibble: 1 × 4
#>   step    args                               time                version
#>   <chr>   <chr>                              <dttm>              <chr>  
#> 1 gc_data samples = 180, measurements = 4951 2026-09-14 21:28:01 0.3.0  
```

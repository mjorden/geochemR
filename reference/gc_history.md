# Processing history of a `gc_data` object

Every constructor, reader and processing function records what it did:
[`gc_data()`](https://mjorden.github.io/geochemR/reference/gc_data.md),
[`read_workbook()`](https://mjorden.github.io/geochemR/reference/read_workbook.md),
[`gc_substitute_lod()`](https://mjorden.github.io/geochemR/reference/gc_substitute_lod.md),
[`gc_convert_units()`](https://mjorden.github.io/geochemR/reference/gc_convert_units.md),
[`gc_oxide_to_element()`](https://mjorden.github.io/geochemR/reference/gc_oxide_to_element.md),
[`gc_renormalize()`](https://mjorden.github.io/geochemR/reference/gc_renormalize.md),
[`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md),
[`gc_bind()`](https://mjorden.github.io/geochemR/reference/gc_bind.md)
... The log, the input-file hashes in `meta$sources` and the package
version make a figure traceable to the spreadsheet it came from.

## Usage

``` r
gc_history(ds)
```

## Arguments

- ds:

  A `gc_data` object.

## Value

A tibble with one row per step: `step`, `args`, `time`, `version`.

## Examples

``` r
gc_history(gc_indices(gc_substitute_lod(gc_example)))
#> # A tibble: 3 × 4
#>   step              args                             time                version
#>   <chr>             <chr>                            <dttm>              <chr>  
#> 1 gc_data           samples = 180, measurements = 4… 2026-09-14 21:28:01 0.3.0  
#> 2 gc_substitute_lod method = half, rows = 85         2026-09-14 22:06:02 0.3.0  
#> 3 gc_indices        which = sra,xrf,xrd,pam, min_to… 2026-09-14 22:06:02 0.3.0  
```

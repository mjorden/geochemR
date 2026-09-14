# Read a sample / location table

Reads a CSV or Excel sheet with one row per sample. Column names are
matched case-insensitively against common spellings: `sample_id`
(`sample`, `id`, `sample_no`), `hole_id` (`hole`, `well`, `borehole`,
`station`, `api`), `x` (`easting`, `lon`, `longitude`), `y` (`northing`,
`lat`, `latitude`), `z` (`elevation`, `elev`, `msl`), `depth_top`
(`depth`, `top`, `from`), `depth_base` (`bottom`, `base`, `to`),
`sample_type` (`type`), `date`.

## Usage

``` r
read_samples(path, sheet = 1, ..., decimal_mark = ".", grouping_mark = ",")
```

## Arguments

- path:

  A file path, or a data frame.

- sheet:

  Excel sheet (name or number) when `path` is a workbook.

- ...:

  Extra column-name mappings as `canonical = "column in file"`.

- decimal_mark, grouping_mark:

  Number format of the coordinate and depth columns (see
  [`.parse_values()`](https://mjorden.github.io/geochemR/reference/dot-parse_values.md)).

## Value

A tibble with the canonical sample columns.

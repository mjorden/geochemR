# Convert concentration units

Converts XRF-style concentrations between `"wt%"`, `"ppm"` and `"ppb"`
(and `mg/kg`, treated as ppm). Values, detection limits and the `unit`
column all change.

## Usage

``` r
gc_convert_units(
  ds,
  to = c("wt%", "ppm", "ppb"),
  analytes = NULL,
  method = "XRF"
)
```

## Arguments

- ds:

  A `gc_data` object.

- to:

  Target unit.

- analytes:

  Optional subset of analytes to convert (default: all rows whose unit
  is convertible).

- method:

  Method whose rows are converted (default `"XRF"`); `NULL` for all
  methods.

## Value

`ds`.

## Details

Only rows of `method` (default `"XRF"`) are touched: mineral percentages
(XRD) and pyrolysis TOC (SRA) are also in wt%, but nothing downstream
expects them in ppm, and
[`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
refuses inputs in the wrong unit. Pass `method = NULL` to convert every
convertible row regardless.

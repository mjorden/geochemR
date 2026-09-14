# Convert concentration units

Converts XRF-style concentrations between `"wt%"`, `"ppm"` and `"ppb"`
(and `mg/kg`, treated as ppm). Values, detection limits and the `unit`
column all change.

## Usage

``` r
gc_convert_units(ds, to = c("wt%", "ppm", "ppb"), analytes = NULL)
```

## Arguments

- ds:

  A `gc_data` object.

- to:

  Target unit.

- analytes:

  Optional subset of analytes to convert (default: all rows whose unit
  is convertible).

## Value

`ds`.

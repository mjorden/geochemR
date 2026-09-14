# Validate a `gc_data` object

Errors on structural problems (unknown `sample_id`s in the measurements,
inverted depths, non-numeric values); warns on things worth a look (XRD
totals far from 100, values below their own detection limit without a
`"<"` qualifier, duplicate sample/method/analyte rows, and keys measured
by more than one lab - which
[`gc_wide()`](https://mjorden.github.io/geochemR/reference/gc_wide.md)
cannot resolve on its own).

## Usage

``` r
validate_gc(ds, xrd_tolerance = 5)
```

## Arguments

- ds:

  A `gc_data` object.

- xrd_tolerance:

  Warn when an XRD total is more than this many wt% from 100.

## Value

`ds`, invisibly.

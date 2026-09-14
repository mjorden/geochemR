# Renormalise a composition to a fixed total

Rescales one method's *measured* values per sample so they sum to
`total` (100 for XRD wt%). `exclude` names analytes left out of the sum
and the scaling (an amorphous fraction, or `total_clay` when the
individual clays are also reported). Rows the laboratory calculated
(`origin = "reported"`) or
[`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
derived are never touched - rerun
[`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
after renormalising if you want them to follow.

## Usage

``` r
gc_renormalize(
  ds,
  method = "XRD",
  total = 100,
  exclude = c("total_clay", "total"),
  tolerance = 0.2
)
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  Which method to renormalise (default `"XRD"`).

- total:

  Target total.

- exclude:

  Analytes to leave out.

- tolerance:

  Warn when a sample's sum before renormalising is more than this
  fraction of `total` away from it (default 0.2: a 65 or 135 wt%
  "composition" is more likely a missing column than closure error).

## Value

`ds`.

## Details

A sample whose clays are reported only as `total_clay` (no individual
clay minerals) has its other minerals scaled to `total - total_clay`, so
the sample still closes to `total`.

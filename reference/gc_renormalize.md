# Renormalise a composition to a fixed total

Rescales one method's values per sample so they sum to `total` (100 for
XRD wt%). `exclude` names analytes left out of the sum and the scaling
(an amorphous fraction, or `total_clay` when the individual clays are
also reported).

## Usage

``` r
gc_renormalize(
  ds,
  method = "XRD",
  total = 100,
  exclude = c("total_clay", "total")
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

## Value

`ds`.

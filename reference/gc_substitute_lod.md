# Substitute censored values

Replaces values with a `"<"` qualifier (below detection limit) following
the usual non-detect conventions.

## Usage

``` r
gc_substitute_lod(ds, method = c("half", "sqrt2", "lod", "zero", "na"))
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  `"half"` (LOD / 2, Helsel 2012, default), `"sqrt2"` (LOD / sqrt(2)),
  `"lod"` (the limit itself), `"zero"`, or `"na"`.

## Value

`ds` with substituted values; the `qualifier` column is kept so the
substitution stays visible.

## Examples

``` r
ds <- gc_substitute_lod(gc_example, "half")
```

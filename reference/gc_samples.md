# Accessors

Accessors

## Usage

``` r
gc_samples(ds)

gc_measurements(ds, method = NULL)

gc_analytes(ds, method = NULL)
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  Optional method filter (`"XRD"`, `"XRF"`, `"SRA"`).

## Value

`gc_samples()` the samples tibble; `gc_measurements()` the measurements
tibble, optionally for one method; `gc_analytes()` the analyte names per
method.

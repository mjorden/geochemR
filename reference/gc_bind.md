# Combine measurement sets for the same samples

Appends the measurements of `...` to `ds` (samples must already be known
to `ds`, or be supplied in the new objects and merged). Sources and
processing history are carried over from every `gc_data` input.

## Usage

``` r
gc_bind(ds, ...)
```

## Arguments

- ds:

  A `gc_data` object.

- ...:

  Further `gc_data` objects, or measurement data frames.

## Value

A `gc_data` object.

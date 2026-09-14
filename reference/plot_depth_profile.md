# Depth profiles

One panel per analyte, holes as colours, depth increasing downward.
Interval samples are drawn as vertical bars over their interval with a
point at the mid-depth; censored values are hollow.

## Usage

``` r
plot_depth_profile(
  ds,
  method,
  analytes = NULL,
  holes = NULL,
  free_x = TRUE,
  connect = TRUE
)
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  Method (`"XRD"`, `"XRF"`, `"SRA"`).

- analytes:

  Analytes to plot (default: all for the method).

- holes:

  Optional subset of holes.

- free_x:

  Independent x scales per analyte (default `TRUE`).

- connect:

  Join a hole's samples with a line.

## Value

A ggplot.

## Examples

``` r
plot_depth_profile(gc_example, "SRA", c("TOC", "Tmax"), holes = c("H01", "H05"))
```

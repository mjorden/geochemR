# Depth profiles

One panel per analyte, holes as colours, depth increasing downward.
Interval samples are drawn as a bar over their interval with a point at
the mid-depth; censored values are hollow. With `direct_labels` (the
default for two or three holes) each trace is named at its deepest
sample and no legend is drawn; a single hole needs no label at all, and
more than three get a legend.

## Usage

``` r
plot_depth_profile(
  ds,
  method,
  analytes = NULL,
  holes = NULL,
  free_x = TRUE,
  connect = TRUE,
  direct_labels = NULL
)
```

## Arguments

- ds:

  A `gc_data` object.

- method:

  Method (`"XRD"`, `"XRF"`, `"SRA"`, `"PAM"`).

- analytes:

  Analytes to plot (default: all for the method).

- holes:

  Optional subset of holes.

- free_x:

  Independent x scales per analyte (default `TRUE`).

- connect:

  Join a hole's samples with a line.

- direct_labels:

  Label traces at their deepest sample instead of a legend; `NULL`
  decides by the number of holes.

## Value

A ggplot.

## Examples

``` r
plot_depth_profile(gc_example, "SRA", c("TOC", "Tmax"), holes = c("H01", "H05"))

plot_depth_profile(gc_cuttings, "SRA", c("TOC", "S2", "Tmax"))
```

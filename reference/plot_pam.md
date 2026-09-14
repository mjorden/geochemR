# PAM pyrolysis log

The multi-ramp pyrolysis fractions (`Oil1` ... `Oil4`, `K1`) stacked
against depth: light hydrocarbons at the base of each bar, kerogen on
top.

## Usage

``` r
plot_pam(
  ds,
  holes = NULL,
  fractions = c("Oil1", "Oil2", "Oil3", "Oil4", "K1"),
  normalize = FALSE
)
```

## Arguments

- ds:

  A `gc_data` object.

- holes:

  Optional subset.

- fractions:

  Which fractions, in stacking order.

- normalize:

  Show each sample as % of its total rather than mg HC/g.

## Value

A ggplot.

## Examples

``` r
plot_pam(gc_cuttings)
```

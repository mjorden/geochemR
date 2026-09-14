# Log-ratio transforms for compositional data

Concentrations that sum to a constant are compositional: correlations
and distances computed on the raw parts are distorted. `gc_clr()`
centres each row's log parts (Aitchison), `gc_alr()` takes logs relative
to one part. Zeros are replaced by `zero_replace` times the smallest
positive value in the column before logging.

## Usage

``` r
gc_clr(x, zero_replace = 0.65)

gc_alr(x, denominator, zero_replace = 0.65)
```

## Arguments

- x:

  A numeric matrix or data frame of parts (rows = samples).

- zero_replace:

  Multiplier for zero replacement.

- denominator:

  For `gc_alr()`: column name or index of the reference part.

## Value

A matrix of the same shape (one fewer column for `gc_alr()`).

## Examples

``` r
w <- gc_wide(gc_example, "XRD", c("quartz", "calcite", "total_clay"))
head(gc_clr(w[, c("quartz", "calcite", "total_clay")]))
#>          quartz    calcite total_clay
#> [1,]  1.0800237 -0.6534669 -0.4265568
#> [2,]  2.2030443 -2.8357619  0.6327175
#> [3,]  1.3867226 -0.7585422 -0.6281804
#> [4,]  1.8256149 -2.0153723  0.1897574
#> [5,]  2.2446138 -2.7667538  0.5221400
#> [6,] -0.2558442 -0.1229054  0.3787496
```

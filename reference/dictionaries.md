# Analyte dictionaries

`gc_minerals` maps the mineral names labs print to canonical names;
`gc_oxides` gives the oxide/element conversion factors;
`gc_sra_analytes` the pyrolysis parameters with units and plausible
ranges.

## Usage

``` r
gc_minerals

gc_oxides

gc_sra_analytes

gc_pam_analytes
```

## Format

`gc_minerals`: a data frame with `canonical`, `alias`, `group`
(`"tectosilicate"`, `"carbonate"`, `"clay"`, `"sulfide"`, `"other"`).
`gc_oxides`: `oxide`, `element`, `factor` (element fraction of the oxide
by mass, so `element = oxide * factor`). `gc_sra_analytes`: `analyte`,
`unit`, `low`, `high`.

An object of class `data.frame` with 85 rows and 3 columns.

An object of class `data.frame` with 20 rows and 3 columns.

An object of class `data.frame` with 14 rows and 4 columns.

`gc_pam_analytes`: the multi-ramp (PAM) pyrolysis fractions - `Oil1` ...
`Oil4` and `K1` in mg HC/g with the carbon range each fraction
represents, plus one `Tmax_*` per fraction.

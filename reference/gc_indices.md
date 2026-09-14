# Derived indices

Adds derived analytes as new measurement rows so they travel with the
raw data. What is computed depends on what is present:

## Usage

``` r
gc_indices(ds, which = c("sra", "xrf", "xrd", "pam"), min_toc = 0.5)
```

## Arguments

- ds:

  A `gc_data` object.

- which:

  Which groups to compute (`"sra"`, `"xrf"`, `"xrd"`).

- min_toc:

  TOC (wt%) below which HI, OI and S1/TOC are not reported - the ratios
  blow up on lean samples and laboratories conventionally leave them
  blank below about 0.5 %.

## Value

`ds` with extra rows, `method` set to `"SRA"`, `"XRF"` or `"XRD"` and
`lab = "derived"`.

## Details

**SRA / Rock-Eval** (needs `TOC`, `S1`, `S2`, `S3`, `Tmax` as
available):

- `HI = 100 * S2 / TOC` (mg HC / g TOC), `OI = 100 * S3 / TOC`

- `PI = S1 / (S1 + S2)` (production index)

- `S1_TOC = 100 * S1 / TOC` (oil-crossover index; \> 100 suggests
  migrated oil)

- `Ro_eq = 0.0180 * Tmax - 7.16` (Jarvie et al. 2001), `NA` outside
  400-500 degC

**XRF** (oxides in wt%; elements are converted to oxides for the
calculation):

- `CIA = 100 * Al2O3 / (Al2O3 + CaO + Na2O + K2O)` (Nesbitt & Young
  1982; molar). CaO is *not* corrected for carbonate, so CIA is only
  meaningful for carbonate-poor samples; an oxide the lab did not report
  at all counts as zero.

- `Si_Al`, `K_Al`, `Ti_Al` element mass ratios (detrital / clay proxies)

**XRD** (wt%):

- `carbonate` = calcite + dolomite + ankerite + siderite + aragonite

- `clay` = `total_clay` if reported, else the sum of clay minerals

- `QFM` = quartz + feldspars (+ mica if present)

- `BI_min = (quartz + dolomite) / (quartz + dolomite + calcite + clay)`
  (Wang & Gale 2009 mineralogical brittleness, 0-1)

- `BI_w = 100 * (1.5*QFM + 1.5*carbonate) / (1.5*QFM + 1.5*carbonate + 2*clay)`

  - a weighted brittleness of the kind cuttings-analysis laboratories
    report, 0-100; brittle phases weighted 1.5, clay 2

**PAM** (multi-ramp pyrolysis fractions, needs `Oil1` ... `K1`):

- `Oil_total = Oil1 + Oil2 + Oil3 + Oil4`, `Oil3_Oil2`, `Oil4_Oil3`,
  `K1_Oil4` and `Oil_TOC = 100 * Oil_total / TOC` when an SRA TOC exists
  for the sample

## Examples

``` r
ds <- gc_indices(gc_example)
gc_analytes(ds)
#> $SRA
#>  [1] "TOC"    "S1"     "S2"     "S3"     "Tmax"   "HI"     "OI"     "PI"    
#>  [9] "S1_TOC" "Ro_eq" 
#> 
#> $XRD
#>  [1] "quartz"      "k_feldspar"  "plagioclase" "calcite"     "dolomite"   
#>  [6] "pyrite"      "illite"      "mixed_layer" "kaolinite"   "chlorite"   
#> [11] "total_clay"  "carbonate"   "clay"        "QFM"         "BI_min"     
#> [16] "BI_w"       
#> 
#> $XRF
#>  [1] "SiO2"  "Al2O3" "CaO"   "MgO"   "K2O"   "Na2O"  "Fe2O3" "TiO2"  "LOI"  
#> [10] "Zr"    "V"     "Mo"    "Ni"    "CIA"   "Si_Al" "K_Al"  "Ti_Al"
#> 
```

# Synthetic example dataset

Twelve holes on a 3 x 4 grid (400 m spacing, EPSG:26914), each with
fifteen 10-ft intervals through three units — a quartz-rich sandstone,
an organic-rich calcareous mudstone whose TOC increases eastward, and a
limestone. Every sample has XRD mineralogy (10 minerals + total clay)
and XRF chemistry (9 oxides + LOI in wt%, Zr / V / Mo / Ni in ppm, with
Mo and Ni censored below 2 and 5 ppm); core samples and about 60 % of
cuttings have SRA pyrolysis (TOC, S1, S2, S3, Tmax; Tmax blank on lean
samples). Built by `data-raw/make_example.R`; nothing in it is real.

## Usage

``` r
gc_example
```

## Format

A `gc_data` object; see
[`gc_data()`](https://mjorden.github.io/geochemR/reference/gc_data.md).

## Examples

``` r
gc_example
#> <gc_data> 180 samples in 12 holes; 4192 measurements
#>   methods: SRA (631), XRD (1221), XRF (2340)
#>   analytes per method: SRA=5, XRD=11, XRF=13
#>   censored (<LOD): 85
#>   depth: 0-154 ft
#>   x: 500007-501230  y: 4199966-4200799  (EPSG:26914)
gc_analytes(gc_example)
#> $SRA
#> [1] "TOC"  "S1"   "S2"   "S3"   "Tmax"
#> 
#> $XRD
#>  [1] "quartz"      "k_feldspar"  "plagioclase" "calcite"     "dolomite"   
#>  [6] "pyrite"      "illite"      "mixed_layer" "kaolinite"   "chlorite"   
#> [11] "total_clay" 
#> 
#> $XRF
#>  [1] "SiO2"  "Al2O3" "CaO"   "MgO"   "K2O"   "Na2O"  "Fe2O3" "TiO2"  "LOI"  
#> [10] "Zr"    "V"     "Mo"    "Ni"   
#> 
```

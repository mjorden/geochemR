# Read a multi-method laboratory workbook

Commercial cuttings-analysis deliverables usually arrive as one sheet
with every method side by side under a **three-row header** - a *group*
row (`SAMPLE INFO`, `TOC`, `TRADITIONAL PYROLYSIS`, `PAM PYROLYSIS`,
`XRD BULK MINERALOGY`, `XRD CLAY SPECIATION`, `XRF ELEMENTAL ...`), an
*analyte* row and a *unit* row - often followed by an error / QC row,
with one sample per row below. Sample rows carry a sample number, the
**bottom** depth of a cuttings interval, and formation / zone labels.
`read_workbook()` reads that layout into a
[`gc_data()`](https://mjorden.github.io/geochemR/reference/gc_data.md)
object in one call.

## Usage

``` r
read_workbook(
  path,
  sheet = 1,
  hole_id = "well",
  interval = "previous",
  keep_calculated = FALSE,
  clay_basis = c("auto", "bulk", "relative"),
  header_row = NULL,
  data_start = NULL,
  x = NA_real_,
  y = NA_real_,
  z = NA_real_,
  crs = NA,
  depth_unit = "ft",
  lab = NA_character_,
  source = NA_character_
)
```

## Arguments

- path:

  Workbook path (`.xlsx`) or a data frame read with no header
  (`header = FALSE`).

- sheet:

  Sheet name or number.

- hole_id:

  Well / hole identifier for every sample.

- interval:

  How to get `depth_top` from a bottom-only depth column: `"previous"`
  (default; the previous sample's bottom, the first sample getting the
  median spacing), a number (fixed interval length), or `"point"`
  (`depth_top = depth_base`).

- keep_calculated:

  Keep lab-calculated columns (see Details).

- clay_basis:

  `"auto"` (default), `"bulk"` or `"relative"`: whether the
  clay-speciation columns are wt% of the bulk rock or % of total clay.
  `"auto"` treats them as relative when they sum to ~100 while
  `total_clay` does not.

- header_row:

  Row number of the *analyte* row (1-based, as in Excel), or `NULL` to
  detect.

- data_start:

  First data row (1-based), or `NULL` to detect.

- x, y, z:

  Optional coordinates / elevation stored on every sample.

- crs, depth_unit, lab, source:

  Passed to
  [`gc_data()`](https://mjorden.github.io/geochemR/reference/gc_data.md)
  / stored on rows.

## Value

A `gc_data` object. The samples table carries `formation` and `zone`
when the sheet has them.

## Details

The header rows are located automatically (the analyte row is the one
whose first cells read `SAMPLE ...` and `... DEPTH`; the group row is
the one above, the unit row the one below; data start at the first row
whose depth is numeric). Override with `header_row` / `data_start` when
a file differs.

Groups are mapped to methods by name: TOC and traditional pyrolysis -\>
`"SRA"`; PAM / multi-ramp pyrolysis -\> `"PAM"`; XRD -\> `"XRD"` (the
clay speciation group is folded in, converted to bulk wt% when it is
reported relative to total clay - see `clay_basis`); XRF -\> `"XRF"`
(elements in %, traces in ppm, as reported). Analyte names are
normalised (`LECO TOC` -\> `TOC`, `HAWK TOC` -\> `TOC_pyr`, `S1/TOC*100`
-\> `S1_TOC`, `FID Oil-1` -\> `Oil1`, `Tmax FID Oil-1` -\> `Tmax_Oil1`,
`K-SPAR` -\> `k_feldspar`, `MIX I/S` -\> `mixed_layer`, `MAJORS + LE`
-\> `majors_LE`, ...).

Columns the laboratory *calculates* from others (HI, OI, PI, S1/TOC,
S2/S3, KQ, Q+F, total carbonate, brittleness, PAM ratios, majors + LE)
are dropped by default so that
[`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
is the single source of derived values; `keep_calculated = TRUE` keeps
them with `lab = "reported"`.

## Examples

``` r
f <- system.file("extdata", "cuttings_workbook.xlsx", package = "geochemR")
if (nzchar(f) && requireNamespace("readxl", quietly = TRUE)) {
  ds <- read_workbook(f, hole_id = "EX-1", lab = "Example Lab")
  ds
  gc_analytes(ds)
}
#> read_workbook(): clay speciation reported relative to total clay; converted to bulk wt%
#> $PAM
#>  [1] "Oil1"      "Tmax_Oil1" "Oil2"      "Tmax_Oil2" "Oil3"      "Tmax_Oil3"
#>  [7] "Oil4"      "Tmax_Oil4" "K1"        "Tmax_K1"  
#> 
#> $SRA
#> [1] "TOC"     "TOC_pyr" "S1"      "S2"      "Tmax"    "S3"     
#> 
#> $XRD
#>  [1] "quartz"      "k_feldspar"  "plagioclase" "calcite"     "dolomite"   
#>  [6] "siderite"    "pyrite"      "total_clay"  "chlorite"    "kaolinite"  
#> [11] "illite"      "mixed_layer"
#> 
#> $XRF
#>  [1] "EGR" "Si"  "Ti"  "Al"  "Fe"  "Mn"  "Mg"  "Ca"  "K"   "P"   "S"   "LE" 
#> [13] "Cl"  "V"   "Cr"  "Co"  "Ni"  "Cu"  "Zn"  "As"  "Rb"  "Sr"  "Zr"  "Mo" 
#> [25] "Pb"  "Th"  "U"   "Ba" 
#> 
```

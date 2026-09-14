#' Synthetic example dataset
#'
#' Twelve holes on a 3 x 4 grid (400 m spacing, EPSG:26914), each with
#' fifteen 10-ft intervals through three units - a quartz-rich sandstone, an
#' organic-rich calcareous mudstone whose TOC increases eastward, and a
#' limestone. Every sample has XRD mineralogy (10 minerals + total clay)
#' and XRF chemistry (9 oxides + LOI in wt%, Zr / V / Mo / Ni in ppm, with
#' Mo and Ni censored below 2 and 5 ppm); core samples and about 60 % of
#' cuttings have SRA pyrolysis (TOC, S1, S2, S3, Tmax; Tmax blank on lean
#' samples). Built by `data-raw/make_example.R`; nothing in it is real.
#'
#' @format A `gc_data` object; see [gc_data()].
#' @examples
#' gc_example
#' gc_analytes(gc_example)
"gc_example"

#' Synthetic cuttings-analysis well
#'
#' One well, 65 cuttings samples at 30-ft intervals from 6,000 to 7,950 ft
#' through four formations (an upper shale, an organic-rich target shale
#' with two zones, a carbonate, a lower sand), carrying everything a
#' commercial cuttings-analysis deliverable does: LECO and pyrolysis TOC,
#' traditional pyrolysis (S1, S2, S3, Tmax), multi-ramp PAM pyrolysis
#' fractions with their Tmax, XRD bulk mineralogy, XRD clay speciation
#' (reported relative to total clay and converted on read), and XRF elements
#' in % with traces in ppm (Mo, As, U, Co partly censored).
#'
#' The same data is shipped as an Excel workbook in the deliverable's
#' three-row-header layout  - 
#' `system.file("extdata", "cuttings_workbook.xlsx", package = "geochemR")`  - 
#' and `gc_cuttings` is simply `read_workbook()` of that file. Built by
#' `data-raw/make_cuttings.R`; every value is invented.
#'
#' @format A `gc_data` object with `formation` and `zone` on the samples.
#' @examples
#' gc_cuttings
#' gc_hole_summary(gc_cuttings, "SRA", by = c("hole_id", "formation"), analytes = c("TOC", "Tmax"))
"gc_cuttings"

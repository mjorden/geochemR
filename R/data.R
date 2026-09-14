#' Synthetic example dataset
#'
#' Twelve holes on a 3 x 4 grid (400 m spacing, EPSG:26914), each with
#' fifteen 10-ft intervals through three units — a quartz-rich sandstone, an
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

#' Derived indices
#'
#' Adds derived analytes as new measurement rows so they travel with the raw
#' data. What is computed depends on what is present:
#'
#' **SRA / Rock-Eval** (needs `TOC`, `S1`, `S2`, `S3`, `Tmax` as available):
#' * `HI = 100 * S2 / TOC` (mg HC / g TOC), `OI = 100 * S3 / TOC`
#' * `PI = S1 / (S1 + S2)` (production index)
#' * `S1_TOC = 100 * S1 / TOC` (oil-crossover index; > 100 suggests migrated oil)
#' * `Ro_eq = 0.0180 * Tmax - 7.16` (Jarvie et al. 2001), `NA` outside 400-500 °C
#'
#' **XRF** (oxides in wt%; elements are converted to oxides for the
#' calculation):
#' * `CIA = 100 * Al2O3 / (Al2O3 + CaO + Na2O + K2O)` (Nesbitt & Young 1982;
#'   molar). CaO is *not* corrected for carbonate, so CIA is only meaningful
#'   for carbonate-poor samples; an oxide the lab did not report at all
#'   counts as zero.
#' * `Si_Al`, `K_Al`, `Ti_Al` element mass ratios (detrital / clay proxies)
#'
#' **XRD** (wt%):
#' * `carbonate` = calcite + dolomite + ankerite + siderite + aragonite
#' * `clay` = `total_clay` if reported, else the sum of clay minerals
#' * `QFM` = quartz + feldspars (+ mica if present)
#' * `BI_min = (quartz + dolomite) / (quartz + dolomite + calcite + clay)`
#'   (Wang & Gale 2009 mineralogical brittleness, 0-1)
#'
#' @param ds A `gc_data` object.
#' @param which Which groups to compute (`"sra"`, `"xrf"`, `"xrd"`).
#' @param min_toc TOC (wt%) below which HI, OI and S1/TOC are not reported —
#'   the ratios blow up on lean samples and laboratories conventionally
#'   leave them blank below about 0.5 %.
#' @return `ds` with extra rows, `method` set to `"SRA"`, `"XRF"` or `"XRD"`
#'   and `lab = "derived"`.
#' @examples
#' ds <- gc_indices(gc_example)
#' gc_analytes(ds)
#' @export
gc_indices <- function(ds, which = c("sra", "xrf", "xrd"), min_toc = 0.5) {
  which <- match.arg(which, several.ok = TRUE)
  m <- ds$measurements
  m <- m[!(m$lab %in% "derived"), ]
  ds$measurements <- m
  new <- list()
  if ("sra" %in% which && any(m$method == "SRA")) new <- c(new, list(.sra_indices(ds, min_toc)))
  if ("xrf" %in% which && any(m$method == "XRF")) new <- c(new, list(.xrf_indices(ds)))
  if ("xrd" %in% which && any(m$method == "XRD")) new <- c(new, list(.xrd_indices(ds)))
  new <- dplyr::bind_rows(new)
  if (nrow(new)) ds$measurements <- dplyr::bind_rows(m, new)
  ds
}

.rows <- function(sample_id, method, values, unit) {
  keep <- !is.na(values)
  tibble::tibble(sample_id = sample_id[keep], method = method, analyte = names(values)[1] %||% NA, value = unname(values[keep]),
                 unit = unit, lod = NA_real_, qualifier = NA_character_, lab = "derived")
}

.derived <- function(w, method, name, values, unit) {
  keep <- !is.na(values) & is.finite(values)
  if (!any(keep)) return(NULL)
  tibble::tibble(sample_id = w$sample_id[keep], method = method, analyte = name, value = unname(values[keep]),
                 unit = unit, lod = NA_real_, qualifier = NA_character_, lab = "derived")
}

.col <- function(w, name) if (name %in% names(w)) w[[name]] else rep(NA_real_, nrow(w))

.sra_indices <- function(ds, min_toc = 0.5) {
  w <- gc_wide(ds, "SRA")
  toc <- .col(w, "TOC"); s1 <- .col(w, "S1"); s2 <- .col(w, "S2"); s3 <- .col(w, "S3"); tmax <- .col(w, "Tmax")
  toc_ok <- ifelse(!is.na(toc) & toc >= min_toc & toc > 0, toc, NA)
  ro <- ifelse(!is.na(tmax) & tmax >= 400 & tmax <= 500, 0.0180 * tmax - 7.16, NA)
  dplyr::bind_rows(
    .derived(w, "SRA", "HI", 100 * s2 / toc_ok, "mg HC/g TOC"),
    .derived(w, "SRA", "OI", 100 * s3 / toc_ok, "mg CO2/g TOC"),
    .derived(w, "SRA", "PI", s1 / (s1 + s2), "frac"),
    .derived(w, "SRA", "S1_TOC", 100 * s1 / toc_ok, "mg HC/g TOC"),
    .derived(w, "SRA", "Ro_eq", ro, "%")
  )
}

.xrf_indices <- function(ds) {
  # work in oxides, wt%
  ox <- gc_element_to_oxide(gc_convert_units(ds, "wt%"))
  w <- gc_wide(ox, "XRF")
  mol <- function(oxide) {
    mass <- c(Al2O3 = 101.96, CaO = 56.08, Na2O = 61.98, K2O = 94.20)
    .col(w, oxide) / mass[[oxide]]
  }
  al <- mol("Al2O3"); ca <- mol("CaO"); na <- mol("Na2O"); k <- mol("K2O")
  # an oxide the lab did not report at all counts as zero in the denominator
  # (a reported NA for one sample stays NA); Al2O3 itself must be present.
  zero_if_absent <- function(v, oxide) if (oxide %in% names(w)) v else rep(0, length(v))
  cia <- 100 * al / (al + zero_if_absent(ca, "CaO") + zero_if_absent(na, "Na2O") + zero_if_absent(k, "K2O"))
  el <- gc_wide(gc_oxide_to_element(ox), "XRF")
  si <- .col(el, "Si"); ali <- .col(el, "Al"); ki <- .col(el, "K"); ti <- .col(el, "Ti")
  dplyr::bind_rows(
    .derived(w, "XRF", "CIA", cia, "index"),
    .derived(w, "XRF", "Si_Al", si / ali, "ratio"),
    .derived(w, "XRF", "K_Al", ki / ali, "ratio"),
    .derived(w, "XRF", "Ti_Al", ti / ali, "ratio")
  )
}

.xrd_indices <- function(ds) {
  w <- gc_wide(ds, "XRD")
  s <- function(...) {
    cols <- c(...)
    have <- intersect(cols, names(w))
    if (!length(have)) return(rep(NA_real_, nrow(w)))
    rowSums(as.matrix(w[, have, drop = FALSE]), na.rm = TRUE)
  }
  carb <- s("calcite", "dolomite", "ankerite", "siderite", "aragonite")
  clay <- if ("total_clay" %in% names(w)) w$total_clay else s("illite", "smectite", "mixed_layer", "kaolinite", "chlorite", "glauconite")
  qfm <- s("quartz", "k_feldspar", "plagioclase")
  q <- .col(w, "quartz"); d <- .col(w, "dolomite"); cal <- .col(w, "calcite")
  q[is.na(q)] <- 0; d[is.na(d)] <- 0; cal[is.na(cal)] <- 0; clay[is.na(clay)] <- 0
  bi <- (q + d) / (q + d + cal + clay)
  dplyr::bind_rows(
    .derived(w, "XRD", "carbonate", carb, "wt%"),
    .derived(w, "XRD", "clay", clay, "wt%"),
    .derived(w, "XRD", "QFM", qfm, "wt%"),
    .derived(w, "XRD", "BI_min", bi, "frac")
  )
}

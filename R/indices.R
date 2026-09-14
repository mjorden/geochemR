#' Derived indices
#'
#' Adds derived analytes as new measurement rows so they travel with the raw
#' data. What is computed depends on what is present:
#'
#' **SRA / Rock-Eval** (needs `TOC`, `S1`, `S2`, `S3`, `Tmax` as available):
#' * `HI = 100 * S2 / TOC` (mg HC / g TOC), `OI = 100 * S3 / TOC`
#' * `PI = S1 / (S1 + S2)` (production index)
#' * `S1_TOC = 100 * S1 / TOC` (oil-crossover index; > 100 suggests migrated oil)
#' * `Ro_eq = 0.0180 * Tmax - 7.16` (Jarvie et al. 2001), `NA` outside 400-500 degC
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
#' * `BI_w = 100 * (1.5*QFM + 1.5*carbonate) / (1.5*QFM + 1.5*carbonate + 2*clay)`
#'   - a weighted brittleness of the kind cuttings-analysis laboratories
#'   report, 0-100; brittle phases weighted 1.5, clay 2
#'
#' **PAM** (multi-ramp pyrolysis fractions, needs `Oil1` ... `K1`):
#' * `Oil_total = Oil1 + Oil2 + Oil3 + Oil4`, `Oil3_Oil2`, `Oil4_Oil3`, `K1_Oil4`
#'   and `Oil_TOC = 100 * Oil_total / TOC` when an SRA TOC exists for the sample
#'
#' @param ds A `gc_data` object.
#' @param which Which groups to compute (`"sra"`, `"xrf"`, `"xrd"`).
#' @param min_toc TOC (wt%) below which HI, OI and S1/TOC are not reported  - 
#'   the ratios blow up on lean samples and laboratories conventionally
#'   leave them blank below about 0.5 %.
#' @return `ds` with extra rows, `method` set to `"SRA"`, `"XRF"`, `"XRD"` or
#'   `"PAM"` and `origin = "derived"`. Calling it again recomputes: the
#'   derived rows of the methods in `which` are replaced, other methods'
#'   derived rows are left alone.
#' @examples
#' ds <- gc_indices(gc_example)
#' gc_analytes(ds)
#' @export
gc_indices <- function(ds, which = c("sra", "xrf", "xrd", "pam"), min_toc = 0.5) {
  which <- match.arg(which, several.ok = TRUE)
  ds <- .ensure_schema(ds)
  m <- ds$measurements
  # recompute: drop only the derived rows of the methods asked for
  m <- m[!(m$origin == "derived" & m$method %in% toupper(which)), ]
  ds$measurements <- m
  new <- list()
  if ("sra" %in% which && any(m$method == "SRA")) new <- c(new, list(.sra_indices(ds, min_toc)))
  if ("xrf" %in% which && any(m$method == "XRF")) new <- c(new, list(.xrf_indices(ds)))
  if ("xrd" %in% which && any(m$method == "XRD")) new <- c(new, list(.xrd_indices(ds)))
  if ("pam" %in% which && any(m$method == "PAM")) new <- c(new, list(.pam_indices(ds, min_toc)))
  new <- dplyr::bind_rows(new)
  if (nrow(new)) ds$measurements <- dplyr::bind_rows(m, new)
  .log_step(ds, "gc_indices", list(which = which, min_toc = min_toc, rows = nrow(new)))
}

.derived <- function(w, method, name, values, unit) {
  keep <- !is.na(values) & is.finite(values)
  if (!any(keep)) return(NULL)
  tibble::tibble(sample_id = w$sample_id[keep], method = method, analyte = name, value = unname(values[keep]),
                 unit = unit, lod = NA_real_, qualifier = NA_character_, lab = NA_character_, origin = "derived")
}

.col <- function(w, name) if (name %in% names(w)) w[[name]] else rep(NA_real_, nrow(w))

# Stop when an input analyte carries a unit the index formulas do not expect
# (e.g. TOC in ppm after gc_convert_units(method = NULL)). Rows with no unit
# recorded are trusted.
.check_units <- function(ds, method, expected) {
  m <- ds$measurements
  m <- m[m$method == method & m$analyte %in% names(expected) & !is.na(m$unit) & m$origin != "derived", ]
  for (a in unique(m$analyte)) {
    u <- unique(m$unit[m$analyte == a])
    bad <- setdiff(tolower(u), tolower(expected[[a]]))
    if (length(bad)) {
      stop("gc_indices(): ", method, " ", a, " is in ", paste(bad, collapse = ", "), " but the ", tolower(method),
           " indices expect ", paste(expected[[a]], collapse = " / "), "; convert back with gc_convert_units()", call. = FALSE)
    }
  }
  invisible(TRUE)
}

.pct <- c("wt%", "%", "wt.%", "pct")
.mg_g <- c("mg/g", "mg HC/g", "mg CO2/g", "mg hc/g", "mg co2/g", "mgHC/g")

.sra_indices <- function(ds, min_toc = 0.5) {
  .check_units(ds, "SRA", list(TOC = .pct, S1 = .mg_g, S2 = .mg_g, S3 = .mg_g, Tmax = c("degC", "C", "deg C", "\u00b0C")))
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
  xrd_an <- unique(ds$measurements$analyte[ds$measurements$method == "XRD" & ds$measurements$origin != "derived"])
  .check_units(ds, "XRD", stats::setNames(rep(list(.pct), length(xrd_an)), xrd_an))
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
  carb0 <- carb; carb0[is.na(carb0)] <- 0
  bi_w <- 100 * (1.5 * qfm + 1.5 * carb0) / (1.5 * qfm + 1.5 * carb0 + 2 * clay)
  dplyr::bind_rows(
    .derived(w, "XRD", "carbonate", carb, "wt%"),
    .derived(w, "XRD", "clay", clay, "wt%"),
    .derived(w, "XRD", "QFM", qfm, "wt%"),
    .derived(w, "XRD", "BI_min", bi, "frac"),
    .derived(w, "XRD", "BI_w", bi_w, "index")
  )
}

.pam_indices <- function(ds, min_toc = 0.5) {
  .check_units(ds, "PAM", list(Oil1 = .mg_g, Oil2 = .mg_g, Oil3 = .mg_g, Oil4 = .mg_g, K1 = .mg_g))
  w <- gc_wide(ds, "PAM")
  o1 <- .col(w, "Oil1"); o2 <- .col(w, "Oil2"); o3 <- .col(w, "Oil3"); o4 <- .col(w, "Oil4"); k1 <- .col(w, "K1")
  z <- function(v) { v[is.na(v)] <- 0; v }
  total <- z(o1) + z(o2) + z(o3) + z(o4)
  total[is.na(o1) & is.na(o2) & is.na(o3) & is.na(o4)] <- NA
  out <- list(
    .derived(w, "PAM", "Oil_total", total, "mg HC/g"),
    .derived(w, "PAM", "Oil3_Oil2", o3 / o2, "ratio"),
    .derived(w, "PAM", "Oil4_Oil3", o4 / o3, "ratio"),
    .derived(w, "PAM", "K1_Oil4", k1 / o4, "ratio")
  )
  if (any(ds$measurements$method == "SRA" & ds$measurements$analyte == "TOC")) {
    toc <- gc_wide(ds, "SRA", "TOC")
    t <- toc$TOC[match(w$sample_id, toc$sample_id)]
    t <- ifelse(!is.na(t) & t >= min_toc & t > 0, t, NA)
    out <- c(out, list(.derived(w, "PAM", "Oil_TOC", 100 * total / t, "mg HC/g TOC")))
  }
  dplyr::bind_rows(out)
}

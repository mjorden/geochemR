#' Substitute censored values
#'
#' Replaces values with a `"<"` qualifier (below detection limit) following
#' the usual non-detect conventions.
#'
#' @param ds A `gc_data` object.
#' @param method `"half"` (LOD / 2, Helsel 2012, default), `"sqrt2"`
#'   (LOD / sqrt(2)), `"lod"` (the limit itself), `"zero"`, or `"na"`.
#' @return `ds` with substituted values; the `qualifier` column is kept so the
#'   substitution stays visible.
#' @examples
#' ds <- gc_substitute_lod(gc_example, "half")
#' @export
gc_substitute_lod <- function(ds, method = c("half", "sqrt2", "lod", "zero", "na")) {
  method <- match.arg(method)
  m <- ds$measurements
  cens <- !is.na(m$qualifier) & m$qualifier == "<" & !is.na(m$lod)
  m$value[cens] <- switch(method,
    half = m$lod[cens] / 2, sqrt2 = m$lod[cens] / sqrt(2), lod = m$lod[cens], zero = 0, na = NA_real_)
  ds$measurements <- m
  ds
}

#' Convert concentration units
#'
#' Converts XRF-style concentrations between `"wt%"`, `"ppm"` and `"ppb"`
#' (and `mg/kg`, treated as ppm). Values, detection limits and the `unit`
#' column all change.
#'
#' @param ds A `gc_data` object.
#' @param to Target unit.
#' @param analytes Optional subset of analytes to convert (default: all rows
#'   whose unit is convertible).
#' @return `ds`.
#' @export
gc_convert_units <- function(ds, to = c("wt%", "ppm", "ppb"), analytes = NULL) {
  to <- match.arg(to)
  f <- c("wt%" = 1e4, ppm = 1, "mg/kg" = 1, ppb = 1e-3)  # to ppm
  m <- ds$measurements
  sel <- m$unit %in% names(f) & (is.null(analytes) | m$analyte %in% analytes)
  scale <- f[m$unit[sel]] / f[[to]]
  m$value[sel] <- m$value[sel] * scale
  m$lod[sel] <- m$lod[sel] * scale
  m$unit[sel] <- to
  ds$measurements <- m
  ds
}

#' Oxide / element conversion for XRF
#'
#' `gc_oxide_to_element()` rewrites oxide rows (`SiO2`, `Al2O3`, …) as their
#' element (`Si`, `Al`, …) using the mass factors in [gc_oxides];
#' `gc_element_to_oxide()` does the reverse for elements that have a
#' conventional oxide. Units are unchanged (a wt% oxide gives a wt% element).
#'
#' @param ds A `gc_data` object.
#' @param keep Keep the original rows as well (default `FALSE`: replace).
#' @return `ds`.
#' @examples
#' gc_measurements(gc_oxide_to_element(gc_example), "XRF")
#' @export
gc_oxide_to_element <- function(ds, keep = FALSE) {
  m <- ds$measurements
  i <- which(m$method == "XRF" & m$analyte %in% gc_oxides$oxide)
  if (!length(i)) return(ds)
  conv <- m[i, ]
  k <- match(conv$analyte, gc_oxides$oxide)
  conv$analyte <- gc_oxides$element[k]
  conv$value <- conv$value * gc_oxides$factor[k]
  conv$lod <- conv$lod * gc_oxides$factor[k]
  ds$measurements <- if (keep) dplyr::bind_rows(m, conv) else dplyr::bind_rows(m[-i, ], conv)
  ds
}

#' @rdname gc_oxide_to_element
#' @export
gc_element_to_oxide <- function(ds, keep = FALSE) {
  m <- ds$measurements
  ox <- gc_oxides[!duplicated(gc_oxides$element), ]  # Fe -> Fe2O3 (first listed)
  i <- which(m$method == "XRF" & m$analyte %in% ox$element)
  if (!length(i)) return(ds)
  conv <- m[i, ]
  k <- match(conv$analyte, ox$element)
  conv$analyte <- ox$oxide[k]
  conv$value <- conv$value / ox$factor[k]
  conv$lod <- conv$lod / ox$factor[k]
  ds$measurements <- if (keep) dplyr::bind_rows(m, conv) else dplyr::bind_rows(m[-i, ], conv)
  ds
}

#' Renormalise a composition to a fixed total
#'
#' Rescales one method's values per sample so they sum to `total`
#' (100 for XRD wt%). `exclude` names analytes left out of the sum and the
#' scaling (an amorphous fraction, or `total_clay` when the individual clays
#' are also reported).
#'
#' @param ds A `gc_data` object.
#' @param method Which method to renormalise (default `"XRD"`).
#' @param total Target total.
#' @param exclude Analytes to leave out.
#' @return `ds`.
#' @export
gc_renormalize <- function(ds, method = "XRD", total = 100, exclude = c("total_clay", "total")) {
  m <- ds$measurements
  sel <- m$method == toupper(method) & !m$analyte %in% exclude & !is.na(m$value)
  sums <- tapply(m$value[sel], m$sample_id[sel], sum)
  f <- total / sums[m$sample_id[sel]]
  m$value[sel] <- m$value[sel] * f
  ds$measurements <- m
  ds
}

#' Log-ratio transforms for compositional data
#'
#' Concentrations that sum to a constant are compositional: correlations and
#' distances computed on the raw parts are distorted. `gc_clr()` centres each
#' row's log parts (Aitchison), `gc_alr()` takes logs relative to one part.
#' Zeros are replaced by `zero_replace` times the smallest positive value in
#' the column before logging.
#'
#' @param x A numeric matrix or data frame of parts (rows = samples).
#' @param denominator For `gc_alr()`: column name or index of the reference part.
#' @param zero_replace Multiplier for zero replacement.
#' @return A matrix of the same shape (one fewer column for `gc_alr()`).
#' @examples
#' w <- gc_wide(gc_example, "XRD", c("quartz", "calcite", "total_clay"))
#' head(gc_clr(w[, c("quartz", "calcite", "total_clay")]))
#' @export
gc_clr <- function(x, zero_replace = 0.65) {
  x <- .replace_zeros(as.matrix(x), zero_replace)
  lx <- log(x)
  lx - rowMeans(lx, na.rm = TRUE)
}

#' @rdname gc_clr
#' @export
gc_alr <- function(x, denominator, zero_replace = 0.65) {
  x <- .replace_zeros(as.matrix(x), zero_replace)
  d <- if (is.character(denominator)) match(denominator, colnames(x)) else denominator
  out <- log(x[, -d, drop = FALSE]) - log(x[, d])
  out
}

.replace_zeros <- function(x, mult) {
  storage.mode(x) <- "double"
  for (j in seq_len(ncol(x))) {
    z <- !is.na(x[, j]) & x[, j] <= 0
    if (any(z)) {
      pos <- x[, j][!is.na(x[, j]) & x[, j] > 0]
      x[z, j] <- if (length(pos)) mult * min(pos) else NA
    }
  }
  x
}

#' Interval statistics per hole
#'
#' Aggregates one method's analytes into depth bins per hole — the step
#' between sample tables and anything gridded or mapped.
#'
#' @param ds A `gc_data` object.
#' @param method Method to aggregate.
#' @param breaks Depth-bin breaks (a numeric vector), or a single bin width.
#' @param fun Summary function (default `mean`).
#' @param analytes Optional subset.
#' @return A tibble: `hole_id`, `x`, `y`, `bin_top`, `bin_base`, `n`, then one
#'   column per analyte.
#' @examples
#' gc_interval_stats(gc_example, "SRA", breaks = 50)
#' @export
gc_interval_stats <- function(ds, method, breaks = 10, fun = mean, analytes = NULL) {
  w <- gc_wide(ds, method, analytes)
  an <- setdiff(names(w), names(ds$samples))
  if (length(breaks) == 1) {
    lo <- floor(min(w$depth_top, na.rm = TRUE) / breaks) * breaks
    hi <- ceiling(max(w$depth_base, na.rm = TRUE) / breaks) * breaks
    breaks <- seq(lo, hi, by = breaks)
  }
  w$bin <- cut(w$depth_mid, breaks, right = FALSE, include.lowest = TRUE)
  w <- w[!is.na(w$bin), ]
  out <- dplyr::group_by(w, .data$hole_id, .data$bin)
  out <- dplyr::summarise(out, x = mean(.data$x), y = mean(.data$y), n = dplyr::n(),
                          dplyr::across(dplyr::all_of(an), ~ fun(.x[!is.na(.x)])), .groups = "drop")
  lv <- as.integer(out$bin)
  out$bin_top <- breaks[lv]
  out$bin_base <- breaks[lv + 1]
  out$bin <- NULL
  out[, c("hole_id", "x", "y", "bin_top", "bin_base", "n", an)]
}

#' Per-hole summary
#'
#' @param ds A `gc_data` object.
#' @param method Method.
#' @param depth Optional `c(top, base)` window.
#' @param fun Summary function.
#' @param analytes Optional subset.
#' @return One row per hole with `x`, `y`, `n` and one column per analyte.
#' @examples
#' gc_hole_summary(gc_example, "SRA", analytes = c("TOC", "Tmax"))
#' @export
gc_hole_summary <- function(ds, method, depth = NULL, fun = mean, analytes = NULL) {
  w <- gc_wide(ds, method, analytes)
  if (!is.null(depth)) w <- w[!is.na(w$depth_mid) & w$depth_mid >= depth[1] & w$depth_mid <= depth[2], ]
  an <- setdiff(names(w), names(ds$samples))
  out <- dplyr::group_by(w, .data$hole_id)
  dplyr::summarise(out, x = mean(.data$x), y = mean(.data$y), n = dplyr::n(),
                   dplyr::across(dplyr::all_of(an), ~ if (all(is.na(.x))) NA_real_ else fun(.x[!is.na(.x)])), .groups = "drop")
}

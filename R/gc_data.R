#' The geochemR data model
#'
#' A `gc_data` object is two tibbles and a little metadata:
#'
#' * `samples` - one row per physical sample: `sample_id`, `hole_id`, `x`, `y`
#'   (map coordinates), `z` (surface elevation, optional), `depth_top`,
#'   `depth_base`, `depth_mid`, `sample_type`, `formation` and `zone`
#'   (optional stratigraphic labels), `date` (optional).
#' * `measurements` - one row per (sample, analyte): `sample_id`, `method`
#'   (`"XRD"`, `"XRF"`, `"SRA"` or your own), `analyte`, `value`, `unit`,
#'   `lod` (detection limit, `NA` if none), `qualifier` (`"<"` when censored
#'   below `lod`, `">"` above range, `NA` otherwise), `lab`.
#' * `meta` - a list: `crs` (EPSG code or `NA`), `depth_unit`, `sources`.
#'
#' Lab results are *samples*, not curves: tens per hole, at a depth or over an
#' interval, from a lab by a method. Keeping every method in one long table
#' means one set of tools for validation, joins and plotting.
#'
#' @param samples A data frame with at least `sample_id`; `hole_id`, `x`, `y`,
#'   `depth_top`, `depth_base` are used where present.
#' @param measurements A data frame with at least `sample_id`, `method`,
#'   `analyte`, `value`; `unit`, `lod`, `qualifier`, `lab` are filled with
#'   `NA` when absent.
#' @param crs Coordinate reference system of `x`/`y` as an EPSG code, or `NA`.
#' @param depth_unit `"ft"` or `"m"` - only carried as metadata.
#' @param sources Character vector recording where the data came from.
#' @return An object of class `gc_data`.
#' @examples
#' ds <- gc_example
#' ds
#' head(gc_samples(ds))
#' head(gc_measurements(ds))
#' @export
gc_data <- function(samples, measurements, crs = NA, depth_unit = "ft", sources = character()) {
  samples <- tibble::as_tibble(samples)
  measurements <- tibble::as_tibble(measurements)
  if (!"sample_id" %in% names(samples)) stop("`samples` needs a `sample_id` column", call. = FALSE)
  for (col in c("hole_id", "sample_type", "formation", "zone")) if (!col %in% names(samples)) samples[[col]] <- NA_character_
  for (col in c("x", "y", "z", "depth_top", "depth_base")) if (!col %in% names(samples)) samples[[col]] <- NA_real_
  samples$sample_id <- as.character(samples$sample_id)
  samples$hole_id <- as.character(samples$hole_id)
  samples$depth_base <- ifelse(is.na(samples$depth_base), samples$depth_top, samples$depth_base)
  samples$depth_mid <- (samples$depth_top + samples$depth_base) / 2

  need <- c("sample_id", "method", "analyte", "value")
  miss <- setdiff(need, names(measurements))
  if (length(miss)) stop("`measurements` is missing columns: ", paste(miss, collapse = ", "), call. = FALSE)
  for (col in c("unit", "qualifier", "lab")) if (!col %in% names(measurements)) measurements[[col]] <- NA_character_
  if (!"lod" %in% names(measurements)) measurements$lod <- NA_real_
  measurements$sample_id <- as.character(measurements$sample_id)
  measurements$method <- toupper(as.character(measurements$method))
  measurements$analyte <- as.character(measurements$analyte)
  measurements$value <- as.numeric(measurements$value)
  measurements$lod <- as.numeric(measurements$lod)
  measurements <- measurements[, c("sample_id", "method", "analyte", "value", "unit", "lod", "qualifier", "lab",
                                   setdiff(names(measurements), c("sample_id", "method", "analyte", "value", "unit", "lod", "qualifier", "lab")))]

  ds <- structure(list(samples = samples, measurements = measurements,
                       meta = list(crs = crs, depth_unit = depth_unit, sources = as.character(sources))),
                  class = "gc_data")
  validate_gc(ds)
  ds
}

#' Validate a `gc_data` object
#'
#' Errors on structural problems (unknown `sample_id`s in the measurements,
#' inverted depths, non-numeric values); warns on things worth a look (XRD
#' totals far from 100, values below their own detection limit without a
#' `"<"` qualifier, duplicate sample/method/analyte rows).
#'
#' @param ds A `gc_data` object.
#' @param xrd_tolerance Warn when an XRD total is more than this many wt%
#'   from 100.
#' @return `ds`, invisibly.
#' @export
validate_gc <- function(ds, xrd_tolerance = 5) {
  if (!inherits(ds, "gc_data")) stop("not a gc_data object", call. = FALSE)
  s <- ds$samples
  m <- ds$measurements
  if (anyDuplicated(s$sample_id)) stop("duplicate sample_id in samples: ", paste(unique(s$sample_id[duplicated(s$sample_id)]), collapse = ", "), call. = FALSE)
  orphan <- setdiff(unique(m$sample_id), s$sample_id)
  if (length(orphan)) stop("measurements refer to unknown sample_id: ", paste(utils::head(orphan, 5), collapse = ", "), call. = FALSE)
  inv <- which(!is.na(s$depth_top) & !is.na(s$depth_base) & s$depth_top > s$depth_base)
  if (length(inv)) stop("depth_top > depth_base for samples: ", paste(s$sample_id[inv], collapse = ", "), call. = FALSE)
  dup <- duplicated(m[, c("sample_id", "method", "analyte", "lab")])
  if (any(dup)) warning(sum(dup), " duplicate (sample, method, analyte, lab) measurement rows", call. = FALSE)
  below <- !is.na(m$lod) & !is.na(m$value) & m$value < m$lod & (is.na(m$qualifier) | m$qualifier != "<")
  if (any(below)) warning(sum(below), " values below their detection limit lack a '<' qualifier", call. = FALSE)
  # bulk-mineral rows only: not totals, not group sums or indices (derived or lab-reported)
  xrd <- m[m$method == "XRD" & !is.na(m$value) & !(m$lab %in% c("derived", "reported")) &
             !(m$analyte %in% c("total_clay", "total", "clay", "carbonate", "QFM", "BI", "BI_min", "BI_w")), ]
  if (nrow(xrd)) {
    tot <- tapply(xrd$value, xrd$sample_id, sum)
    off <- tot[abs(tot - 100) > xrd_tolerance]
    if (length(off)) warning(length(off), " XRD sample(s) total more than ", xrd_tolerance, " wt% from 100 (e.g. ", names(off)[1], " = ", round(off[1], 1), ")", call. = FALSE)
  }
  invisible(ds)
}

#' @export
print.gc_data <- function(x, ...) {
  s <- x$samples
  m <- x$measurements
  cat("<gc_data> ", nrow(s), " samples in ", length(unique(stats::na.omit(s$hole_id))), " holes; ",
      nrow(m), " measurements\n", sep = "")
  if (nrow(m)) {
    by <- table(m$method)
    cat("  methods: ", paste0(names(by), " (", as.integer(by), ")", collapse = ", "), "\n", sep = "")
    an <- tapply(m$analyte, m$method, function(a) length(unique(a)))
    cat("  analytes per method: ", paste0(names(an), "=", an, collapse = ", "), "\n", sep = "")
    cens <- sum(!is.na(m$qualifier) & m$qualifier == "<")
    if (cens) cat("  censored (<LOD): ", cens, "\n", sep = "")
  }
  if (any(!is.na(s$depth_top))) cat("  depth: ", round(min(s$depth_top, na.rm = TRUE), 1), "-", round(max(s$depth_base, na.rm = TRUE), 1), " ", x$meta$depth_unit, "\n", sep = "")
  if (any(!is.na(s$x))) cat("  x: ", round(min(s$x, na.rm = TRUE)), "-", round(max(s$x, na.rm = TRUE)), "  y: ", round(min(s$y, na.rm = TRUE)), "-", round(max(s$y, na.rm = TRUE)),
                            if (!is.na(x$meta$crs)) paste0("  (EPSG:", x$meta$crs, ")") else "", "\n", sep = "")
  invisible(x)
}

#' Accessors
#'
#' @param ds A `gc_data` object.
#' @param method Optional method filter (`"XRD"`, `"XRF"`, `"SRA"`).
#' @return `gc_samples()` the samples tibble; `gc_measurements()` the
#'   measurements tibble, optionally for one method; `gc_analytes()` the
#'   analyte names per method.
#' @export
gc_samples <- function(ds) {
  stopifnot(inherits(ds, "gc_data"))
  ds$samples
}

#' @rdname gc_samples
#' @export
gc_measurements <- function(ds, method = NULL) {
  stopifnot(inherits(ds, "gc_data"))
  m <- ds$measurements
  if (!is.null(method)) m <- m[m$method %in% toupper(method), ]
  m
}

#' @rdname gc_samples
#' @export
gc_analytes <- function(ds, method = NULL) {
  m <- gc_measurements(ds, method)
  split(unique(m[, c("method", "analyte")])$analyte, unique(m[, c("method", "analyte")])$method)
}

#' Combine measurement sets for the same samples
#'
#' Appends the measurements of `...` to `ds` (samples must already be known
#' to `ds`, or be supplied in the new objects and merged).
#'
#' @param ds A `gc_data` object.
#' @param ... Further `gc_data` objects, or measurement data frames.
#' @return A `gc_data` object.
#' @export
gc_bind <- function(ds, ...) {
  more <- list(...)
  s <- ds$samples
  m <- ds$measurements
  src <- ds$meta$sources
  for (obj in more) {
    if (inherits(obj, "gc_data")) {
      new_s <- obj$samples[!obj$samples$sample_id %in% s$sample_id, ]
      s <- dplyr::bind_rows(s, new_s)
      m <- dplyr::bind_rows(m, obj$measurements)
      src <- c(src, obj$meta$sources)
    } else {
      m <- dplyr::bind_rows(m, tibble::as_tibble(obj))
    }
  }
  gc_data(s, m, crs = ds$meta$crs, depth_unit = ds$meta$depth_unit, sources = unique(src))
}

#' Wide table of one method's results joined to the sample table
#'
#' @param ds A `gc_data` object.
#' @param method Which method to widen (one of the values in
#'   `gc_measurements(ds)$method`).
#' @param analytes Optional subset of analytes.
#' @param values Which column to spread: `"value"` (default) or `"qualifier"`.
#' @return A tibble: sample columns, then one column per analyte.
#' @examples
#' head(gc_wide(gc_example, "SRA"))
#' @export
gc_wide <- function(ds, method, analytes = NULL, values = "value") {
  m <- gc_measurements(ds, method)
  if (!is.null(analytes)) m <- m[m$analyte %in% analytes, ]
  if (!nrow(m)) stop("no ", method, " measurements", call. = FALSE)
  w <- tidyr::pivot_wider(m[, c("sample_id", "analyte", values)], names_from = "analyte", values_from = dplyr::all_of(values),
                          values_fn = mean)
  dplyr::left_join(ds$samples, w, by = "sample_id")
}

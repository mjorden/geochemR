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
#'   below `lod`, `">"` above range, `NA` otherwise), `lab` (who measured
#'   it), `origin` (`"measured"`, `"reported"` for a value the laboratory
#'   calculated from others, `"derived"` for one [gc_indices()] computed).
#' * `meta` - a list: `crs` (EPSG code or `NA`), `depth_unit`, `sources` (a
#'   tibble of input files with `md5`, `size` and `mtime` when the file
#'   exists), `schema_version`, `package_version`, `created`, and `history`
#'   (the processing steps applied so far; see [gc_history()]).
#'
#' Lab results are *samples*, not curves: tens per hole, at a depth or over an
#' interval, from a lab by a method. Keeping every method in one long table
#' means one set of tools for validation, joins and plotting.
#'
#' Objects saved by geochemR < 0.3.0 (no `origin` column, `lab` holding
#' `"derived"` / `"reported"`) are upgraded in place the first time any
#' function touches them.
#'
#' @param samples A data frame with at least `sample_id`; `hole_id`, `x`, `y`,
#'   `depth_top`, `depth_base` are used where present.
#' @param measurements A data frame with at least `sample_id`, `method`,
#'   `analyte`, `value`; `unit`, `lod`, `qualifier`, `lab` are filled with
#'   `NA` and `origin` with `"measured"` when absent. A `source` column (the
#'   readers fill it with the file name) is harvested into `meta$sources`.
#' @param crs Coordinate reference system of `x`/`y` as an EPSG code, or `NA`.
#' @param depth_unit `"ft"` or `"m"` - only carried as metadata.
#' @param sources Where the data came from: file paths (hashed when they
#'   exist), free text, or a data frame with a `path` column.
#' @return An object of class `gc_data`.
#' @examples
#' ds <- gc_example
#' ds
#' head(gc_samples(ds))
#' head(gc_measurements(ds))
#' gc_history(ds)
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
  for (col in c("unit", "qualifier", "lab", "origin")) if (!col %in% names(measurements)) measurements[[col]] <- NA_character_
  if (!"lod" %in% names(measurements)) measurements$lod <- NA_real_
  measurements$sample_id <- as.character(measurements$sample_id)
  measurements$method <- toupper(as.character(measurements$method))
  measurements$analyte <- as.character(measurements$analyte)
  measurements$value <- as.numeric(measurements$value)
  measurements$lod <- as.numeric(measurements$lod)
  measurements <- .fill_origin(measurements)
  measurements <- measurements[, c(.meas_cols, setdiff(names(measurements), .meas_cols))]

  src <- .source_table(sources)
  if ("source" %in% names(measurements)) src <- .bind_sources(src, .source_table(unique(stats::na.omit(measurements$source))))

  ds <- structure(list(samples = samples, measurements = measurements,
                       meta = list(crs = crs, depth_unit = depth_unit, sources = src, schema_version = .gc_schema,
                                   package_version = .gc_version(), created = Sys.time(), history = list())),
                  class = "gc_data")
  validate_gc(ds)
  .log_step(ds, "gc_data", list(samples = nrow(samples), measurements = nrow(measurements)))
}

.meas_cols <- c("sample_id", "method", "analyte", "value", "unit", "lod", "qualifier", "lab", "origin")
.gc_origins <- c("measured", "reported", "derived")
.gc_schema <- 2L

.gc_version <- function() tryCatch(as.character(utils::packageVersion("geochemR")), error = function(e) NA_character_)

# origin: explicit column wins; the pre-0.3.0 sentinels in `lab` are migrated;
# everything else is a measurement
.fill_origin <- function(m) {
  if (!"origin" %in% names(m)) m$origin <- NA_character_
  m$origin <- as.character(m$origin)
  legacy <- is.na(m$origin) & m$lab %in% c("derived", "reported")
  if (any(legacy)) {
    m$origin[legacy] <- m$lab[legacy]
    m$lab[legacy] <- NA_character_
  }
  m$origin[is.na(m$origin)] <- "measured"
  bad <- setdiff(unique(m$origin), .gc_origins)
  if (length(bad)) stop("`origin` must be one of ", paste(.gc_origins, collapse = ", "), "; got ", paste(bad, collapse = ", "), call. = FALSE)
  m
}

# ---- provenance ----------------------------------------------------------------

# A tibble describing input files: path, md5, size, mtime (hash and size only
# when the path is a readable file; free text is kept as a path with NAs).
.source_table <- function(x, sheet = NA_character_) {
  empty <- tibble::tibble(path = character(), md5 = character(), size = numeric(), mtime = as.POSIXct(character()), sheet = character())
  if (is.null(x) || !length(x)) return(empty)
  if (is.data.frame(x)) {
    if (!"path" %in% names(x)) stop("`sources` data frame needs a `path` column", call. = FALSE)
    x <- tibble::as_tibble(x)
    for (col in setdiff(names(empty), names(x))) x[[col]] <- empty[[col]][NA_integer_][rep(1, nrow(x))]
    return(x[, names(empty)])
  }
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  if (!length(x)) return(empty)
  exists <- file.exists(x) & !dir.exists(x)
  md5 <- rep(NA_character_, length(x)); size <- rep(NA_real_, length(x)); mtime <- rep(as.POSIXct(NA), length(x))
  if (any(exists)) {
    md5[exists] <- unname(tools::md5sum(x[exists]))
    size[exists] <- file.size(x[exists])
    mtime[exists] <- file.mtime(x[exists])
  }
  tibble::tibble(path = x, md5 = md5, size = size, mtime = mtime, sheet = rep(as.character(sheet), length.out = length(x)))
}

.bind_sources <- function(...) {
  out <- dplyr::bind_rows(...)
  if (!nrow(out)) return(out)
  # a path already recorded with a hash is not repeated by a bare mention
  out <- out[order(is.na(out$md5)), ]
  out[!duplicated(out$path), ]
}

# Append one processing step to meta$history and return the object
.log_step <- function(ds, step, args = list()) {
  fmt <- function(v) {
    if (is.null(v)) return("NULL")
    if (is.function(v)) return("<function>")
    s <- paste(format(v, digits = 6), collapse = ",")
    if (nchar(s) > 60) s <- paste0(substr(s, 1, 57), "...")
    s
  }
  txt <- if (length(args)) paste(names(args), vapply(args, fmt, character(1)), sep = " = ", collapse = ", ") else ""
  entry <- list(step = step, args = txt, time = Sys.time(), version = .gc_version())
  ds$meta$history <- c(ds$meta$history, list(entry))
  ds
}

#' Processing history of a `gc_data` object
#'
#' Every constructor, reader and processing function records what it did:
#' [gc_data()], [read_workbook()], [gc_substitute_lod()],
#' [gc_convert_units()], [gc_oxide_to_element()], [gc_renormalize()],
#' [gc_indices()], [gc_bind()] ... The log, the input-file hashes in
#' `meta$sources` and the package version make a figure traceable to the
#' spreadsheet it came from.
#'
#' @param ds A `gc_data` object.
#' @return A tibble with one row per step: `step`, `args`, `time`, `version`.
#' @examples
#' gc_history(gc_indices(gc_substitute_lod(gc_example)))
#' @export
gc_history <- function(ds) {
  ds <- .ensure_schema(ds)
  h <- ds$meta$history
  if (!length(h)) return(tibble::tibble(step = character(), args = character(), time = as.POSIXct(character()), version = character()))
  tibble::tibble(step = vapply(h, `[[`, character(1), "step"), args = vapply(h, `[[`, character(1), "args"),
                 time = as.POSIXct(vapply(h, function(e) as.numeric(e$time), numeric(1)), origin = "1970-01-01", tz = ""),
                 version = vapply(h, function(e) as.character(e$version %||% NA_character_), character(1)))
}

# Upgrade an object saved by an older geochemR (no origin column / schema
# fields) so every function can rely on the current layout.
.ensure_schema <- function(ds) {
  if (!inherits(ds, "gc_data")) stop("not a gc_data object", call. = FALSE)
  if (identical(ds$meta$schema_version, .gc_schema)) return(ds)
  m <- .fill_origin(ds$measurements)
  ds$measurements <- m[, c(.meas_cols, setdiff(names(m), .meas_cols))]
  ds$meta$sources <- if (is.data.frame(ds$meta$sources)) ds$meta$sources else .source_table(ds$meta$sources)
  ds$meta$schema_version <- .gc_schema
  ds$meta$package_version <- ds$meta$package_version %||% NA_character_
  ds$meta$created <- ds$meta$created %||% as.POSIXct(NA)
  ds$meta$history <- ds$meta$history %||% list()
  .log_step(ds, "upgrade_schema", list(from = 1L, to = .gc_schema))
}

#' Validate a `gc_data` object
#'
#' Errors on structural problems (unknown `sample_id`s in the measurements,
#' inverted depths, non-numeric values); warns on things worth a look (XRD
#' totals far from 100, values below their own detection limit without a
#' `"<"` qualifier, duplicate sample/method/analyte rows, and keys measured
#' by more than one lab - which [gc_wide()] cannot resolve on its own).
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
  if (!"origin" %in% names(m)) m <- .fill_origin(m)
  if (anyDuplicated(s$sample_id)) stop("duplicate sample_id in samples: ", paste(unique(s$sample_id[duplicated(s$sample_id)]), collapse = ", "), call. = FALSE)
  orphan <- setdiff(unique(m$sample_id), s$sample_id)
  if (length(orphan)) stop("measurements refer to unknown sample_id: ", paste(utils::head(orphan, 5), collapse = ", "), call. = FALSE)
  inv <- which(!is.na(s$depth_top) & !is.na(s$depth_base) & s$depth_top > s$depth_base)
  if (length(inv)) stop("depth_top > depth_base for samples: ", paste(s$sample_id[inv], collapse = ", "), call. = FALSE)
  dup <- duplicated(m[, c("sample_id", "method", "analyte", "lab", "origin")])
  if (any(dup)) warning(sum(dup), " duplicate (sample, method, analyte, lab) measurement rows", call. = FALSE)
  multi <- duplicated(m[, c("sample_id", "method", "analyte", "origin")]) & !dup
  if (any(multi)) {
    k <- unique(paste(m$method[multi], m$analyte[multi]))
    warning(sum(multi), " (sample, method, analyte) key(s) have rows from more than one lab (", paste(utils::head(k, 3), collapse = ", "),
            "); gc_wide() will need `fun =` or a lab filter", call. = FALSE)
  }
  below <- !is.na(m$lod) & !is.na(m$value) & m$value < m$lod & (is.na(m$qualifier) | m$qualifier != "<")
  if (any(below)) warning(sum(below), " values below their detection limit lack a '<' qualifier", call. = FALSE)
  # bulk-mineral rows only: not totals, not group sums or indices (derived or lab-reported)
  xrd <- m[m$method == "XRD" & !is.na(m$value) & m$origin == "measured" & !(m$analyte %in% .xrd_sums), ]
  if (nrow(xrd)) {
    tot <- tapply(xrd$value, xrd$sample_id, sum)
    off <- tot[abs(tot - 100) > xrd_tolerance]
    if (length(off)) warning(length(off), " XRD sample(s) total more than ", xrd_tolerance, " wt% from 100 (e.g. ", names(off)[1], " = ", round(off[1], 1), ")", call. = FALSE)
  }
  invisible(ds)
}

# XRD analytes that are totals or group sums, never part of a composition
.xrd_sums <- c("total_clay", "total", "clay", "carbonate", "QFM", "BI", "BI_min", "BI_w")

#' @export
print.gc_data <- function(x, ...) {
  x <- .ensure_schema(x)
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
    der <- table(m$origin[m$origin != "measured"])
    if (length(der)) cat("  ", paste0(names(der), ": ", as.integer(der), collapse = ", "), "\n", sep = "")
  }
  if (any(!is.na(s$depth_top))) cat("  depth: ", round(min(s$depth_top, na.rm = TRUE), 1), "-", round(max(s$depth_base, na.rm = TRUE), 1), " ", x$meta$depth_unit, "\n", sep = "")
  if (any(!is.na(s$x))) cat("  x: ", round(min(s$x, na.rm = TRUE)), "-", round(max(s$x, na.rm = TRUE)), "  y: ", round(min(s$y, na.rm = TRUE)), "-", round(max(s$y, na.rm = TRUE)),
                            if (!is.na(x$meta$crs)) paste0("  (EPSG:", x$meta$crs, ")") else "", "\n", sep = "")
  src <- x$meta$sources
  if (nrow(src)) {
    lab <- ifelse(is.na(src$md5), src$path, paste0(basename(src$path), " [", substr(src$md5, 1, 8), "]"))
    cat("  sources: ", paste(utils::head(lab, 3), collapse = "; "), if (nrow(src) > 3) paste0(" (+", nrow(src) - 3, ")"), "\n", sep = "")
  }
  h <- x$meta$history
  if (length(h)) cat("  history: ", length(h), " step(s), last ", h[[length(h)]]$step, "\n", sep = "")
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
  ds <- .ensure_schema(ds)
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
#' to `ds`, or be supplied in the new objects and merged). Sources and
#' processing history are carried over from every `gc_data` input.
#'
#' @param ds A `gc_data` object.
#' @param ... Further `gc_data` objects, or measurement data frames.
#' @return A `gc_data` object.
#' @export
gc_bind <- function(ds, ...) {
  ds <- .ensure_schema(ds)
  more <- list(...)
  s <- ds$samples
  m <- ds$measurements
  src <- ds$meta$sources
  hist <- ds$meta$history
  n_new <- 0L
  for (obj in more) {
    if (inherits(obj, "gc_data")) {
      obj <- .ensure_schema(obj)
      new_s <- obj$samples[!obj$samples$sample_id %in% s$sample_id, ]
      s <- dplyr::bind_rows(s, new_s)
      m <- dplyr::bind_rows(m, obj$measurements)
      src <- .bind_sources(src, obj$meta$sources)
      hist <- c(hist, obj$meta$history)
      n_new <- n_new + nrow(obj$measurements)
    } else {
      m <- dplyr::bind_rows(m, tibble::as_tibble(obj))
      n_new <- n_new + nrow(obj)
    }
  }
  out <- gc_data(s, m, crs = ds$meta$crs, depth_unit = ds$meta$depth_unit, sources = src)
  out$meta$created <- ds$meta$created
  out$meta$history <- hist
  .log_step(out, "gc_bind", list(objects = length(more), rows = n_new))
}

#' Wide table of one method's results joined to the sample table
#'
#' One row per sample, one column per analyte. A (sample, analyte) key that
#' has more than one row is resolved by `prefer`: the first origin in the
#' vector that is present wins (so a laboratory's own HI beats the one
#' [gc_indices()] computed, and both beat nothing). Rows that still collide
#' after that - the same analyte from two labs, or exact duplicates - are an
#' error unless `fun` says how to combine them; `gc_wide()` never averages
#' silently. Analytes reported in more than one unit across the surviving
#' rows are an error too: convert with [gc_convert_units()] first.
#'
#' @param ds A `gc_data` object.
#' @param method Which method to widen (one of the values in
#'   `gc_measurements(ds)$method`).
#' @param analytes Optional subset of analytes.
#' @param values Which column to spread: `"value"` (default) or `"qualifier"`.
#' @param prefer Origins in order of preference when a key has rows of more
#'   than one origin (default `c("measured", "reported", "derived")`).
#' @param fun Function to combine rows that remain duplicated after `prefer`
#'   (e.g. `mean`); `NULL` (default) makes them an error.
#' @return A tibble: sample columns, then one column per analyte.
#' @examples
#' head(gc_wide(gc_example, "SRA"))
#' @export
gc_wide <- function(ds, method, analytes = NULL, values = "value", prefer = c("measured", "reported", "derived"), fun = NULL) {
  m <- gc_measurements(ds, method)
  if (!is.null(analytes)) m <- m[m$analyte %in% analytes, ]
  if (!nrow(m)) stop("no ", method, " measurements", call. = FALSE)
  key <- paste(m$sample_id, m$analyte, sep = "\r")
  # 1. resolve by origin
  rank <- match(m$origin, prefer)
  rank[is.na(rank)] <- length(prefer) + 1L
  best <- tapply(rank, key, min)
  keep <- rank == best[key]
  if (!all(keep)) {
    lost <- m[!keep, ]
    won <- unique(m$origin[keep][key[keep] %in% key[!keep]])
    message("gc_wide(", method, "): ", length(unique(key[!keep])), " ", paste(unique(lost$analyte), collapse = "/"),
            " value(s) exist as ", paste(unique(lost$origin), collapse = " and "), " as well as ", paste(won, collapse = "/"),
            "; using ", paste(won, collapse = "/"), " (prefer = )")
    m <- m[keep, ]
    key <- key[keep]
  }
  # 2. one unit per analyte
  if (values == "value") {
    u <- unique(m[!is.na(m$unit), c("analyte", "unit")])
    mixed <- unique(u$analyte[duplicated(u$analyte)])
    if (length(mixed)) {
      stop("gc_wide(", method, "): ", paste(mixed, collapse = ", "), " reported in more than one unit (",
           paste(unique(u$unit[u$analyte %in% mixed]), collapse = ", "), "); convert with gc_convert_units() first", call. = FALSE)
    }
  }
  # 3. what is still duplicated needs an explicit combiner
  d <- duplicated(key)
  if (any(d) && is.null(fun)) {
    ex <- m[d, ][1, ]
    stop("gc_wide(", method, "): ", sum(d), " (sample, analyte) key(s) have more than one row of the same origin (e.g. ",
         ex$sample_id, " ", ex$analyte, if (!is.na(ex$lab)) paste0(", lab ", ex$lab), "); pass fun = (e.g. mean) to combine them, ",
         "or filter by lab first", call. = FALSE)
  }
  w <- tidyr::pivot_wider(m[, c("sample_id", "analyte", values)], names_from = "analyte", values_from = dplyr::all_of(values),
                          values_fn = if (any(d)) fun else NULL)
  dplyr::left_join(ds$samples, w, by = "sample_id")
}

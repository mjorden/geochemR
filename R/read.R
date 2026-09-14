#' Read a sample / location table
#'
#' Reads a CSV or Excel sheet with one row per sample. Column names are
#' matched case-insensitively against common spellings: `sample_id` (`sample`,
#' `id`, `sample_no`), `hole_id` (`hole`, `well`, `borehole`, `station`,
#' `api`), `x` (`easting`, `lon`, `longitude`), `y` (`northing`, `lat`,
#' `latitude`), `z` (`elevation`, `elev`, `msl`), `depth_top` (`depth`, `top`,
#' `from`), `depth_base` (`bottom`, `base`, `to`), `sample_type` (`type`),
#' `date`.
#'
#' @param path A file path, or a data frame.
#' @param sheet Excel sheet (name or number) when `path` is a workbook.
#' @param ... Extra column-name mappings as `canonical = "column in file"`.
#' @return A tibble with the canonical sample columns.
#' @export
read_samples <- function(path, sheet = 1, ...) {
  df <- .read_table(path, sheet)
  map <- list(
    sample_id = c("sample_id", "sample", "id", "sample_no", "sample_number", "sampleid", "lab_id"),
    hole_id = c("hole_id", "hole", "well", "borehole", "boring", "station", "api", "well_id", "site"),
    x = c("x", "easting", "east", "lon", "longitude", "long"),
    y = c("y", "northing", "north", "lat", "latitude"),
    z = c("z", "elevation", "elev", "msl", "ground_elevation", "kb"),
    depth_top = c("depth_top", "top", "depth", "from", "top_depth", "depth_from"),
    depth_base = c("depth_base", "bottom", "base", "to", "bottom_depth", "depth_to"),
    sample_type = c("sample_type", "type", "sample_kind"),
    formation = c("formation", "fm", "unit", "stratigraphy"),
    zone = c("zone", "member", "interval_name"),
    date = c("date", "sample_date", "collected")
  )
  over <- list(...)
  for (k in names(over)) map[[k]] <- c(over[[k]], map[[k]])
  out <- tibble::tibble(.rows = nrow(df))
  for (k in names(map)) {
    col <- .match_col(names(df), map[[k]])
    out[[k]] <- if (is.null(col)) NA else df[[col]]
  }
  if (all(is.na(out$sample_id))) stop("no sample_id column found in ", paste(names(df), collapse = ", "), call. = FALSE)
  out$sample_id <- as.character(out$sample_id)
  for (k in c("x", "y", "z", "depth_top", "depth_base")) out[[k]] <- suppressWarnings(as.numeric(out[[k]]))
  out
}

#' Read a laboratory results table into long measurements
#'
#' `read_xrd()`, `read_xrf()` and `read_sra()` read a *wide* table - one row
#' per sample, one column per mineral / element / pyrolysis parameter - and
#' return the long `measurements` form used by [gc_data()]. `read_geochem()`
#' is the generic behind them.
#'
#' * **XRD** columns are matched to canonical minerals with
#'   [gc_mineral_name()]; values are weight percent.
#' * **XRF** columns are elements (`Si`, `Fe`, `Zr`) or oxides (`SiO2`,
#'   `Fe2O3`); the unit is taken from a suffix (`Zr_ppm`, `SiO2_wt%`,
#'   `Ba (ppm)`) or from `units`. Censored values written as `"<5"` become
#'   `value = 5`, `lod = 5`, `qualifier = "<"`; `"n.d."`, `"bdl"`, `"-"` become
#'   `NA`.
#' * **SRA** columns are `TOC`, `S1`, `S2`, `S3`, `Tmax` (aliases such as
#'   `T max`, `TOC (wt%)` are accepted).
#'
#' Columns that are not recognised as analytes and are not the sample id are
#' ignored, and named in a message so a typo cannot silently drop a column.
#'
#' @param path File path (CSV or Excel) or a data frame.
#' @param method Method label for the rows (`"XRD"`, `"XRF"`, `"SRA"`).
#' @param sample_id Name of the sample-id column (default: auto-detect).
#' @param units For XRF: a named character vector `c(Zr = "ppm")` overriding
#'   the suffix detection; a single unnamed string sets the default for
#'   columns without a suffix (default `"wt%"`).
#' @param lab,source Filled into every row.
#' @param sheet Excel sheet.
#' @param analytes For `read_geochem()`: a function mapping column names to
#'   analyte names (`NA` = not an analyte).
#' @return A tibble of measurements (see [gc_data()]).
#' @examples
#' xrd <- data.frame(sample = c("A1", "A2"), Quartz = c(40, 12), "Illite/Mica" = c(25, 3),
#'                   Calcite = c(20, 80), Pyrite = c(2, 1), check.names = FALSE)
#' read_xrd(xrd)
#' xrf <- data.frame(sample = c("A1", "A2"), SiO2 = c(62.1, 8.3), CaO = c(9.9, 48.2),
#'                   Zr_ppm = c(180, "<5"), check.names = FALSE)
#' read_xrf(xrf)
#' @export
read_geochem <- function(path, method, analytes, sample_id = NULL, units = "wt%", lab = NA_character_,
                         source = NA_character_, sheet = 1) {
  df <- .read_table(path, sheet)
  id_col <- sample_id %||% .match_col(names(df), c("sample_id", "sample", "id", "sample_no", "sample_number", "sampleid", "lab_id"))
  if (is.null(id_col) || !id_col %in% names(df)) stop("no sample id column found in ", paste(names(df), collapse = ", "), call. = FALSE)
  other <- setdiff(names(df), id_col)
  an <- analytes(other)
  ignored <- other[is.na(an)]
  if (length(ignored)) message("read_geochem(", method, "): ignoring column(s) ", paste(ignored, collapse = ", "))
  keep <- other[!is.na(an)]
  if (!length(keep)) stop("no analyte columns recognised for ", method, " in ", paste(other, collapse = ", "), call. = FALSE)
  unit_of <- .unit_for(keep, units, an[!is.na(an)])
  rows <- lapply(seq_along(keep), function(i) {
    p <- .parse_values(df[[keep[i]]])
    tibble::tibble(sample_id = as.character(df[[id_col]]), method = toupper(method), analyte = an[!is.na(an)][i],
                   value = p$value, unit = unit_of[i], lod = p$lod, qualifier = p$qualifier, lab = lab, source = source)
  })
  out <- dplyr::bind_rows(rows)
  out[!is.na(out$value) | !is.na(out$qualifier), ]
}

#' @rdname read_geochem
#' @export
read_xrd <- function(path, sample_id = NULL, lab = NA_character_, source = NA_character_, sheet = 1) {
  read_geochem(path, "XRD", analytes = function(cols) {
    key <- tolower(trimws(cols))
    key <- gsub("\\s*\\(.*?\\)\\s*$", "", key)
    key <- sub("_?(wt%|wt\\.%|wt|pct|%)$", "", key)
    out <- gc_minerals$canonical[match(trimws(key), gc_minerals$alias)]
    out
  }, sample_id = sample_id, units = "wt%", lab = lab, source = source, sheet = sheet)
}

#' @rdname read_geochem
#' @export
read_xrf <- function(path, sample_id = NULL, units = "wt%", lab = NA_character_, source = NA_character_, sheet = 1) {
  read_geochem(path, "XRF", analytes = function(cols) {
    base <- .strip_unit_suffix(cols)
    known <- c(gc_oxides$oxide, unique(gc_oxides$element), "LOI", "Total", "S", "C", "Cl", "F", "Rb", "Sr", "Y", "Zr", "Nb", "Mo",
               "Ba", "Pb", "Th", "U", "V", "Cr", "Co", "Ni", "Cu", "Zn", "Ga", "As", "Se", "Sn", "Sb", "Cs", "La", "Ce", "Nd", "Hf", "Ta", "W", "Sc", "Li", "Be", "B", "Mn")
    hit <- known[match(tolower(base), tolower(known))]
    hit[tolower(base) == "total"] <- NA  # a lab total is not an analyte
    hit
  }, sample_id = sample_id, units = units, lab = lab, source = source, sheet = sheet)
}

#' @rdname read_geochem
#' @export
read_sra <- function(path, sample_id = NULL, lab = NA_character_, source = NA_character_, sheet = 1) {
  read_geochem(path, "SRA", analytes = function(cols) {
    key <- gsub("[^a-z0-9]", "", tolower(.strip_unit_suffix(cols)))
    al <- c(toc = "TOC", totalorganiccarbon = "TOC", s1 = "S1", s2 = "S2", s3 = "S3", tmax = "Tmax", hi = "HI", oi = "OI",
            pi = "PI", ro = "Ro", vr = "Ro", vro = "Ro", vitrinite = "Ro", roeq = "Ro_eq")
    unname(al[key])
  }, sample_id = sample_id, units = stats::setNames(gc_sra_analytes$unit, gc_sra_analytes$analyte), lab = lab, source = source, sheet = sheet)
}

# ---- helpers -----------------------------------------------------------------

`%||%` <- function(a, b) if (is.null(a)) b else a

.read_table <- function(path, sheet = 1) {
  if (is.data.frame(path)) return(tibble::as_tibble(path, .name_repair = "minimal"))
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) stop("reading Excel needs the readxl package", call. = FALSE)
    return(readxl::read_excel(path, sheet = sheet, .name_repair = "minimal"))
  }
  readr::read_csv(path, show_col_types = FALSE, name_repair = "minimal", col_types = readr::cols(.default = readr::col_character()))
}

.match_col <- function(cols, candidates) {
  low <- tolower(trimws(cols))
  for (c in candidates) {
    i <- match(tolower(c), low)
    if (!is.na(i)) return(cols[i])
  }
  NULL
}

.strip_unit_suffix <- function(cols) {
  x <- trimws(cols)
  x <- gsub("\\s*\\(.*?\\)\\s*$", "", x)                                   # "Ba (ppm)"
  x <- sub("[_ ]?(ppm|ppb|wt%|wt\\.%|wt|pct|%|mg/kg|mgkg)$", "", x, ignore.case = TRUE)  # "Zr_ppm"
  trimws(x)
}

.unit_for <- function(cols, units, analytes = cols) {
  default <- if (is.null(names(units)) && length(units) == 1) units else "wt%"
  named <- if (!is.null(names(units))) units else character()
  vapply(seq_along(cols), function(i) {
    cn <- cols[i]
    base <- .strip_unit_suffix(cn)
    if (analytes[i] %in% names(named)) return(unname(named[analytes[i]]))   # by analyte (read_sra passes a unit table)
    if (base %in% names(named)) return(unname(named[base]))
    m <- regmatches(cn, regexpr("(ppm|ppb|wt%|wt\\.%|pct|mg/kg)", cn, ignore.case = TRUE))
    if (length(m)) {
      u <- tolower(m)
      return(switch(u, "pct" = "wt%", "wt.%" = "wt%", "mg/kg" = "ppm", u))
    }
    default
  }, character(1), USE.NAMES = FALSE)
}

#' Parse laboratory value strings
#'
#' `"<5"` becomes `value = 5, lod = 5, qualifier = "<"`; `">1000"` becomes
#' `value = 1000, qualifier = ">"`; `"n.d."`, `"nd"`, `"bdl"`, `"-"`, `""` and
#' `"NA"` become `NA`; everything else is coerced to a number (a thousands
#' comma is removed).
#'
#' @param x A character or numeric vector.
#' @return A list with numeric `value`, numeric `lod`, character `qualifier`.
#' @examples
#' .parse_values(c("12.5", "<5", ">1000", "n.d.", "1,250"))
#' @keywords internal
#' @export
.parse_values <- function(x) {
  if (is.numeric(x)) return(list(value = as.numeric(x), lod = rep(NA_real_, length(x)), qualifier = rep(NA_character_, length(x))))
  s <- trimws(as.character(x))
  s[is.na(s)] <- ""
  na_words <- c("", "na", "n.a.", "n/a", "nd", "n.d.", "n.d", "bdl", "bd", "-", "--", "nan", "null", "ins", "is")
  isna <- tolower(s) %in% na_words
  lt <- grepl("^<\\s*", s)
  gt <- grepl("^>\\s*", s)
  num <- suppressWarnings(as.numeric(gsub("[,<>\\s]", "", s)))
  num[isna] <- NA
  list(value = num, lod = ifelse(lt, num, NA_real_), qualifier = ifelse(lt, "<", ifelse(gt, ">", NA_character_)))
}

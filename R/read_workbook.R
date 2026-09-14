#' Read a multi-method laboratory workbook
#'
#' Commercial cuttings-analysis deliverables usually arrive as one sheet with
#' every method side by side under a **three-row header** - a *group* row
#' (`SAMPLE INFO`, `TOC`, `TRADITIONAL PYROLYSIS`, `PAM PYROLYSIS`,
#' `XRD BULK MINERALOGY`, `XRD CLAY SPECIATION`, `XRF ELEMENTAL ...`), an
#' *analyte* row and a *unit* row - often followed by an error / QC row, with
#' one sample per row below. Sample rows carry a sample number, the
#' **bottom** depth of a cuttings interval, and formation / zone labels.
#' `read_workbook()` reads that layout into a [gc_data()] object in one call.
#'
#' The header rows are located automatically (the analyte row is the one
#' whose first cells read `SAMPLE ...` and `... DEPTH`; the group row is the one
#' above, the unit row the one below; data start at the first row whose depth
#' is numeric). Override with `header_row` / `data_start` when a file differs.
#'
#' Groups are mapped to methods by name: TOC and traditional pyrolysis ->
#' `"SRA"`; PAM / multi-ramp pyrolysis -> `"PAM"`; XRD -> `"XRD"` (the clay
#' speciation group is folded in, converted to bulk wt% when it is reported
#' relative to total clay - see `clay_basis`); XRF -> `"XRF"` (elements in %,
#' traces in ppm, as reported). Analyte names are normalised (`LECO TOC` ->
#' `TOC`, `HAWK TOC` -> `TOC_pyr`, `S1/TOC*100` -> `S1_TOC`, `FID Oil-1` ->
#' `Oil1`, `Tmax FID Oil-1` -> `Tmax_Oil1`, `K-SPAR` -> `k_feldspar`,
#' `MIX I/S` -> `mixed_layer`, `MAJORS + LE` -> `majors_LE`, ...).
#'
#' Columns the laboratory *calculates* from others (HI, OI, PI, S1/TOC, S2/S3,
#' KQ, Q+F, total carbonate, brittleness, PAM ratios, majors + LE) are dropped
#' by default so that [gc_indices()] is the single source of derived values;
#' `keep_calculated = TRUE` keeps them with `lab = "reported"`.
#'
#' @param path Workbook path (`.xlsx`) or a data frame read with no header
#'   (`header = FALSE`).
#' @param sheet Sheet name or number.
#' @param hole_id Well / hole identifier for every sample.
#' @param interval How to get `depth_top` from a bottom-only depth column:
#'   `"previous"` (default; the previous sample's bottom, the first sample
#'   getting the median spacing), a number (fixed interval length), or
#'   `"point"` (`depth_top = depth_base`).
#' @param keep_calculated Keep lab-calculated columns (see Details).
#' @param clay_basis `"auto"` (default), `"bulk"` or `"relative"`: whether the
#'   clay-speciation columns are wt% of the bulk rock or % of total clay.
#'   `"auto"` treats them as relative when they sum to ~100 while
#'   `total_clay` does not.
#' @param header_row Row number of the *analyte* row (1-based, as in Excel),
#'   or `NULL` to detect.
#' @param data_start First data row (1-based), or `NULL` to detect.
#' @param x,y,z Optional coordinates / elevation stored on every sample.
#' @param crs,depth_unit,lab,source Passed to [gc_data()] / stored on rows.
#' @return A `gc_data` object. The samples table carries `formation` and
#'   `zone` when the sheet has them.
#' @examples
#' f <- system.file("extdata", "cuttings_workbook.xlsx", package = "geochemR")
#' if (nzchar(f) && requireNamespace("readxl", quietly = TRUE)) {
#'   ds <- read_workbook(f, hole_id = "EX-1", lab = "Example Lab")
#'   ds
#'   gc_analytes(ds)
#' }
#' @export
read_workbook <- function(path, sheet = 1, hole_id = "well", interval = "previous", keep_calculated = FALSE,
                          clay_basis = c("auto", "bulk", "relative"), header_row = NULL, data_start = NULL,
                          x = NA_real_, y = NA_real_, z = NA_real_, crs = NA, depth_unit = "ft",
                          lab = NA_character_, source = NA_character_) {
  clay_basis <- match.arg(clay_basis)
  raw <- if (is.data.frame(path)) as.data.frame(path, stringsAsFactors = FALSE) else {
    if (!requireNamespace("readxl", quietly = TRUE)) stop("read_workbook needs the readxl package", call. = FALSE)
    as.data.frame(readxl::read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", .name_repair = "minimal"))
  }
  if (is.na(source) && !is.data.frame(path)) source <- basename(path)
  cell <- function(i, j) { v <- raw[i, j]; if (is.na(v)) "" else trimws(as.character(v)) }
  n <- nrow(raw)
  if (is.null(header_row)) {
    header_row <- NULL
    for (i in seq_len(min(n, 60))) {
      row <- tolower(vapply(seq_len(ncol(raw)), function(j) cell(i, j), character(1)))
      if (grepl("sample", row[1]) && any(grepl("depth", row[2:min(4, length(row))]))) { header_row <- i; break }
    }
    if (is.null(header_row)) stop("could not find the analyte header row (a row starting 'SAMPLE ...' with a 'DEPTH' column); pass header_row=", call. = FALSE)
  }
  group_row <- header_row - 1
  unit_row <- header_row + 1
  names_r <- vapply(seq_len(ncol(raw)), function(j) cell(header_row, j), character(1))
  groups_r <- vapply(seq_len(ncol(raw)), function(j) cell(group_row, j), character(1))
  units_r <- vapply(seq_len(ncol(raw)), function(j) cell(unit_row, j), character(1))
  # forward-fill group labels across merged cells
  g <- ""
  for (j in seq_along(groups_r)) { if (nzchar(groups_r[j])) g <- groups_r[j]; groups_r[j] <- g }
  depth_col <- which(grepl("depth", tolower(names_r)))[1]
  if (is.null(data_start)) {
    data_start <- NULL
    for (i in (unit_row + 1):n) {
      if (!is.na(suppressWarnings(as.numeric(cell(i, depth_col))))) { data_start <- i; break }
    }
    if (is.null(data_start)) stop("no numeric depth found below the header; pass data_start=", call. = FALSE)
  }
  body <- raw[data_start:n, , drop = FALSE]
  body <- body[!is.na(suppressWarnings(as.numeric(body[[depth_col]]))), , drop = FALSE]
  if (!nrow(body)) stop("no data rows", call. = FALSE)

  method_of <- function(group) {
    gl <- tolower(group)
    if (grepl("sample", gl)) return("SAMPLE")
    if (grepl("pam", gl)) return("PAM")
    if (grepl("toc|pyrolysis|rock.?eval|hawk", gl)) return("SRA")
    if (grepl("clay", gl)) return("XRD_CLAY")
    if (grepl("xrd|mineral", gl)) return("XRD")
    if (grepl("xrf|element", gl)) return("XRF")
    NA_character_
  }
  methods <- vapply(groups_r, method_of, character(1))

  # ---- samples ---------------------------------------------------------------
  s_cols <- which(methods == "SAMPLE")
  pick <- function(pattern) { j <- s_cols[grepl(pattern, tolower(names_r[s_cols]))]; if (length(j)) body[[j[1]]] else NULL }
  sample_no <- pick("sample") %||% seq_len(nrow(body))
  depth_base <- as.numeric(body[[depth_col]])
  formation <- pick("formation"); zone <- pick("zone")
  if (identical(interval, "previous")) {
    spacing <- stats::median(diff(depth_base))
    depth_top <- c(depth_base[1] - spacing, depth_base[-length(depth_base)])
  } else if (is.numeric(interval)) depth_top <- depth_base - interval else depth_top <- depth_base
  samples <- tibble::tibble(sample_id = paste0(hole_id, "-", as.character(sample_no)), hole_id = hole_id, x = x, y = y, z = z,
                            depth_top = depth_top, depth_base = depth_base, sample_type = "cuttings",
                            formation = if (is.null(formation)) NA_character_ else as.character(formation),
                            zone = if (is.null(zone)) NA_character_ else as.character(zone))

  # ---- measurements ----------------------------------------------------------
  calc <- c("HI", "OI", "PI", "S1_TOC", "S2_S3", "KQ", "QFM", "carbonate", "BI", "majors_LE", "Oil3_Oil2", "Oil4_Oil3", "K1_Oil4")
  out <- list()
  for (j in which(!is.na(methods) & methods != "SAMPLE")) {
    an <- .workbook_analyte(names_r[j], methods[j])
    if (is.na(an)) next
    m <- if (methods[j] == "XRD_CLAY") "XRD" else methods[j]
    p <- .parse_values(body[[j]])
    if (all(is.na(p$value))) next
    is_calc <- an %in% calc
    if (is_calc && !keep_calculated) next
    out[[length(out) + 1]] <- tibble::tibble(sample_id = samples$sample_id, method = m, analyte = an, value = p$value,
                                             unit = .workbook_unit(units_r[j], an, m), lod = p$lod, qualifier = p$qualifier,
                                             lab = if (is_calc) "reported" else lab, source = source, group = groups_r[j])
  }
  meas <- dplyr::bind_rows(out)
  meas <- meas[!is.na(meas$value) | !is.na(meas$qualifier), ]
  # clay speciation basis
  clay_names <- c("illite", "smectite", "mixed_layer", "kaolinite", "chlorite", "glauconite")
  clay_rows <- meas$method == "XRD" & meas$analyte %in% clay_names & grepl("clay", tolower(meas$group))
  if (any(clay_rows) && clay_basis != "bulk") {
    tc <- meas[meas$analyte == "total_clay", c("sample_id", "value")]
    sums <- tapply(meas$value[clay_rows], meas$sample_id[clay_rows], sum, na.rm = TRUE)
    relative <- clay_basis == "relative" || (clay_basis == "auto" && nrow(tc) > 0 && stats::median(abs(sums - 100), na.rm = TRUE) < 5 &&
                                               stats::median(tc$value, na.rm = TRUE) < 90)
    if (relative) {
      f <- tc$value[match(meas$sample_id[clay_rows], tc$sample_id)] / 100
      meas$value[clay_rows] <- meas$value[clay_rows] * f
      meas$lod[clay_rows] <- meas$lod[clay_rows] * f
      message("read_workbook(): clay speciation reported relative to total clay; converted to bulk wt%")
    }
  }
  meas$group <- NULL
  gc_data(samples, meas, crs = crs, depth_unit = depth_unit, sources = source)
}

.workbook_analyte <- function(name, method) {
  nm <- trimws(name)
  key <- tolower(nm)
  if (!nzchar(key)) return(NA_character_)
  if (method %in% c("XRD", "XRD_CLAY")) {
    if (grepl("quartz\\s*\\+\\s*feld", key)) return("QFM")
    if (grepl("total\\s*carb", key)) return("carbonate")
    if (grepl("brittle", key)) return("BI")
    return(gc_mineral_name(nm))
  }
  if (method == "SRA") {
    if (grepl("leco", key)) return("TOC")
    if (grepl("hawk\\s*toc|rock.?eval\\s*toc|pyrolysis\\s*toc", key)) return("TOC_pyr")
    if (key == "toc") return("TOC")
    if (grepl("^s1\\s*/\\s*toc", key)) return("S1_TOC")
    if (grepl("^s2\\s*/\\s*s3", key)) return("S2_S3")
    if (key %in% c("s1", "s2", "s3", "tmax", "hi", "oi", "pi", "kq", "ro")) return(c(s1 = "S1", s2 = "S2", s3 = "S3", tmax = "Tmax", hi = "HI", oi = "OI", pi = "PI", kq = "KQ", ro = "Ro")[[key]])
    return(gsub("[^A-Za-z0-9]+", "_", nm))
  }
  if (method == "PAM") {
    if (grepl("^tmax", key)) {
      k <- sub("^tmax\\s*(fid\\s*)?", "", key)
      return(paste0("Tmax_", .pam_fraction(k)))
    }
    if (grepl("/", key)) {
      parts <- strsplit(gsub("\\s", "", nm), "/")[[1]]
      return(paste(vapply(parts, .pam_fraction, character(1)), collapse = "_"))
    }
    return(.pam_fraction(sub("^fid\\s*", "", key)))
  }
  if (method == "XRF") {
    if (grepl("light\\s*element", key)) return("LE")
    if (grepl("major", key)) return("majors_LE")
    if (grepl("^egr|gamma", key)) return("EGR")
    if (grepl("^total$", key)) return(NA_character_)
    el <- c(gc_oxides$oxide, unique(gc_oxides$element), "S", "Cl", "P", "Mn", "V", "Cr", "Co", "Ni", "Cu", "Zn", "As", "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Pb", "Th", "U", "Ba", "Ga", "Se", "Sn", "Sb", "Cs", "La", "Ce", "Nd", "Hf", "Ta", "W", "Sc", "Li", "Be", "B", "LOI")
    hit <- el[match(key, tolower(el))]
    return(if (is.na(hit)) gsub("[^A-Za-z0-9]+", "_", nm) else hit)
  }
  NA_character_
}

.pam_fraction <- function(k) {
  k <- gsub("[^a-z0-9]", "", tolower(k))
  k <- sub("^fid", "", k)
  if (grepl("^oil", k)) return(paste0("Oil", sub("^oil", "", k)))
  if (grepl("^k", k)) return(paste0("K", sub("^k", "", k)))
  toupper(k)
}

.workbook_unit <- function(u, analyte, method) {
  ul <- tolower(gsub("\\s", "", u))
  if (grepl("^wt%|^%$|^pct$|^wt%$", ul) || ul == "%") return(if (method == "XRF" && !grepl("^(LE|majors_LE)$", analyte)) "wt%" else "wt%")
  if (grepl("ppm|mg/kg", ul)) return("ppm")
  if (grepl("^(\u00b0|\u2070)?c$", ul)) return("degC")
  if (grepl("mg/g", ul)) return(if (analyte == "S3") "mg CO2/g" else "mg HC/g")
  if (grepl("^c[0-9]", ul) || grepl("kerogen", ul)) return("mg HC/g")   # PAM fractions labelled by carbon range
  if (grepl("api", ul)) return("API")
  if (grepl("hi-oi", ul)) return("index")
  if (nzchar(ul)) return(u)
  # no unit given: fall back on what the analyte is
  if (analyte %in% gc_sra_analytes$analyte) return(gc_sra_analytes$unit[match(analyte, gc_sra_analytes$analyte)])
  if (grepl("^Tmax", analyte)) return("degC")
  if (method %in% c("XRD", "XRD_CLAY")) return("wt%")
  NA_character_
}

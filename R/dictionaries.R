#' Analyte dictionaries
#'
#' `gc_minerals` maps the mineral names labs print to canonical names;
#' `gc_oxides` gives the oxide/element conversion factors; `gc_sra_analytes`
#' the pyrolysis parameters with units and plausible ranges.
#'
#' @format `gc_minerals`: a data frame with `canonical`, `alias`, `group`
#'   (`"tectosilicate"`, `"carbonate"`, `"clay"`, `"sulfide"`, `"other"`).
#'   `gc_oxides`: `oxide`, `element`, `factor` (element fraction of the oxide
#'   by mass, so `element = oxide * factor`). `gc_sra_analytes`: `analyte`,
#'   `unit`, `low`, `high`.
#' @name dictionaries
NULL

.mineral_table <- function() {
  rows <- list(
    c("quartz", "quartz|qtz|silica", "tectosilicate"),
    c("k_feldspar", "k_feldspar|k-feldspar|kspar|k-spar|k spar|k feldspar|orthoclase|microcline|potassium feldspar|kfs", "tectosilicate"),
    c("plagioclase", "plagioclase|plag|albite|anorthite|na feldspar|plagioclase feldspar", "tectosilicate"),
    c("calcite", "calcite|cal", "carbonate"),
    c("dolomite", "dolomite|dol", "carbonate"),
    c("ankerite", "ankerite|ank|fe-dolomite", "carbonate"),
    c("siderite", "siderite|sid", "carbonate"),
    c("aragonite", "aragonite", "carbonate"),
    c("pyrite", "pyrite|py", "sulfide"),
    c("marcasite", "marcasite", "sulfide"),
    c("apatite", "apatite|fluorapatite|ap", "other"),
    c("anhydrite", "anhydrite|anh", "other"),
    c("gypsum", "gypsum|gyp", "other"),
    c("halite", "halite|hal", "other"),
    c("barite", "barite|baryte", "other"),
    c("hematite", "hematite|hem", "other"),
    c("goethite", "goethite", "other"),
    c("illite", "illite|ill|illite_mica|illite/mica|illite+mica|mica", "clay"),
    c("smectite", "smectite|sme|montmorillonite", "clay"),
    c("mixed_layer", "mixed_layer|mixed-layer|mixed layer|i/s|mix i/s|mixed i/s|illite_smectite|illite/smectite|i-s|ml", "clay"),
    c("kaolinite", "kaolinite|kao|kaol", "clay"),
    c("chlorite", "chlorite|chl", "clay"),
    c("glauconite", "glauconite", "clay"),
    c("total_clay", "total_clay|total clay|clays|clay|tot_clay|sum clay", "clay"),
    c("amorphous", "amorphous|amorph|glass|organic", "other"),
    c("other", "other|others|unidentified|trace", "other")
  )
  do.call(rbind, lapply(rows, function(r) {
    al <- strsplit(r[2], "|", fixed = TRUE)[[1]]
    data.frame(canonical = r[1], alias = al, group = r[3], stringsAsFactors = FALSE)
  }))
}

.oxide_table <- function() {
  # element mass fraction of each oxide (element = oxide * factor)
  data.frame(
    oxide   = c("SiO2", "TiO2", "Al2O3", "Fe2O3", "FeO", "MnO", "MgO", "CaO", "Na2O", "K2O", "P2O5", "SO3", "Cr2O3", "BaO", "SrO", "ZrO2", "V2O5", "NiO", "CuO", "ZnO"),
    element = c("Si", "Ti", "Al", "Fe", "Fe", "Mn", "Mg", "Ca", "Na", "K", "P", "S", "Cr", "Ba", "Sr", "Zr", "V", "Ni", "Cu", "Zn"),
    factor  = c(0.4674, 0.5995, 0.5293, 0.6994, 0.7773, 0.7745, 0.6030, 0.7147, 0.7419, 0.8302, 0.4364, 0.4005, 0.6842, 0.8957, 0.8456, 0.7403, 0.5602, 0.7858, 0.7989, 0.8034),
    stringsAsFactors = FALSE
  )
}

.sra_table <- function() {
  data.frame(
    analyte = c("TOC", "TOC_pyr", "S1", "S2", "S3", "Tmax", "HI", "OI", "PI", "Ro", "Ro_eq", "S1_TOC", "S2_S3", "KQ"),
    unit    = c("wt%", "wt%", "mg HC/g", "mg HC/g", "mg CO2/g", "degC", "mg HC/g TOC", "mg CO2/g TOC", "frac", "%", "%", "mg HC/g TOC", "ratio", "index"),
    low     = c(0, 0, 0, 0, 0, 300, 0, 0, 0, 0, 0, 0, 0, NA),
    high    = c(100, 100, NA, NA, NA, 650, 1200, 600, 1, 6, 6, NA, NA, NA),
    stringsAsFactors = FALSE
  )
}

#' @rdname dictionaries
#' @export
gc_minerals <- .mineral_table()

#' @rdname dictionaries
#' @export
gc_oxides <- .oxide_table()

#' @rdname dictionaries
#' @export
gc_sra_analytes <- .sra_table()

#' @rdname dictionaries
#' @format `gc_pam_analytes`: the multi-ramp (PAM) pyrolysis fractions  - 
#'   `Oil1` ... `Oil4` and `K1` in mg HC/g with the carbon range each fraction
#'   represents, plus one `Tmax_*` per fraction.
#' @export
gc_pam_analytes <- data.frame(
  analyte = c("Oil1", "Oil2", "Oil3", "Oil4", "K1", "Tmax_Oil1", "Tmax_Oil2", "Tmax_Oil3", "Tmax_Oil4", "Tmax_K1"),
  unit = c(rep("mg HC/g", 5), rep("degC", 5)),
  carbon_range = c("C4-C5", "C6-C10", "C11-C19", "C20-C36", "kerogen + C37+", rep(NA, 5)),
  stringsAsFactors = FALSE
)

#' Canonical mineral names
#'
#' @param x Character vector of mineral names as printed by a lab.
#' @param strict Error (rather than pass through unchanged) on names that no
#'   alias matches.
#' @return Character vector of canonical names (see [gc_minerals]).
#' @examples
#' gc_mineral_name(c("Quartz", "K-Feldspar", "I/S", "Illite/Mica"))
#' @export
gc_mineral_name <- function(x, strict = FALSE) {
  key <- tolower(trimws(gsub("[[:space:]]+", " ", x)))
  key <- gsub("\\s*\\(.*?\\)\\s*$", "", key)          # drop trailing "(wt%)"
  key <- sub("_?(wt%|wt\\.%|wt|pct|%)$", "", key)
  key <- trimws(key)
  hit <- gc_minerals$canonical[match(key, gc_minerals$alias)]
  miss <- is.na(hit)
  if (strict && any(miss)) stop("unrecognised mineral names: ", paste(unique(x[miss]), collapse = ", "), call. = FALSE)
  hit[miss] <- gsub("[^a-z0-9]+", "_", key[miss])
  hit
}

#' @rdname gc_mineral_name
#' @export
gc_mineral_group <- function(x) {
  gc_minerals$group[match(gc_mineral_name(x), gc_minerals$canonical)]
}

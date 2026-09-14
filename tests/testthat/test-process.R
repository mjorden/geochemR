test_that("LOD substitution follows the chosen convention and keeps the qualifier", {
  ds <- gc_example
  cens <- gc_measurements(ds, "XRF")
  cens <- cens[!is.na(cens$qualifier) & cens$qualifier == "<", ]
  expect_gt(nrow(cens), 0)
  half <- gc_measurements(gc_substitute_lod(ds, "half"), "XRF")
  half <- half[!is.na(half$qualifier) & half$qualifier == "<", ]
  expect_equal(half$value, cens$lod / 2)
  expect_equal(half$qualifier, cens$qualifier)
  zero <- gc_measurements(gc_substitute_lod(ds, "zero"), "XRF")
  expect_true(all(zero$value[!is.na(zero$qualifier) & zero$qualifier == "<"] == 0))
  na <- gc_measurements(gc_substitute_lod(ds, "na"), "XRF")
  expect_true(all(is.na(na$value[!is.na(na$qualifier) & na$qualifier == "<"])))
})

test_that("unit conversion scales values and detection limits", {
  m <- data.frame(sample_id = c("A", "A"), method = "XRF", analyte = c("Zr", "SiO2"), value = c(200, 60), unit = c("ppm", "wt%"), lod = c(5, NA))
  ds <- gc_data(data.frame(sample_id = "A"), m)
  w <- gc_measurements(gc_convert_units(ds, "wt%"))
  expect_equal(w$value, c(0.02, 60)); expect_equal(w$lod, c(0.0005, NA)); expect_true(all(w$unit == "wt%"))
  p <- gc_measurements(gc_convert_units(ds, "ppm"))
  expect_equal(p$value, c(200, 600000))
  only <- gc_measurements(gc_convert_units(ds, "ppb", analytes = "Zr"))
  expect_equal(only$value, c(200000, 60)); expect_equal(only$unit, c("ppb", "wt%"))
})

test_that("oxide/element conversion uses the mass factors and round-trips", {
  m <- data.frame(sample_id = "A", method = "XRF", analyte = c("SiO2", "Al2O3", "Zr"), value = c(60, 15, 100), unit = c("wt%", "wt%", "ppm"))
  ds <- gc_data(data.frame(sample_id = "A"), m)
  el <- gc_measurements(gc_oxide_to_element(ds))
  expect_setequal(el$analyte, c("Zr", "Si", "Al"))
  expect_equal(el$value[el$analyte == "Si"], 60 * 0.4674)
  expect_equal(el$value[el$analyte == "Al"], 15 * 0.5293)
  back <- gc_measurements(gc_element_to_oxide(gc_oxide_to_element(ds)))
  expect_equal(back$value[back$analyte == "SiO2"], 60)
  keep <- gc_measurements(gc_oxide_to_element(ds, keep = TRUE))
  expect_equal(nrow(keep), 5)
})

test_that("renormalisation hits the target and respects exclusions", {
  m <- data.frame(sample_id = c("A", "A", "A", "B", "B"), method = "XRD", analyte = c("quartz", "calcite", "total_clay", "quartz", "calcite"),
                  value = c(60, 30, 10, 45, 45))
  ds <- suppressWarnings(gc_data(data.frame(sample_id = c("A", "B")), m))
  r <- gc_measurements(gc_renormalize(ds))
  # A already closes: 60 + 30 + total_clay 10 = 100, so the non-clays keep their values (#4)
  expect_equal(r$value[r$sample_id == "A" & r$analyte != "total_clay"], c(60, 30))
  expect_equal(r$value[r$analyte == "total_clay"], 10)      # excluded, untouched
  expect_equal(sum(r$value[r$sample_id == "B"]), 100)
  # an explicit exclusion is honoured on its own terms
  r2 <- gc_measurements(suppressWarnings(gc_renormalize(ds, exclude = "calcite")))   # B is 45 before: tolerance warning
  expect_equal(r2$value[r2$sample_id == "B" & r2$analyte == "quartz"], 100)
  expect_equal(r2$value[r2$sample_id == "B" & r2$analyte == "calcite"], 45)
})

test_that("clr rows centre to zero and alr drops the denominator", {
  x <- matrix(c(60, 30, 10, 45, 45, 10), ncol = 3, byrow = TRUE, dimnames = list(NULL, c("q", "c", "cl")))
  cl <- gc_clr(x)
  expect_equal(unname(rowSums(cl)), c(0, 0))
  al <- gc_alr(x, "cl")
  expect_equal(colnames(al), c("q", "c"))
  expect_equal(unname(al[1, "q"]), log(60 / 10))
  z <- gc_clr(rbind(x, c(0, 50, 50)))
  expect_false(any(is.infinite(z)))
})

test_that("interval stats and hole summaries aggregate as expected", {
  st <- gc_interval_stats(gc_example, "SRA", breaks = 50, analytes = "TOC")
  expect_true(all(c("hole_id", "x", "y", "bin_top", "bin_base", "n", "TOC") %in% names(st)))
  expect_true(all(st$bin_base - st$bin_top == 50))
  expect_true(all(st$n >= 1))
  hs <- gc_hole_summary(gc_example, "SRA", depth = c(60, 110), analytes = c("TOC", "Tmax"))
  expect_equal(nrow(hs), 12)
  expect_true(all(hs$TOC > 0))
  hm <- gc_hole_summary(gc_example, "SRA", fun = max, analytes = "TOC")
  expect_true(all(hm$TOC >= hs$TOC[match(hm$hole_id, hs$hole_id)] - 1e-9))
})

test_that("interval stats never return -Inf / NaN for an empty bin (#5)", {
  # one hole, TOC only on the deep sample: the shallow bin has samples but no TOC
  s <- data.frame(sample_id = c("A", "B"), hole_id = "H", x = 0, y = 0, depth_top = c(0, 50), depth_base = c(10, 60))
  m <- data.frame(sample_id = c("A", "B", "B"), method = "SRA", analyte = c("S1", "TOC", "S1"), value = c(0.1, 2, 0.2))
  ds <- gc_data(s, m)
  for (f in list(max, mean, min, median)) {
    st <- gc_interval_stats(ds, "SRA", breaks = 10, fun = f)
    expect_false(any(is.nan(st$TOC)) || any(is.infinite(st$TOC)))
    expect_true(is.na(st$TOC[st$bin_top == 0]))
    expect_equal(st$TOC[st$bin_top == 50], 2)
  }
  # and on the example data with a coarse binning
  st <- gc_interval_stats(gc_example, "SRA", breaks = 5, fun = max)
  expect_false(any(is.infinite(as.matrix(st[, -(1:6)]))))
})

test_that("gc_renormalize leaves derived rows alone and closes total_clay-only samples (#4)", {
  s <- data.frame(sample_id = c("A", "B"))
  m <- data.frame(sample_id = c("A", "A", "A", "A", "B", "B", "B"), method = "XRD",
                  analyte = c("quartz", "calcite", "illite", "kaolinite", "quartz", "calcite", "total_clay"),
                  value = c(40, 20, 15, 5, 30, 20, 30))
  # A sums to 80 with species; B has non-clays 50 + total_clay 30 = 80
  ds <- gc_indices(suppressWarnings(gc_data(s, m)), "xrd")
  before <- gc_measurements(ds)
  rn <- suppressWarnings(gc_renormalize(ds))
  after <- gc_measurements(rn)
  a <- after[after$sample_id == "A" & after$origin == "measured", ]
  expect_equal(sum(a$value), 100)
  expect_equal(a$value[a$analyte == "quartz"], 50)
  b <- after[after$sample_id == "B" & after$origin == "measured", ]
  expect_equal(b$value[b$analyte == "total_clay"], 30)                     # untouched
  expect_equal(sum(b$value[b$analyte != "total_clay"]), 70)                # closes to 100 - 30
  expect_equal(b$value[b$analyte == "quartz"], 42)
  # derived rows are byte-identical before and after
  expect_equal(after[after$origin == "derived", ], before[before$origin == "derived", ])
  expect_warning(gc_renormalize(ds, tolerance = 0.1), "sum to more than 10% of 100 away")
  expect_silent(gc_renormalize(gc_data(data.frame(sample_id = "C"), data.frame(sample_id = "C", method = "XRD", analyte = c("quartz", "calcite"), value = c(52, 50)))))
})

test_that("gc_convert_units touches XRF only unless told otherwise (#7)", {
  ds <- gc_example
  p <- gc_convert_units(ds, "ppm")
  m <- gc_measurements(p)
  expect_true(all(m$unit[m$method == "XRF" & m$analyte == "SiO2"] == "ppm"))
  expect_true(all(m$unit[m$method == "SRA" & m$analyte == "TOC"] == "wt%"))
  expect_true(all(m$unit[m$method == "XRD"] == "wt%"))
  # indices are unaffected by an XRF conversion
  expect_equal(gc_wide(gc_indices(p), "SRA")$HI, gc_wide(gc_indices(ds), "SRA")$HI)
  # converting everything is possible but gc_indices() then refuses the SRA / XRD inputs
  all_ppm <- gc_convert_units(ds, "ppm", method = NULL)
  expect_true(all(gc_measurements(all_ppm, "SRA")$unit[gc_measurements(all_ppm, "SRA")$analyte == "TOC"] == "ppm"))
  expect_error(gc_indices(all_ppm, "sra"), "TOC is in ppm")
  expect_error(gc_indices(all_ppm, "xrd"), "expect wt%")
  expect_silent(gc_indices(all_ppm, "xrf"))
})

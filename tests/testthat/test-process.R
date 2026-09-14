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
  expect_equal(r$value[r$sample_id == "A" & r$analyte != "total_clay"], c(60, 30) / 90 * 100)
  expect_equal(r$value[r$analyte == "total_clay"], 10)      # excluded, untouched
  expect_equal(sum(r$value[r$sample_id == "B"]), 100)
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

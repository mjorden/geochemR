test_that("SRA indices reproduce the textbook definitions", {
  m <- data.frame(sample_id = c("A", "A", "A", "A", "A", "B", "B"), method = "SRA",
                  analyte = c("TOC", "S1", "S2", "S3", "Tmax", "TOC", "Tmax"), value = c(2.0, 0.5, 8.0, 0.4, 440, 1.0, 520))
  ds <- gc_indices(gc_data(data.frame(sample_id = c("A", "B")), m), "sra")
  w <- gc_wide(ds, "SRA")
  a <- w[w$sample_id == "A", ]
  expect_equal(a$HI, 400); expect_equal(a$OI, 20); expect_equal(a$PI, 0.5 / 8.5); expect_equal(a$S1_TOC, 25)
  expect_equal(a$Ro_eq, 0.0180 * 440 - 7.16)
  b <- w[w$sample_id == "B", ]
  expect_true(is.na(b$HI)); expect_true(is.na(b$Ro_eq))   # no S2; Tmax outside 400-500
  # lean samples: HI / OI not reported below min_toc, PI and Ro_eq still are
  lean <- data.frame(sample_id = "L", method = "SRA", analyte = c("TOC", "S1", "S2", "S3", "Tmax"), value = c(0.2, 0.1, 0.3, 0.5, 435))
  wl <- gc_wide(gc_indices(gc_data(data.frame(sample_id = "L"), lean), "sra"), "SRA")
  absent_or_na <- function(v) is.null(v) || all(is.na(v))   # no derived rows at all, or NA
  expect_true(absent_or_na(wl$HI) && absent_or_na(wl$OI) && absent_or_na(wl$S1_TOC))
  expect_equal(wl$PI, 0.1 / 0.4); expect_false(is.na(wl$Ro_eq))
  wl2 <- gc_wide(gc_indices(gc_data(data.frame(sample_id = "L"), lean), "sra", min_toc = 0), "SRA")
  expect_equal(wl2$HI, 150)
  expect_true(all(gc_measurements(ds)$lab[gc_measurements(ds)$analyte == "HI"] == "derived"))
  # running twice does not duplicate derived rows
  expect_equal(nrow(gc_measurements(gc_indices(ds))), nrow(gc_measurements(ds)))
})

test_that("CIA and element ratios come out right on a known composition", {
  # pure Al2O3 -> CIA 100; equal molar Al2O3 and CaO -> 50
  m <- data.frame(sample_id = c("P", "P", "P", "E", "E"), method = "XRF", analyte = c("Al2O3", "SiO2", "CaO", "Al2O3", "CaO"),
                  value = c(20, 60, 0, 101.96, 56.08), unit = "wt%")
  w <- gc_wide(gc_indices(gc_data(data.frame(sample_id = c("P", "E")), m), "xrf"), "XRF")
  expect_equal(w$CIA[w$sample_id == "P"], 100)
  expect_equal(w$CIA[w$sample_id == "E"], 50)
  expect_equal(w$Si_Al[w$sample_id == "P"], (60 * 0.4674) / (20 * 0.5293))
  # element input in ppm is converted before the calculation
  m2 <- data.frame(sample_id = "Q", method = "XRF", analyte = c("Al", "Ca"), value = c(105860, 0), unit = c("ppm", "ppm"))
  w2 <- gc_wide(gc_indices(gc_data(data.frame(sample_id = "Q"), m2), "xrf"), "XRF")
  expect_equal(w2$CIA, 100)
})

test_that("XRD group sums and mineralogical brittleness", {
  m <- data.frame(sample_id = "A", method = "XRD", analyte = c("quartz", "dolomite", "calcite", "illite", "kaolinite", "pyrite"),
                  value = c(40, 10, 20, 20, 5, 5))
  w <- gc_wide(gc_indices(gc_data(data.frame(sample_id = "A"), m), "xrd"), "XRD")
  expect_equal(w$carbonate, 30); expect_equal(w$clay, 25); expect_equal(w$QFM, 40)
  expect_equal(w$BI_min, (40 + 10) / (40 + 10 + 20 + 25))
  # total_clay wins over the sum of individual clays when reported
  m2 <- rbind(m, data.frame(sample_id = "A", method = "XRD", analyte = "total_clay", value = 28))
  w2 <- gc_wide(gc_indices(suppressWarnings(gc_data(data.frame(sample_id = "A"), m2)), "xrd"), "XRD")
  expect_equal(w2$clay, 28)
})

test_that("mineral name normalisation", {
  expect_equal(gc_mineral_name(c("Quartz", "K-Feldspar", "I/S", "Illite/Mica", "Total Clay (wt%)", "Weirdite")),
               c("quartz", "k_feldspar", "mixed_layer", "illite", "total_clay", "weirdite"))
  expect_error(gc_mineral_name("Weirdite", strict = TRUE), "unrecognised")
  expect_equal(gc_mineral_group(c("calcite", "Illite", "Pyrite")), c("carbonate", "clay", "sulfide"))
})

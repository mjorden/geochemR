samples <- data.frame(sample_id = c("A1", "A2", "A3"), hole_id = c("H1", "H1", "H2"), x = c(0, 0, 100), y = c(0, 0, 0),
                      depth_top = c(10, 20, 10), depth_base = c(20, 30, 10))
meas <- data.frame(sample_id = c("A1", "A1", "A2", "A2", "A3", "A3"), method = "xrd",
                   analyte = c("quartz", "calcite", "quartz", "calcite", "quartz", "calcite"),
                   value = c(60, 40, 55, 45, 70, 30))

test_that("gc_data builds, fills defaults and prints", {
  ds <- gc_data(samples, meas, crs = 26914)
  expect_s3_class(ds, "gc_data")
  expect_equal(gc_samples(ds)$depth_mid, c(15, 25, 10))
  expect_equal(unique(gc_measurements(ds)$method), "XRD")
  expect_true(all(is.na(gc_measurements(ds)$lod)))
  expect_equal(gc_analytes(ds), list(XRD = c("quartz", "calcite")))
  expect_output(print(ds), "3 samples in 2 holes; 6 measurements")
  expect_output(print(ds), "EPSG:26914")
})

test_that("validation catches structural errors and warns on data problems", {
  expect_error(gc_data(samples, rbind(meas, data.frame(sample_id = "ZZ", method = "XRD", analyte = "quartz", value = 1))), "unknown sample_id")
  bad <- samples; bad$depth_base[1] <- 5
  expect_error(gc_data(bad, meas), "depth_top > depth_base")
  expect_error(gc_data(rbind(samples, samples[1, ]), meas), "duplicate sample_id")
  sra <- data.frame(sample_id = "A1", method = "SRA", analyte = "TOC", value = 2)
  expect_warning(gc_data(samples, rbind(meas, sra, sra)), "duplicate .* measurement rows")
  cens <- meas; cens$lod <- c(NA, NA, 60, NA, NA, NA)     # A2 quartz 55 < lod 60, no qualifier
  expect_warning(gc_data(samples, cens), "below their detection limit")
  off <- meas; off$value[3] <- 120                          # A2 sums to 165
  expect_warning(gc_data(samples, off), "XRD sample\\(s\\) total")
})

test_that("gc_example has every method on every sample (#1)", {
  s <- gc_samples(gc_example)
  for (meth in c("XRD", "XRF")) {
    have <- unique(gc_measurements(gc_example, meth)$sample_id)
    expect_setequal(have, s$sample_id)
  }
  # SRA is deliberately sparse on cuttings ("not every cuttings sample was run") but complete on core
  sra <- unique(gc_measurements(gc_example, "SRA")$sample_id)
  expect_true(all(s$sample_id[s$sample_type == "core"] %in% sra))
  expect_gt(length(sra), nrow(s) / 2)
  xrd <- gc_wide(gc_example, "XRD")
  expect_false(anyNA(xrd$quartz))
  expect_true(all(abs(rowSums(xrd[, c("quartz", "k_feldspar", "plagioclase", "calcite", "dolomite", "pyrite",
                                      "illite", "mixed_layer", "kaolinite", "chlorite")]) - 100) < 1))
})

test_that("gc_wide pivots and joins the sample table", {
  w <- gc_wide(gc_data(samples, meas), "XRD")
  expect_true(all(c(names(samples), "depth_mid", "quartz", "calcite") %in% names(w)))
  expect_equal(names(w)[1], "sample_id")
  expect_equal(w$quartz, c(60, 55, 70))
  expect_equal(w$calcite, c(40, 45, 30))
  expect_error(gc_wide(gc_data(samples, meas), "SRA"), "no SRA")
})

test_that("gc_bind appends methods and new samples", {
  ds <- gc_data(samples, meas)
  extra <- data.frame(sample_id = "A1", method = "SRA", analyte = "TOC", value = 2.1)
  ds2 <- gc_bind(ds, extra)
  expect_equal(sort(unique(gc_measurements(ds2)$method)), c("SRA", "XRD"))
  other <- gc_data(data.frame(sample_id = "B1", hole_id = "H3", depth_top = 1), data.frame(sample_id = "B1", method = "XRF", analyte = "SiO2", value = 50), sources = "b")
  ds3 <- gc_bind(ds, other)
  expect_equal(nrow(gc_samples(ds3)), 4)
  expect_equal(ds3$meta$sources, "b")
})

test_that("the bundled example is valid and has all three methods", {
  expect_s3_class(gc_example, "gc_data")
  expect_setequal(names(gc_analytes(gc_example)), c("SRA", "XRD", "XRF"))
  expect_equal(length(unique(gc_samples(gc_example)$hole_id)), 12)
  expect_silent(validate_gc(gc_example))
  m <- gc_measurements(gc_example, "XRF")
  expect_true(any(m$qualifier == "<", na.rm = TRUE))
})

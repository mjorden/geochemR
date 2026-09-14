skip_if_not_installed("readxl")
f <- system.file("extdata", "cuttings_workbook.xlsx", package = "geochemR")
if (!nzchar(f)) f <- file.path("..", "..", "inst", "extdata", "cuttings_workbook.xlsx")
skip_if_not(file.exists(f), "example workbook not built")

test_that("read_workbook parses the three-row-header deliverable layout", {
  expect_message(ds <- read_workbook(f, hole_id = "EX-1", lab = "L"), "clay speciation reported relative")
  expect_s3_class(ds, "gc_data")
  s <- gc_samples(ds)
  expect_equal(nrow(s), 65)
  expect_equal(unique(s$hole_id), "EX-1")
  expect_equal(s$depth_base[1:3], c(6030, 6060, 6090))
  expect_equal(s$depth_top[1:3], c(6000, 6030, 6060))          # previous bottom; first gets the median spacing
  expect_true(all(s$sample_type == "cuttings"))
  expect_setequal(unique(s$formation), c("Upper Shale", "Target Shale", "Carbonate", "Lower Sand"))
  expect_true(all(c("TS-A", "TS-B") %in% s$zone))
  expect_setequal(names(gc_analytes(ds)), c("SRA", "PAM", "XRD", "XRF"))
  an <- gc_analytes(ds)
  expect_setequal(an$SRA, c("TOC", "TOC_pyr", "S1", "S2", "Tmax", "S3"))            # calculated columns dropped
  expect_setequal(an$PAM, c("Oil1", "Tmax_Oil1", "Oil2", "Tmax_Oil2", "Oil3", "Tmax_Oil3", "Oil4", "Tmax_Oil4", "K1", "Tmax_K1"))
  expect_setequal(an$XRD, c("quartz", "k_feldspar", "plagioclase", "calcite", "dolomite", "siderite", "pyrite", "total_clay",
                            "chlorite", "kaolinite", "illite", "mixed_layer"))
  expect_true(all(c("EGR", "Si", "Al", "Ca", "LE", "Mo", "Ba", "U") %in% an$XRF))
  expect_false("majors_LE" %in% an$XRF)
  m <- gc_measurements(ds)
  expect_equal(unique(m$unit[m$analyte == "Tmax"]), "degC")
  expect_equal(unique(m$unit[m$analyte == "Tmax_Oil2"]), "degC")
  expect_equal(unique(m$unit[m$analyte == "Oil1"]), "mg HC/g")
  expect_equal(unique(m$unit[m$analyte == "S3"]), "mg CO2/g")
  expect_equal(unique(m$unit[m$analyte == "Si"]), "wt%")
  expect_equal(unique(m$unit[m$analyte == "Mo"]), "ppm")
  expect_equal(unique(m$unit[m$analyte == "EGR"]), "API")
  expect_true(any(m$qualifier[m$analyte == "Mo"] == "<", na.rm = TRUE))
  expect_true(all(m$lab == "L"))
  # clay speciation converted to bulk: the four clays sum to total_clay
  w <- gc_wide(ds, "XRD")
  expect_equal(w$chlorite + w$kaolinite + w$illite + w$mixed_layer, w$total_clay, tolerance = 0.02)
})

test_that("keep_calculated keeps lab-reported derived columns tagged as such", {
  ds <- suppressMessages(read_workbook(f, hole_id = "EX-1", keep_calculated = TRUE))
  m <- gc_measurements(ds)
  expect_true(all(c("HI", "OI", "PI", "S1_TOC", "S2_S3", "KQ", "QFM", "carbonate", "BI", "majors_LE", "Oil3_Oil2") %in% m$analyte))
  expect_equal(unique(m$lab[m$analyte == "HI"]), "reported")
  # gc_indices adds its own HI as 'derived' alongside the reported one
  di <- gc_measurements(gc_indices(ds))
  expect_setequal(unique(di$lab[di$analyte == "HI"]), c("reported", "derived"))
})

test_that("interval options and clay_basis override", {
  fixed <- suppressMessages(read_workbook(f, hole_id = "W", interval = 10))
  expect_equal(gc_samples(fixed)$depth_top[1], 6020)
  pt <- suppressMessages(read_workbook(f, hole_id = "W", interval = "point"))
  expect_equal(gc_samples(pt)$depth_top, gc_samples(pt)$depth_base)
  # forcing "bulk" on relative clay data: no conversion, and the XRD-total check catches the mistake
  expect_warning(bulk <- read_workbook(f, hole_id = "W", clay_basis = "bulk"), "XRD sample\\(s\\) total")
  w <- gc_wide(bulk, "XRD")
  expect_equal(w$chlorite + w$kaolinite + w$illite + w$mixed_layer, rep(100, nrow(w)), tolerance = 0.02)
})

test_that("read_workbook fails loudly on a sheet without the header", {
  expect_error(read_workbook(data.frame(a = c("x", "y"), b = c("1", "2"))), "header row")
})

test_that("PAM and weighted brittleness indices", {
  ds <- gc_indices(suppressMessages(read_workbook(f, hole_id = "EX-1")))
  w <- gc_wide(ds, "PAM")
  expect_equal(w$Oil_total, w$Oil1 + w$Oil2 + w$Oil3 + w$Oil4)
  expect_equal(w$Oil3_Oil2, w$Oil3 / w$Oil2)
  expect_true("Oil_TOC" %in% names(w))
  x <- gc_wide(ds, "XRD")
  expect_true(all(x$BI_w >= 0 & x$BI_w <= 100))
  qf <- x$quartz + x$k_feldspar + x$plagioclase; carb <- x$calcite + x$dolomite + x$siderite
  expect_equal(x$BI_w, 100 * (1.5 * qf + 1.5 * carb) / (1.5 * qf + 1.5 * carb + 2 * x$total_clay))
})

test_that("stratigraphic summaries group by formation and zone", {
  ds <- gc_cuttings
  s <- gc_hole_summary(ds, "SRA", by = c("hole_id", "formation"), analytes = c("TOC", "Tmax"))
  expect_equal(nrow(s), 4)
  expect_true(s$TOC[s$formation == "Target Shale"] > s$TOC[s$formation == "Carbonate"])
  expect_true(all(c("depth_top", "depth_base") %in% names(s)))
  z <- gc_hole_summary(ds, "SRA", by = c("hole_id", "zone"), analytes = "TOC")
  expect_true(all(c("TS-A", "TS-B") %in% z$zone))
})

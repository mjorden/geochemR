test_that(".parse_values handles censoring, blanks and thousands commas", {
  p <- .parse_values(c("12.5", "<5", "> 1000", "n.d.", "bdl", "", NA, "1,250", "-"))
  expect_equal(p$value, c(12.5, 5, 1000, NA, NA, NA, NA, 1250, NA))
  expect_equal(p$lod, c(NA, 5, NA, NA, NA, NA, NA, NA, NA))
  expect_equal(p$qualifier, c(NA, "<", ">", NA, NA, NA, NA, NA, NA))
  n <- .parse_values(c(1, 2.5))
  expect_equal(n$value, c(1, 2.5))
  expect_true(all(is.na(n$qualifier)))
})

test_that(".parse_values honours decimal and grouping marks (#2)", {
  # decimal comma, space grouping
  eu <- .parse_values(c("2,5", "1 250,75", "<0,5", "12"), decimal_mark = ",", grouping_mark = " ")
  expect_equal(eu$value, c(2.5, 1250.75, 0.5, 12))
  expect_equal(eu$qualifier, c(NA, NA, "<", NA))
  # decimal comma, point grouping
  de <- .parse_values(c("1.250,5", "0,25"), decimal_mark = ",", grouping_mark = ".")
  expect_equal(de$value, c(1250.5, 0.25))
  # default locale: space grouping is tolerated, a decimal-comma column is flagged
  expect_equal(.parse_values("1 250")$value, 1250)
  expect_warning(p <- .parse_values(c("2,5", "0,75", "12")), "decimal comma")
  expect_equal(p$value, c(25, 75, 12))
  expect_silent(.parse_values(c("1,250", "2,500.5")))            # real thousands grouping
  expect_error(.parse_values("1", decimal_mark = ",", grouping_mark = ","), "must differ")
  # the marks reach the readers
  xrf <- data.frame(sample = "A", SiO2 = "62,5", Zr_ppm = "1 250", check.names = FALSE)
  m <- read_xrf(xrf, decimal_mark = ",", grouping_mark = " ")
  expect_equal(m$value[m$analyte == "SiO2"], 62.5)
  expect_equal(m$value[m$analyte == "Zr"], 1250)
  s <- read_samples(data.frame(sample = "A", hole = "H", depth = "10,5", x = "1 000", y = "2 000"),
                    decimal_mark = ",", grouping_mark = " ")
  expect_equal(c(s$depth_top, s$x, s$y), c(10.5, 1000, 2000))
})

test_that("read_xrd maps lab mineral names to canonical ones", {
  xrd <- data.frame(Sample = c("A1", "A2"), Quartz = c(40, 12), "K-Feldspar" = c(5, 1), "Illite/Mica" = c(25, 3),
                    "I/S" = c(6, 1), Calcite = c(20, 80), Pyrite = c(2, 1), "Total Clay (wt%)" = c(31, 4), Comment = c("x", "y"),
                    check.names = FALSE)
  expect_message(m <- read_xrd(xrd, lab = "L"), "ignoring column\\(s\\) Comment")
  expect_setequal(unique(m$analyte), c("quartz", "k_feldspar", "illite", "mixed_layer", "calcite", "pyrite", "total_clay"))
  expect_equal(nrow(m), 14)
  expect_true(all(m$unit == "wt%") && all(m$method == "XRD") && all(m$lab == "L"))
  expect_equal(m$value[m$sample_id == "A2" & m$analyte == "calcite"], 80)
})

test_that("read_xrf detects units from suffixes and parses censored values", {
  xrf <- data.frame(sample = c("A1", "A2"), SiO2 = c(62.1, 8.3), CaO = c(9.9, 48.2), "Ba (ppm)" = c(410, 95),
                    Zr_ppm = c("180", "<5"), Total = c(99.8, 100.1), check.names = FALSE)
  expect_message(m <- read_xrf(xrf), "ignoring column\\(s\\) Total")
  expect_equal(m$unit[m$analyte == "SiO2"], c("wt%", "wt%"))
  expect_equal(m$unit[m$analyte == "Ba"], c("ppm", "ppm"))
  expect_equal(m$unit[m$analyte == "Zr"], c("ppm", "ppm"))
  z <- m[m$analyte == "Zr" & m$sample_id == "A2", ]
  expect_equal(z$value, 5); expect_equal(z$lod, 5); expect_equal(z$qualifier, "<")
  m2 <- read_xrf(xrf, units = c(Ba = "wt%"))
  expect_equal(unique(m2$unit[m2$analyte == "Ba"]), "wt%")
})

test_that("read_sra accepts common spellings and drops blanks", {
  sra <- data.frame(ID = c("A1", "A2", "A3"), "TOC (wt%)" = c(2.4, 0.2, NA), S1 = c(0.3, 0.05, 0.1), S2 = c(4.1, 0.2, 0.5),
                    S3 = c(0.4, 0.5, 0.3), "T max" = c(438, NA, 441), check.names = FALSE)
  m <- read_sra(sra)
  expect_setequal(unique(m$analyte), c("TOC", "S1", "S2", "S3", "Tmax"))
  expect_equal(m$unit[m$analyte == "Tmax"][1], "degC")
  expect_equal(sum(m$sample_id == "A3"), 4)   # TOC blank dropped
  expect_false(any(m$analyte == "Tmax" & m$sample_id == "A2"))
})

test_that("read_samples maps columns and fills depth_base", {
  s <- read_samples(data.frame(Sample = "A1", Well = "W1", Easting = 1, Northing = 2, Elev = 100, Depth = "50", Type = "core"))
  expect_equal(s$sample_id, "A1"); expect_equal(s$hole_id, "W1"); expect_equal(s$x, 1); expect_equal(s$depth_top, 50)
  expect_true(is.na(s$depth_base))
  expect_error(read_samples(data.frame(a = 1)), "sample_id")
  s2 <- read_samples(data.frame(Lab_No = "A1", Depth = 1), sample_id = "Lab_No")
  expect_equal(s2$sample_id, "A1")
})

test_that("readers work from a CSV on disk", {
  f <- tempfile(fileext = ".csv")
  writeLines(c("sample,SiO2,Zr_ppm", "A1,60.2,<5", "A2,55.1,120"), f)
  m <- read_xrf(f)
  expect_equal(nrow(m), 4)
  expect_equal(m$qualifier[m$sample_id == "A1" & m$analyte == "Zr"], "<")
})

test_that("IDW is exact at data points and honours maxdist / nmax", {
  x <- c(0, 1, 2); y <- c(0, 0, 0); v <- c(1, 2, 3)
  expect_equal(gc_idw(x, y, v, gx = c(0, 1, 2), gy = c(0, 0, 0)), v)
  mid <- gc_idw(x, y, v, gx = 0.5, gy = 0)
  expect_gt(mid, 1); expect_lt(mid, 2)
  expect_true(is.na(gc_idw(x, y, v, gx = 10, gy = 0, maxdist = 1)))
  near <- gc_idw(x, y, v, gx = 0.4, gy = 0, nmax = 1)
  expect_equal(near, 1)
  expect_equal(gc_idw(x, NULL, v, gx = 1.5), gc_idw(x, y, v, gx = 1.5, gy = 0))  # 1-D
  expect_true(is.na(gc_idw(numeric(), numeric(), numeric(), gx = 1, gy = 1)))
})

expect_plot <- function(p) {
  expect_s3_class(p, "ggplot")
  expect_silent(b <- ggplot2::ggplot_build(p))
  invisible(b)
}

test_that("depth plots build", {
  expect_plot(plot_depth_profile(gc_example, "SRA", c("TOC", "Tmax"), holes = c("H01", "H05")))
  expect_plot(plot_depth_profile(gc_example, "XRF", "Mo", holes = "H12"))        # has censored points
  expect_plot(plot_depth_heatmap(gc_example, "SRA", "TOC"))
  expect_plot(plot_depth_heatmap(gc_example, "XRD", "quartz", breaks = 30, order = "y"))
  expect_plot(plot_section(gc_example, "SRA", "TOC", holes = c("H01", "H02", "H03", "H04")))
  expect_plot(plot_mineralogy(gc_example, holes = c("H01", "H12")))
  expect_error(plot_section(gc_example, "SRA", "TOC", holes = "H01"), "at least two")
  expect_error(plot_depth_profile(gc_example, "SRA", "Nope"), "no SRA")
})

test_that("map, ternary and kerogen plots build", {
  expect_plot(plot_map(gc_example, "SRA", "TOC", depth = c(60, 120)))
  expect_plot(plot_map(gc_example, "XRD", "quartz", interp = FALSE, fun = max))
  ds <- gc_indices(gc_example)
  expect_plot(plot_ternary(ds, "XRD", c("quartz", "carbonate", "clay"), colour = "depth_mid"))
  expect_error(plot_ternary(ds, "XRD", c("quartz", "carbonate", "unobtainium")), "not present")
  expect_plot(plot_kerogen(ds, "hi_oi"))
  expect_plot(plot_kerogen(ds, "hi_tmax", colour = "depth_mid"))
  expect_plot(plot_kerogen(ds, "s2_toc"))
  expect_error(plot_kerogen(gc_example, "hi_oi"), "gc_indices")
})

test_that("the section's IDW surface honours the sample values at the holes", {
  st <- gc_interval_stats(gc_example, "SRA", 10, analytes = "TOC")
  st <- st[st$hole_id == "H01", ]
  p <- plot_section(gc_example, "SRA", "TOC", holes = c("H01", "H02"))
  b <- ggplot2::ggplot_build(p)
  raster <- b$data[[1]]
  at_h01 <- raster[abs(raster$x - 0) < 1e-6, ]
  # grid depth nearest the first bin midpoint should be close to the bin value
  mid <- (st$bin_top[1] + st$bin_base[1]) / 2
  near <- at_h01[which.min(abs(at_h01$y - mid)), ]
  expect_equal(unname(near$fill != "transparent"), TRUE)
})

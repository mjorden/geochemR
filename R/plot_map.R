#' Planar map of one analyte
#'
#' Summarises each hole over a depth window ([gc_hole_summary()]) and draws
#' the holes as points coloured by the value, optionally over an IDW surface
#' with contours.
#'
#' @param ds A `gc_data` object.
#' @param method,analyte Which analyte.
#' @param depth Optional `c(top, base)` window; default: whole hole.
#' @param fun Summary function per hole (default `mean`; `max` for a
#'   "hottest sample" map).
#' @param interp Draw an IDW surface (`TRUE`) under the points.
#' @param n,power,nmax,maxdist Grid resolution and IDW controls.
#' @param contours Number of contour bins on the surface (0 for none).
#' @param label Label the points with the hole id.
#' @param palette Viridis option.
#' @return A ggplot with `coord_equal()`.
#' @examples
#' plot_map(gc_example, "SRA", "TOC", depth = c(60, 120))
#' plot_map(gc_example, "XRD", "quartz", interp = FALSE)
#' @export
plot_map <- function(ds, method, analyte, depth = NULL, fun = mean, interp = TRUE, n = 80, power = 2, nmax = 12,
                     maxdist = Inf, contours = 6, label = TRUE, palette = "viridis") {
  h <- gc_hole_summary(ds, method, depth, fun, analytes = analyte)
  h <- h[!is.na(h$x) & !is.na(h[[analyte]]), ]
  if (!nrow(h)) stop("no holes with coordinates and ", analyte, " values", call. = FALSE)
  p <- ggplot2::ggplot()
  if (interp && nrow(h) >= 3) {
    g <- .grid_over(h$x, h$y, n)
    g$v <- gc_idw(h$x, h$y, h[[analyte]], g$x, g$y, power = power, nmax = nmax, maxdist = maxdist)
    p <- p + ggplot2::geom_raster(data = g, ggplot2::aes(x = .data$x, y = .data$y, fill = .data$v), interpolate = TRUE, alpha = 0.85)
    if (contours > 0) p <- p + ggplot2::geom_contour(data = g, ggplot2::aes(x = .data$x, y = .data$y, z = .data$v), bins = contours, colour = "white", linewidth = 0.3, na.rm = TRUE)
  }
  p <- p + ggplot2::geom_point(data = h, ggplot2::aes(x = .data$x, y = .data$y, fill = .data[[analyte]]), shape = 21, size = 4, colour = "black")
  if (label) p <- p + ggplot2::geom_text(data = h, ggplot2::aes(x = .data$x, y = .data$y, label = .data$hole_id), vjust = -1.1, size = 3)
  sub <- if (!is.null(depth)) paste0(depth[1], "-", depth[2], " ", ds$meta$depth_unit, ", ", deparse(substitute(fun)), " per hole") else paste0("whole hole, ", deparse(substitute(fun)))
  p + ggplot2::scale_fill_viridis_c(option = palette, name = analyte, na.value = "transparent") +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "x", y = "y", subtitle = sub) +
    .theme_gc()
}

#' Ternary diagram
#'
#' Three parts of a composition (renormalised to 100 per sample) plotted in
#' barycentric coordinates — no extra package needed. Typical uses:
#' `c("quartz", "carbonate", "clay")` after [gc_indices()], or
#' `c("SiO2", "Al2O3", "CaO")`.
#'
#' @param ds A `gc_data` object.
#' @param method Method.
#' @param parts Three analyte names, in order bottom-left, top, bottom-right.
#' @param colour Column of the sample table (or `"hole_id"`, `"depth_mid"`)
#'   to colour by.
#' @param holes Optional subset.
#' @return A ggplot.
#' @examples
#' plot_ternary(gc_indices(gc_example), "XRD", c("quartz", "carbonate", "clay"), colour = "depth_mid")
#' @export
plot_ternary <- function(ds, method, parts, colour = "hole_id", holes = NULL) {
  stopifnot(length(parts) == 3)
  w <- gc_wide(ds, method, parts)
  if (!is.null(holes)) w <- w[w$hole_id %in% holes, ]
  miss <- setdiff(parts, names(w))
  if (length(miss)) stop("parts not present: ", paste(miss, collapse = ", "), call. = FALSE)
  a <- w[[parts[1]]]; b <- w[[parts[2]]]; c <- w[[parts[3]]]
  tot <- a + b + c
  a <- a / tot; b <- b / tot; c <- c / tot
  w$tx <- 0.5 * (2 * c + b) / (a + b + c)
  w$ty <- (sqrt(3) / 2) * b / (a + b + c)
  tri <- data.frame(x = c(0, 0.5, 1, 0), y = c(0, sqrt(3) / 2, 0, 0))
  grid <- do.call(rbind, lapply(seq(0.2, 0.8, 0.2), function(f) rbind(
    data.frame(x = c(f / 2, 1 - f / 2), y = c(f * sqrt(3) / 2, f * sqrt(3) / 2), g = paste0("a", f)),
    data.frame(x = c(f, f + (1 - f) / 2), y = c(0, (1 - f) * sqrt(3) / 2), g = paste0("b", f)),
    data.frame(x = c(1 - f, (1 - f) / 2), y = c(0, (1 - f) * sqrt(3) / 2), g = paste0("c", f)))))
  ggplot2::ggplot() +
    ggplot2::geom_path(data = grid, ggplot2::aes(x = .data$x, y = .data$y, group = .data$g), colour = "grey85", linewidth = 0.3) +
    ggplot2::geom_path(data = tri, ggplot2::aes(x = .data$x, y = .data$y), colour = "grey30") +
    ggplot2::geom_point(data = w, ggplot2::aes(x = .data$tx, y = .data$ty, colour = .data[[colour]]), size = 2, alpha = 0.85) +
    ggplot2::annotate("text", x = c(-0.03, 0.5, 1.03), y = c(-0.03, sqrt(3) / 2 + 0.04, -0.03), label = parts, fontface = "bold", size = 3.5) +
    ggplot2::coord_equal(xlim = c(-0.1, 1.1), ylim = c(-0.08, 0.95)) +
    ggplot2::theme_void() +
    ggplot2::theme(legend.position = "right") +
    ggplot2::labs(colour = colour)
}

#' Kerogen-type and maturity plots from pyrolysis
#'
#' `type = "hi_oi"` — pseudo-van Krevelen (HI vs OI) with the conventional
#' Type I / II / III trend lines; `type = "hi_tmax"` — HI vs Tmax with
#' maturity windows (immature < 435 °C, oil 435–470, gas > 470);
#' `type = "s2_toc"` — S2 vs TOC, whose slope is the HI of the sample set
#' (and whose intercept exposes a mineral-matrix effect). Needs
#' [gc_indices()] to have been run for HI / OI.
#'
#' @param ds A `gc_data` object.
#' @param type Which plot.
#' @param colour Column to colour by (`"hole_id"`, `"depth_mid"`, or a sample column).
#' @param holes Optional subset.
#' @return A ggplot.
#' @examples
#' ds <- gc_indices(gc_example)
#' plot_kerogen(ds, "hi_oi")
#' plot_kerogen(ds, "hi_tmax", colour = "depth_mid")
#' @export
plot_kerogen <- function(ds, type = c("hi_oi", "hi_tmax", "s2_toc"), colour = "hole_id", holes = NULL) {
  type <- match.arg(type)
  w <- gc_wide(ds, "SRA")
  if (!is.null(holes)) w <- w[w$hole_id %in% holes, ]
  need <- switch(type, hi_oi = c("HI", "OI"), hi_tmax = c("HI", "Tmax"), s2_toc = c("S2", "TOC"))
  miss <- setdiff(need, names(w))
  if (length(miss)) stop("missing ", paste(miss, collapse = ", "), if (any(miss %in% c("HI", "OI"))) " - run gc_indices() first", call. = FALSE)
  pts <- function(p) p + ggplot2::geom_point(data = w, ggplot2::aes(x = .data[[need[2]]], y = .data[[need[1]]], colour = .data[[colour]]), size = 2, alpha = 0.85) +
    .theme_gc() + ggplot2::theme(legend.position = "right")
  if (type == "hi_oi") {
    trend <- rbind(data.frame(t = "Type I", x = c(5, 10, 20, 30), y = c(900, 800, 600, 300)),
                   data.frame(t = "Type II", x = c(10, 30, 60, 100), y = c(600, 450, 250, 100)),
                   data.frame(t = "Type III", x = c(20, 60, 120, 200), y = c(200, 150, 100, 50)))
    p <- ggplot2::ggplot() + ggplot2::geom_path(data = trend, ggplot2::aes(x = .data$x, y = .data$y, group = .data$t), colour = "grey60", linetype = 2) +
      ggplot2::geom_text(data = trend[!duplicated(trend$t), ], ggplot2::aes(x = .data$x, y = .data$y, label = .data$t), colour = "grey40", hjust = -0.1, size = 3)
    return(pts(p) + ggplot2::labs(x = "OI [mg CO2/g TOC]", y = "HI [mg HC/g TOC]", title = "Pseudo-van Krevelen"))
  }
  if (type == "hi_tmax") {
    p <- ggplot2::ggplot() +
      ggplot2::annotate("rect", xmin = -Inf, xmax = 435, ymin = -Inf, ymax = Inf, fill = "grey95") +
      ggplot2::annotate("rect", xmin = 435, xmax = 470, ymin = -Inf, ymax = Inf, fill = "#fff3e0") +
      ggplot2::annotate("rect", xmin = 470, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "#ffe0e0") +
      ggplot2::annotate("text", x = c(425, 452, 480), y = Inf, label = c("immature", "oil window", "gas"), vjust = 1.5, size = 3, colour = "grey40")
    return(pts(p) + ggplot2::labs(x = "Tmax [degC]", y = "HI [mg HC/g TOC]", title = "HI vs Tmax"))
  }
  fit <- stats::lm(S2 ~ TOC, data = w)
  p <- ggplot2::ggplot() + ggplot2::geom_abline(intercept = stats::coef(fit)[1], slope = stats::coef(fit)[2], colour = "grey50", linetype = 2)
  pts(p) + ggplot2::labs(x = "TOC [wt%]", y = "S2 [mg HC/g]", title = sprintf("S2 vs TOC: slope = HI %.0f, intercept %.2f", 100 * stats::coef(fit)[2], stats::coef(fit)[1]))
}

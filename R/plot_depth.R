.theme_gc <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), strip.text = ggplot2::element_text(face = "bold"),
                   legend.position = "bottom")
}

.long_for_plot <- function(ds, method, analytes, holes = NULL) {
  m <- gc_measurements(ds, method)
  if (!is.null(analytes)) m <- m[m$analyte %in% analytes, ]
  if (!nrow(m)) stop("no ", method, " measurements", if (!is.null(analytes)) paste0(" for ", paste(analytes, collapse = ", ")), call. = FALSE)
  d <- dplyr::left_join(m, ds$samples, by = "sample_id")
  if (!is.null(holes)) d <- d[d$hole_id %in% holes, ]
  d$analyte <- factor(d$analyte, levels = unique(c(analytes %||% character(), unique(d$analyte))))
  d$censored <- !is.na(d$qualifier) & d$qualifier == "<"
  d
}

#' Depth profiles
#'
#' One panel per analyte, holes as colours, depth increasing downward.
#' Interval samples are drawn as vertical bars over their interval with a
#' point at the mid-depth; censored values are hollow.
#'
#' @param ds A `gc_data` object.
#' @param method Method (`"XRD"`, `"XRF"`, `"SRA"`).
#' @param analytes Analytes to plot (default: all for the method).
#' @param holes Optional subset of holes.
#' @param free_x Independent x scales per analyte (default `TRUE`).
#' @param connect Join a hole's samples with a line.
#' @return A ggplot.
#' @examples
#' plot_depth_profile(gc_example, "SRA", c("TOC", "Tmax"), holes = c("H01", "H05"))
#' @export
plot_depth_profile <- function(ds, method, analytes = NULL, holes = NULL, free_x = TRUE, connect = TRUE) {
  d <- .long_for_plot(ds, method, analytes, holes)
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$value, y = .data$depth_mid, colour = .data$hole_id, group = .data$hole_id)) +
    ggplot2::geom_linerange(ggplot2::aes(ymin = .data$depth_top, ymax = .data$depth_base), linewidth = 1.2, alpha = 0.5)
  if (connect) p <- p + ggplot2::geom_path(alpha = 0.6, linewidth = 0.4)
  p <- p + ggplot2::geom_point(ggplot2::aes(shape = .data$censored), size = 2) +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 1), labels = c("measured", "< LOD"), name = NULL) +
    ggplot2::scale_y_reverse() +
    ggplot2::facet_wrap(~ .data$analyte, scales = if (free_x) "free_x" else "fixed", nrow = 1) +
    ggplot2::labs(x = NULL, y = paste0("Depth [", ds$meta$depth_unit, "]"), colour = "Hole") +
    .theme_gc()
  if (length(unique(d$hole_id)) > 12) p <- p + ggplot2::guides(colour = "none")
  p
}

#' Hole-by-depth heatmap
#'
#' Holes across, depth down, tile colour = value of one analyte. Holes are
#' ordered by `x` (or by `order`) so lateral trends read left to right.
#'
#' @param ds A `gc_data` object.
#' @param method,analyte Which analyte.
#' @param breaks Depth-bin width (or vector of breaks) passed to
#'   [gc_interval_stats()]; `NULL` uses each sample's own interval.
#' @param order Hole order: `"x"`, `"y"`, or a character vector.
#' @param palette A viridis option name (`"viridis"`, `"magma"`, …).
#' @return A ggplot.
#' @examples
#' plot_depth_heatmap(gc_example, "SRA", "TOC")
#' @export
plot_depth_heatmap <- function(ds, method, analyte, breaks = NULL, order = "x", palette = "viridis") {
  if (is.null(breaks)) {
    d <- .long_for_plot(ds, method, analyte)
    d <- d[, c("hole_id", "x", "y", "depth_top", "depth_base", "value")]
    names(d)[4:5] <- c("bin_top", "bin_base")
    d$v <- d$value
  } else {
    d <- gc_interval_stats(ds, method, breaks, analytes = analyte)
    d$v <- d[[analyte]]
  }
  lev <- if (is.character(order) && length(order) > 1) order else {
    hs <- unique(d[, c("hole_id", "x", "y")])
    hs$hole_id[order(hs[[order]])]
  }
  d$hole_id <- factor(d$hole_id, levels = lev)
  d$mid <- (d$bin_top + d$bin_base) / 2
  d$h <- pmax(d$bin_base - d$bin_top, 0.5)
  ggplot2::ggplot(d, ggplot2::aes(x = .data$hole_id, y = .data$mid, fill = .data$v, height = .data$h)) +
    ggplot2::geom_tile(width = 0.9) +
    ggplot2::scale_y_reverse() +
    ggplot2::scale_fill_viridis_c(option = palette, name = analyte, na.value = "grey85") +
    ggplot2::labs(x = "Hole", y = paste0("Depth [", ds$meta$depth_unit, "]")) +
    .theme_gc() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

#' Interpolated cross-section along a line of holes
#'
#' Projects the holes onto a section line, bins samples by depth and
#' interpolates (IDW) onto a distance-depth grid. `holes` gives the order
#' along the line; distances are cumulative straight-line distances between
#' consecutive holes.
#'
#' @param ds A `gc_data` object.
#' @param method,analyte Which analyte.
#' @param holes Holes in order along the section (at least two).
#' @param breaks Depth-bin width for [gc_interval_stats()].
#' @param n_x,n_z Grid resolution.
#' @param power,maxdist,nmax IDW controls; `maxdist` is in the section's
#'   (distance, depth) units after `aspect` scaling.
#' @param aspect Depth units per distance unit used to make the IDW search
#'   isotropic (e.g. 0.05 when 1 ft of depth should count like 20 ft
#'   laterally).
#' @param palette Viridis option.
#' @return A ggplot with the hole positions marked along the top.
#' @examples
#' plot_section(gc_example, "SRA", "TOC", holes = c("H01", "H02", "H03", "H04"))
#' @export
plot_section <- function(ds, method, analyte, holes, breaks = 10, n_x = 120, n_z = 80, power = 2, maxdist = Inf, nmax = 12,
                         aspect = 0.05, palette = "viridis") {
  if (length(holes) < 2) stop("a section needs at least two holes", call. = FALSE)
  st <- gc_interval_stats(ds, method, breaks, analytes = analyte)
  st <- st[st$hole_id %in% holes, ]
  pos <- unique(st[, c("hole_id", "x", "y")])
  pos <- pos[match(holes, pos$hole_id), ]
  if (anyNA(pos$x)) stop("holes without coordinates: ", paste(holes[is.na(pos$x)], collapse = ", "), call. = FALSE)
  dist <- c(0, cumsum(sqrt(diff(pos$x)^2 + diff(pos$y)^2)))
  st$dist <- dist[match(st$hole_id, holes)]
  st$mid <- (st$bin_top + st$bin_base) / 2
  v <- st[[analyte]]
  gx <- seq(0, max(dist), length.out = n_x)
  gz <- seq(min(st$bin_top), max(st$bin_base), length.out = n_z)
  g <- expand.grid(dist = gx, depth = gz)
  # scale depth so the IDW search is roughly isotropic in "section" units
  g$v <- gc_idw(st$dist, st$mid / aspect, v, g$dist, g$depth / aspect, power = power, nmax = nmax, maxdist = maxdist)
  p <- ggplot2::ggplot(g, ggplot2::aes(x = .data$dist, y = .data$depth, fill = .data$v)) +
    ggplot2::geom_raster(interpolate = TRUE) +
    ggplot2::geom_point(data = st, ggplot2::aes(x = .data$dist, y = .data$mid, fill = .data[[analyte]]), shape = 21, size = 2, colour = "white") +
    ggplot2::geom_vline(xintercept = dist, colour = "grey30", linewidth = 0.3) +
    ggplot2::annotate("text", x = dist, y = min(gz), label = holes, vjust = -0.4, size = 3) +
    ggplot2::scale_y_reverse() +
    ggplot2::scale_fill_viridis_c(option = palette, name = analyte, na.value = "transparent") +
    ggplot2::labs(x = "Distance along section", y = paste0("Depth [", ds$meta$depth_unit, "]")) +
    .theme_gc()
  p
}

#' Stacked mineralogy bars
#'
#' XRD composition per sample as stacked bars, grouped by mineral group,
#' one facet per hole, ordered by depth.
#'
#' @param ds A `gc_data` object.
#' @param holes Optional subset.
#' @param exclude Analytes to leave out (defaults to totals and derived rows).
#' @return A ggplot.
#' @examples
#' plot_mineralogy(gc_example, holes = c("H01", "H12"))
#' @export
plot_mineralogy <- function(ds, holes = NULL, exclude = c("total_clay", "total", "carbonate", "clay", "QFM", "BI_min")) {
  d <- .long_for_plot(ds, "XRD", NULL, holes)
  d <- d[!d$analyte %in% exclude & !(d$lab %in% "derived"), ]
  d$group <- gc_mineral_group(as.character(d$analyte))
  d$group[is.na(d$group)] <- "other"
  d$analyte <- factor(as.character(d$analyte), levels = unique(as.character(d$analyte)[order(d$group)]))
  d$label <- factor(sprintf("%g", d$depth_mid), levels = sprintf("%g", sort(unique(d$depth_mid), decreasing = TRUE)))
  ggplot2::ggplot(d, ggplot2::aes(x = .data$value, y = .data$label, fill = .data$analyte)) +
    ggplot2::geom_col(width = 0.85) +
    ggplot2::facet_wrap(~ .data$hole_id, scales = "free_y") +
    ggplot2::labs(x = "wt%", y = paste0("Depth [", ds$meta$depth_unit, "]"), fill = "Mineral") +
    .theme_gc()
}

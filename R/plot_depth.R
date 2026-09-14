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

.depth_lab <- function(ds) paste0("Depth [", ds$meta$depth_unit, "]")

#' Depth profiles
#'
#' One panel per analyte, holes as colours, depth increasing downward.
#' Interval samples are drawn as a bar over their interval with a point at the
#' mid-depth; censored values are hollow. With `direct_labels` (the default
#' for two or three holes) each trace is named at its deepest sample and no
#' legend is drawn; a single hole needs no label at all, and more than three
#' get a legend.
#'
#' @param ds A `gc_data` object.
#' @param method Method (`"XRD"`, `"XRF"`, `"SRA"`, `"PAM"`).
#' @param analytes Analytes to plot (default: all for the method).
#' @param holes Optional subset of holes.
#' @param free_x Independent x scales per analyte (default `TRUE`).
#' @param connect Join a hole's samples with a line.
#' @param direct_labels Label traces at their deepest sample instead of a
#'   legend; `NULL` decides by the number of holes.
#' @return A ggplot.
#' @examples
#' plot_depth_profile(gc_example, "SRA", c("TOC", "Tmax"), holes = c("H01", "H05"))
#' plot_depth_profile(gc_cuttings, "SRA", c("TOC", "S2", "Tmax"))
#' @export
plot_depth_profile <- function(ds, method, analytes = NULL, holes = NULL, free_x = TRUE, connect = TRUE, direct_labels = NULL) {
  d <- .long_for_plot(ds, method, analytes, holes)
  n_holes <- length(unique(d$hole_id))
  direct <- direct_labels %||% (n_holes %in% 2:3)
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$value, y = .data$depth_mid, colour = .data$hole_id, group = .data$hole_id)) +
    ggplot2::geom_linerange(ggplot2::aes(ymin = .data$depth_top, ymax = .data$depth_base), linewidth = 1.1, alpha = 0.45)
  if (connect) p <- p + ggplot2::geom_path(alpha = 0.7, linewidth = 0.35)
  p <- p + ggplot2::geom_point(ggplot2::aes(shape = .data$censored), size = 1.7, fill = gc_hex[["parchment"]]) +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 21), labels = c("measured", "< LOD"), name = NULL, drop = FALSE) +
    scale_colour_gc(name = NULL) +
    ggplot2::scale_y_reverse() +
    ggplot2::facet_wrap(~ .data$analyte, scales = if (free_x) "free_x" else "fixed", nrow = 1) +
    ggplot2::labs(x = NULL, y = .depth_lab(ds)) +
    theme_gc()
  if (direct) {
    last <- d[order(d$hole_id, d$depth_mid), ]
    last <- last[!duplicated(last[, c("hole_id", "analyte")], fromLast = TRUE), ]
    p <- p + ggplot2::geom_text(data = last, ggplot2::aes(label = .data$hole_id), family = "serif", size = 2.8, vjust = 1.6, show.legend = FALSE) +
      ggplot2::guides(colour = "none")
  } else if (n_holes == 1) {
    p <- p + ggplot2::guides(colour = "none") + ggplot2::labs(subtitle = unique(d$hole_id))
  }
  if (!any(d$censored)) p <- p + ggplot2::guides(shape = "none")
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
#' @param palette A sequential palette name for [gc_pal()] (default `"scholar"`).
#' @return A ggplot.
#' @examples
#' plot_depth_heatmap(gc_example, "SRA", "TOC")
#' @export
plot_depth_heatmap <- function(ds, method, analyte, breaks = NULL, order = "x", palette = "scholar") {
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
    ggplot2::geom_tile(width = 0.88) +
    ggplot2::scale_y_reverse() +
    scale_fill_gc_c(palette, name = analyte, na.value = gc_hex[["parchment_grid"]]) +
    ggplot2::labs(x = NULL, y = .depth_lab(ds)) +
    theme_gc(axis = "y", legend_position = "right") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1), axis.ticks.x = ggplot2::element_blank())
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
#' @param palette Sequential palette for [gc_pal()] (default `"scholar"`).
#' @return A ggplot with the hole positions marked along the top.
#' @examples
#' plot_section(gc_example, "SRA", "TOC", holes = c("H01", "H02", "H03", "H04"))
#' @export
plot_section <- function(ds, method, analyte, holes, breaks = 10, n_x = 120, n_z = 80, power = 2, maxdist = Inf, nmax = 12,
                         aspect = 0.05, palette = "scholar") {
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
  g$v <- gc_idw(st$dist, st$mid / aspect, v, g$dist, g$depth / aspect, power = power, nmax = nmax, maxdist = maxdist)
  ggplot2::ggplot(g, ggplot2::aes(x = .data$dist, y = .data$depth, fill = .data$v)) +
    ggplot2::geom_raster(interpolate = TRUE) +
    ggplot2::geom_point(data = st, ggplot2::aes(x = .data$dist, y = .data$mid, fill = .data[[analyte]]), shape = 21, size = 1.8, colour = gc_hex[["parchment"]], stroke = 0.4) +
    ggplot2::geom_vline(xintercept = dist, colour = gc_hex[["ink"]], linewidth = 0.25, alpha = 0.6) +
    ggplot2::annotate("text", x = dist, y = min(gz), label = holes, vjust = -0.5, size = 3, family = "serif", colour = gc_hex[["ink"]],
                      hjust = c(0, rep(0.5, max(length(holes) - 2, 0)), 1)[seq_along(holes)]) +
    ggplot2::scale_y_reverse(expand = ggplot2::expansion(mult = c(0, 0.06))) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(0)) +
    scale_fill_gc_c(palette, name = analyte, na.value = "transparent") +
    ggplot2::labs(x = "Distance along section", y = .depth_lab(ds)) +
    theme_gc(legend_position = "right")
}

#' Stacked composition against depth
#'
#' Horizontal stacked bars, one per sample interval, for a set of analytes that
#' add up to something meaningful: XRD minerals ([plot_mineralogy()]) or the
#' PAM pyrolysis fractions ([plot_pam()]). One facet per hole.
#'
#' @param ds A `gc_data` object.
#' @param method Method.
#' @param analytes Analytes to stack, bottom to top of the legend.
#' @param holes Optional subset.
#' @param normalize Rescale each sample to 100 %.
#' @param xlab x-axis label.
#' @param fill_scale A ggplot2 fill scale to use instead of [scale_fill_gc()]
#'   (e.g. [scale_fill_minerals()]).
#' @return A ggplot.
#' @export
plot_stacked_depth <- function(ds, method, analytes, holes = NULL, normalize = FALSE, xlab = NULL, fill_scale = NULL) {
  d <- .long_for_plot(ds, method, analytes, holes)
  d <- d[d$origin != "derived", ]
  if (normalize) {
    tot <- tapply(d$value, d$sample_id, sum, na.rm = TRUE)
    d$value <- 100 * d$value / tot[d$sample_id]
  }
  d$analyte <- factor(as.character(d$analyte), levels = analytes)
  d <- d[!is.na(d$value), ]
  d <- d[order(d$sample_id, as.integer(d$analyte)), ]
  d$xmax <- stats::ave(d$value, d$sample_id, FUN = cumsum)      # explicit stacking: cumulative extent per sample
  d$xmin <- d$xmax - d$value
  d$ymin <- ifelse(d$depth_base > d$depth_top, d$depth_top, d$depth_mid - 0.25)
  d$ymax <- ifelse(d$depth_base > d$depth_top, d$depth_base, d$depth_mid + 0.25)
  ggplot2::ggplot(d) +
    ggplot2::geom_rect(ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax, ymin = .data$ymin, ymax = .data$ymax, fill = .data$analyte),
                       colour = gc_hex[["parchment"]], linewidth = 0.15) +
    ggplot2::scale_y_reverse(expand = ggplot2::expansion(0)) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.02))) +
    (fill_scale %||% scale_fill_gc(name = NULL)) +
    ggplot2::facet_wrap(~ .data$hole_id, scales = "free_y") +
    ggplot2::labs(x = xlab %||% if (normalize) "%" else NULL, y = .depth_lab(ds)) +
    theme_gc(axis = "y")
}

#' Stacked mineralogy bars
#'
#' XRD composition per sample interval as stacked bars, minerals grouped
#' (tectosilicates, carbonates, clays, sulfides, other), one facet per hole.
#'
#' @param ds A `gc_data` object.
#' @param holes Optional subset.
#' @param exclude Analytes to leave out (totals and derived sums by default).
#' @return A ggplot.
#' @examples
#' plot_mineralogy(gc_example, holes = c("H01", "H12"))
#' plot_mineralogy(gc_cuttings)
#' @export
plot_mineralogy <- function(ds, holes = NULL, exclude = c("total_clay", "total", "carbonate", "clay", "QFM", "BI", "BI_min", "BI_w")) {
  an <- setdiff(gc_analytes(ds, "XRD")$XRD, exclude)
  grp <- gc_mineral_group(an)
  grp[is.na(grp)] <- "other"
  order <- c("tectosilicate", "carbonate", "sulfide", "other", "clay")
  an <- an[order(match(grp, order), an)]
  plot_stacked_depth(ds, "XRD", an, holes = holes, xlab = "wt%", fill_scale = scale_fill_minerals(an, name = NULL))
}

#' PAM pyrolysis log
#'
#' The multi-ramp pyrolysis fractions (`Oil1` ... `Oil4`, `K1`) stacked against
#' depth: light hydrocarbons at the base of each bar, kerogen on top.
#'
#' @inheritParams plot_mineralogy
#' @param fractions Which fractions, in stacking order.
#' @param normalize Show each sample as % of its total rather than mg HC/g.
#' @return A ggplot.
#' @examples
#' plot_pam(gc_cuttings)
#' @export
plot_pam <- function(ds, holes = NULL, fractions = c("Oil1", "Oil2", "Oil3", "Oil4", "K1"), normalize = FALSE) {
  plot_stacked_depth(ds, "PAM", fractions, holes = holes, normalize = normalize, xlab = if (normalize) "% of total" else "mg HC/g")
}

#' The geochemR look: academic parchment, Tufte restraint
#'
#' Every plot in the package is drawn with [theme_gc()] and the `scale_*_gc()`
#' scales. The palette is a sibling of the *academic* style in
#' [econscape](https://github.com/mjorden/econscape): parchment surfaces,
#' brown ink, a tan-to-espresso categorical palette, a rust accent, serif
#' type. The furniture follows Tufte rather than a newspaper: no panel fill
#' behind the data (the parchment is the page, not the chart), no gridlines
#' unless asked for, hairline axes with outward ticks, muted axis titles, a
#' legend that reads as a row of labels - or, on depth profiles, no legend at
#' all and the hole names written at the bottom of each trace.
#'
#' @section Colours:
#' `gc_colours()` returns the dictionary. Categorical: `espresso`, `tan`,
#' `sand`, `walnut`, `parchment_dark`, `bark`, `stone`, then `rust`, `moss`,
#' `slate`, `ochre` for more than seven groups. Surfaces: `parchment`,
#' `parchment_grid`; ink: `ink`, `muted`; accent: `rust`; maturity windows:
#' `window_immature`, `window_oil`, `window_gas`.
#'
#' @param base_size Base font size in points.
#' @param base_family Font family; `"serif"` by default.
#' @param grid Major gridlines: `"none"` (default), `"y"`, `"x"` or `"both"`.
#'   When drawn they are hairlines in the parchment grid colour.
#' @param axis Which axis lines to draw: `"both"` (default), `"x"`, `"y"` or
#'   `"none"`.
#' @param legend_position Passed to [ggplot2::theme()]; `"top"` by default.
#' @param panel `"page"` (default: transparent panel on a parchment page) or
#'   `"parchment"` (panel filled too, closer to econscape).
#' @return A ggplot2 theme.
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
#'   geom_point(size = 2) +
#'   scale_colour_gc() +
#'   labs(title = "Weight and economy", subtitle = "mtcars, 1974", colour = "Cylinders") +
#'   theme_gc()
#' @export
theme_gc <- function(base_size = 11, base_family = "serif", grid = c("none", "y", "x", "both"),
                     axis = c("both", "x", "y", "none"), legend_position = "top", panel = c("page", "parchment")) {
  grid <- match.arg(grid)
  axis <- match.arg(axis)
  panel <- match.arg(panel)
  h <- gc_hex
  half <- base_size / 2
  blank <- ggplot2::element_blank()
  gridline <- ggplot2::element_line(colour = h[["parchment_grid"]], linewidth = 0.3)
  axisline <- ggplot2::element_line(colour = h[["ink"]], linewidth = 0.35)
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = h[["parchment"]], colour = NA),
      panel.background = ggplot2::element_rect(fill = if (panel == "parchment") h[["parchment"]] else NA, colour = NA),
      panel.border = blank,
      legend.background = ggplot2::element_rect(fill = h[["parchment"]], colour = NA),
      legend.key = ggplot2::element_rect(fill = NA, colour = NA),
      strip.background = blank,
      panel.grid.major.x = if (grid %in% c("x", "both")) gridline else blank,
      panel.grid.major.y = if (grid %in% c("y", "both")) gridline else blank,
      panel.grid.minor = blank,
      axis.line.x = if (axis %in% c("x", "both")) axisline else blank,
      axis.line.y = if (axis %in% c("y", "both")) axisline else blank,
      axis.ticks = axisline,
      axis.ticks.length = grid::unit(base_size / 4, "pt"),
      axis.text = ggplot2::element_text(colour = h[["ink"]], size = ggplot2::rel(0.85)),
      axis.title = ggplot2::element_text(colour = h[["muted"]], size = ggplot2::rel(0.9)),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = half)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = half)),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title = ggplot2::element_text(colour = h[["ink"]], face = "bold", size = ggplot2::rel(1.25), hjust = 0, margin = ggplot2::margin(b = half * 0.6)),
      plot.subtitle = ggplot2::element_text(colour = h[["muted"]], size = ggplot2::rel(0.95), hjust = 0, margin = ggplot2::margin(b = base_size)),
      plot.caption = ggplot2::element_text(colour = h[["muted"]], size = ggplot2::rel(0.75), hjust = 0, margin = ggplot2::margin(t = base_size)),
      plot.margin = ggplot2::margin(half, base_size, half, base_size),
      legend.position = legend_position,
      legend.justification = "left",
      legend.direction = if (legend_position %in% c("top", "bottom")) "horizontal" else "vertical",
      legend.title = ggplot2::element_text(colour = h[["muted"]], size = ggplot2::rel(0.85)),
      legend.text = ggplot2::element_text(colour = h[["ink"]], size = ggplot2::rel(0.85)),
      legend.key.height = grid::unit(base_size, "pt"),
      legend.margin = ggplot2::margin(b = half),
      strip.text = ggplot2::element_text(colour = h[["ink"]], face = "bold", size = ggplot2::rel(0.95), hjust = 0, margin = ggplot2::margin(b = half * 0.5))
    )
}

gc_hex <- c(
  espresso = "#5C4033", tan = "#A47551", sand = "#C9A87C", walnut = "#7B5E3B", parchment_dark = "#D8C3A5",
  bark = "#3E2F23", stone = "#9C8B7A", rust = "#8B3A2F", moss = "#6B7A5A", slate = "#5A6E78", ochre = "#B9946A",
  parchment = "#F4EEE2", parchment_grid = "#E3D9C6", ink = "#2E2622", muted = "#7A6B5D",
  window_immature = "#EFE6D6", window_oil = "#E8D2B8", window_gas = "#E2C2B7"
)

#' @rdname theme_gc
#' @param ... For `gc_colours()`: colour names; none returns the dictionary.
#' @export
gc_colours <- function(...) {
  nm <- c(...)
  if (!length(nm)) return(gc_hex)
  bad <- setdiff(nm, names(gc_hex))
  if (length(bad)) stop("unknown colour(s): ", paste(bad, collapse = ", "), call. = FALSE)
  gc_hex[nm]
}

gc_palettes <- list(
  academic = unname(gc_hex[c("espresso", "tan", "sand", "walnut", "parchment_dark", "bark", "stone", "rust", "moss", "slate", "ochre")]),
  browns = c("#EAD9BF", "#D3B58C", "#B98F62", "#95693F", "#6E4A2E", "#4A3222", "#2E2622"),
  rust = c("#F0E1D8", "#DDB5A6", "#C7877A", "#A95A4B", "#8B3A2F", "#5E2620"),
  moss = c("#E4E8DC", "#C1CBB1", "#9CAB85", "#7A8B62", "#5B6D45", "#3D4B2E")
)

#' @rdname theme_gc
#' @param palette `"academic"` (categorical, 11 colours), or a sequential
#'   ramp: `"browns"` (default for continuous scales), `"rust"`, `"moss"`.
#' @param reverse Reverse the palette.
#' @return `gc_pal()` returns a function of `n`; categorical palettes
#'   interpolate beyond their length rather than error.
#' @export
gc_pal <- function(palette = "academic", reverse = FALSE) {
  palette <- match.arg(palette, names(gc_palettes))
  cols <- gc_palettes[[palette]]
  if (reverse) cols <- rev(cols)
  function(n) {
    if (palette == "academic" && n <= length(cols)) return(cols[seq_len(n)])
    grDevices::colorRampPalette(cols)(n)
  }
}

#' @rdname theme_gc
#' @export
scale_colour_gc <- function(palette = "academic", reverse = FALSE, ...) {
  ggplot2::discrete_scale("colour", palette = gc_pal(palette, reverse), ...)
}

#' @rdname theme_gc
#' @export
scale_fill_gc <- function(palette = "academic", reverse = FALSE, ...) {
  ggplot2::discrete_scale("fill", palette = gc_pal(palette, reverse), ...)
}

#' @rdname theme_gc
#' @export
scale_colour_gc_c <- function(palette = "browns", reverse = FALSE, ...) {
  ggplot2::scale_colour_gradientn(colours = gc_pal(palette, reverse)(256), ...)
}

#' @rdname theme_gc
#' @export
scale_fill_gc_c <- function(palette = "browns", reverse = FALSE, ...) {
  ggplot2::scale_fill_gradientn(colours = gc_pal(palette, reverse)(256), ...)
}

#' @rdname theme_gc
#' @export
scale_color_gc <- scale_colour_gc

#' @rdname theme_gc
#' @export
scale_color_gc_c <- scale_colour_gc_c

# internal: keep the old name used across plot files
.theme_gc <- function(...) theme_gc(...)

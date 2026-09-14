#' The geochemR look: academic parchment, Tufte restraint, colour where it counts
#'
#' Every plot in the package is drawn with [theme_gc()] and the `scale_*_gc()`
#' scales. The furniture is a sibling of the *academic* style in
#' [econscape](https://github.com/mjorden/econscape): parchment surfaces,
#' brown ink, serif type. It follows Tufte rather than a newspaper: no panel
#' fill behind the data (the parchment is the page, not the chart), no
#' gridlines unless asked for, hairline axes with outward ticks, muted axis
#' titles, a legend that reads as a row of labels - or, on depth profiles of
#' two or three holes, no legend at all and the hole names written at the
#' bottom of each trace. The furniture being monochrome is what lets the data
#' carry colour: the categorical palette rotates through distinct hues muted
#' to sit on parchment, and continuous scales use a multi-hue ramp so that
#' both level and gradient read.
#'
#' @section Colours:
#' `gc_colours()` returns the dictionary. Categorical hues: `espresso`,
#' `rust`, `slate`, `moss`, `ochre`, `plum`, `teal`, `tan`, `indigo`, `brick`,
#' `sage`. Surfaces: `parchment`, `parchment_grid`; ink: `ink`, `muted`;
#' maturity windows: `window_immature`, `window_oil`, `window_gas`.
#' `gc_mineral_colours` colours XRD minerals by kind.
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
  # categorical: distinct hues, each muted enough to sit on parchment
  espresso = "#5C4033", rust = "#A23E2E", slate = "#3F6E8C", moss = "#5F7F3F", ochre = "#D29A2B", plum = "#7A4F7D",
  teal = "#2F8F86", tan = "#B9946A", indigo = "#4B4A8A", brick = "#C86A4A", sage = "#8FA37A",
  # browns kept for sequential work
  sand = "#C9A87C", walnut = "#7B5E3B", parchment_dark = "#D8C3A5", bark = "#3E2F23", stone = "#9C8B7A",
  parchment = "#F4EEE2", parchment_grid = "#E3D9C6", ink = "#2E2622", muted = "#7A6B5D",
  window_immature = "#EFE6D6", window_oil = "#E8D2B8", window_gas = "#E2C2B7"
)

#' @rdname theme_gc
#' @param ... For `gc_colours()`: colour names; none returns the dictionary.
#'   For the scales: passed to the ggplot2 scale.
#' @export
gc_colours <- function(...) {
  nm <- c(...)
  if (!length(nm)) return(gc_hex)
  bad <- setdiff(nm, names(gc_hex))
  if (length(bad)) stop("unknown colour(s): ", paste(bad, collapse = ", "), call. = FALSE)
  gc_hex[nm]
}

gc_palettes <- list(
  # categorical, ordered for maximum separation between neighbours
  academic = unname(gc_hex[c("espresso", "rust", "slate", "moss", "ochre", "plum", "teal", "tan", "indigo", "brick", "sage")]),
  # sequential, multi-hue: sand through ochre and rust to plum and ink -
  # luminance falls monotonically while the hue rotates, so level and gradient both read
  scholar = c("#EAD9BF", "#DDB86A", "#D29A2B", "#B65E2A", "#A23E2E", "#7A3A55", "#4B2F4E", "#2E2622"),
  # sequential, cool: sand through sage and teal to slate and indigo
  tide = c("#EAD9BF", "#B9C99A", "#7FAE8C", "#3F8F86", "#3F6E8C", "#3C4F7A", "#2E2A4A"),
  # single-hue ramps
  browns = c("#EAD9BF", "#D3B58C", "#B98F62", "#95693F", "#6E4A2E", "#4A3222", "#2E2622"),
  rust = c("#F0E1D8", "#DDB5A6", "#C7877A", "#A95A4B", "#8B3A2F", "#5E2620"),
  moss = c("#E4E8DC", "#C1CBB1", "#9CAB85", "#7A8B62", "#5B6D45", "#3D4B2E"),
  # diverging: slate - parchment - rust, for anomalies about a centre
  divergent = c("#3F6E8C", "#8FB0C4", "#D6DCE0", "#F4EEE2", "#E8C9B8", "#C9806E", "#A23E2E")
)

#' @rdname theme_gc
#' @format `gc_mineral_colours`: fill colours for XRD minerals keyed by
#'   canonical name, grouped by kind so a stacked bar reads at a glance -
#'   tectosilicates in warm yellows and tans, carbonates in blues, clays in
#'   greens, sulfides dark, everything else grey or violet.
#' @export
gc_mineral_colours <- c(
  quartz = "#E3C46E", k_feldspar = "#D29A2B", plagioclase = "#B9946A", amorphous = "#EAD9BF",
  calcite = "#3F6E8C", dolomite = "#7FA6C0", ankerite = "#5A88A6", siderite = "#2E4A66", aragonite = "#A9C4D6",
  illite = "#5F7F3F", smectite = "#8FA37A", mixed_layer = "#3E6B4A", kaolinite = "#B7C79B", chlorite = "#2F6F5E", glauconite = "#6F8F5A", total_clay = "#5F7F3F",
  pyrite = "#2E2622", marcasite = "#4A3A3A",
  apatite = "#7A4F7D", anhydrite = "#C9BFC8", gypsum = "#DDD3DC", halite = "#EDE7EE", barite = "#9C8B7A", hematite = "#A23E2E", goethite = "#C86A4A", other = "#B5ADA4"
)

#' @rdname theme_gc
#' @param palette `"academic"` (categorical: espresso, rust, slate, moss,
#'   ochre, plum, teal, tan, indigo, brick, sage); sequential ramps
#'   `"scholar"` (default for continuous scales: sand through ochre and rust
#'   to plum and ink), `"tide"` (sand through sage and teal to indigo),
#'   `"browns"`, `"rust"`, `"moss"`; or `"divergent"` (slate - parchment - rust).
#' @param reverse Reverse the palette.
#' @return `gc_pal()` returns a function of `n`; the categorical palette
#'   interpolates beyond its length rather than error.
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
scale_colour_gc_c <- function(palette = "scholar", reverse = FALSE, ...) {
  ggplot2::scale_colour_gradientn(colours = gc_pal(palette, reverse)(256), ...)
}

#' @rdname theme_gc
#' @export
scale_fill_gc_c <- function(palette = "scholar", reverse = FALSE, ...) {
  ggplot2::scale_fill_gradientn(colours = gc_pal(palette, reverse)(256), ...)
}

#' @rdname theme_gc
#' @param minerals Mineral names present in the data; any not in
#'   `gc_mineral_colours` get colours from the categorical palette.
#' @return `scale_fill_minerals()` is a manual fill scale keyed by canonical
#'   mineral name.
#' @export
scale_fill_minerals <- function(minerals = NULL, ...) {
  vals <- gc_mineral_colours
  if (!is.null(minerals)) {
    extra <- setdiff(minerals, names(vals))
    if (length(extra)) vals <- c(vals, stats::setNames(gc_pal("academic")(length(extra)), extra))
  }
  ggplot2::scale_fill_manual(values = vals, na.value = gc_hex[["stone"]], ...)
}

#' @rdname theme_gc
#' @export
scale_color_gc <- scale_colour_gc

#' @rdname theme_gc
#' @export
scale_color_gc_c <- scale_colour_gc_c

# internal: keep the old name used across plot files
.theme_gc <- function(...) theme_gc(...)

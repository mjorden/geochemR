#' Inverse-distance-weighted interpolation to a grid
#'
#' Plain IDW in one or two dimensions with an optional search radius and
#' neighbour cap; used by [plot_map()] and [plot_section()]. Exact at data
#' points.
#'
#' @param x,y,v Coordinates and values of the data points (`y` may be `NULL`
#'   for a 1-D problem).
#' @param gx,gy Grid coordinates to predict at (`gy` `NULL` for 1-D).
#' @param power Distance exponent (2 = classic IDW).
#' @param nmax Use only the `nmax` nearest points.
#' @param maxdist Ignore points farther than this; grid cells with no point
#'   inside `maxdist` get `NA`.
#' @return A numeric vector of predictions, one per grid point.
#' @examples
#' gc_idw(c(0, 1, 2), c(0, 0, 0), c(1, 2, 3), gx = 0.5, gy = 0)
#' @export
gc_idw <- function(x, y = NULL, v, gx, gy = NULL, power = 2, nmax = Inf, maxdist = Inf) {
  ok <- is.finite(x) & is.finite(v) & (is.null(y) | is.finite(y %||% x))
  x <- x[ok]; v <- v[ok]; if (!is.null(y)) y <- y[ok]
  if (!length(v)) return(rep(NA_real_, length(gx)))
  vapply(seq_along(gx), function(i) {
    d <- if (is.null(y)) abs(x - gx[i]) else sqrt((x - gx[i])^2 + (y - gy[i])^2)
    if (any(d == 0)) return(mean(v[d == 0]))
    keep <- d <= maxdist
    if (!any(keep)) return(NA_real_)
    d <- d[keep]; vv <- v[keep]
    if (is.finite(nmax) && length(d) > nmax) {
      o <- order(d)[seq_len(nmax)]
      d <- d[o]; vv <- vv[o]
    }
    w <- 1 / d^power
    sum(w * vv) / sum(w)
  }, numeric(1))
}

#' Regular grid over a set of points
#'
#' @param x,y Point coordinates.
#' @param n Cells along the longer axis.
#' @param expand Fraction of the range to pad on each side.
#' @return A data frame of grid `x`, `y`.
#' @keywords internal
.grid_over <- function(x, y, n = 80, expand = 0.05) {
  rx <- range(x, na.rm = TRUE); ry <- range(y, na.rm = TRUE)
  px <- diff(rx) * expand; py <- diff(ry) * expand
  rx <- rx + c(-px, px); ry <- ry + c(-py, py)
  step <- max(diff(rx), diff(ry)) / n
  gx <- seq(rx[1], rx[2], by = step); gy <- seq(ry[1], ry[2], by = step)
  expand.grid(x = gx, y = gy)
}

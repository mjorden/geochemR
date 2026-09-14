#' geochemR: import, process and map geochemical data
#'
#' Sample-based geochemistry — XRD mineralogy, XRF element / oxide chemistry
#' and source-rock analyzer (Rock-Eval) pyrolysis — kept in one tidy data
#' model ([gc_data()]), read from laboratory spreadsheets ([read_xrd()],
#' [read_xrf()], [read_sra()]), processed ([gc_substitute_lod()],
#' [gc_convert_units()], [gc_oxide_to_element()], [gc_renormalize()],
#' [gc_clr()], [gc_indices()]) and plotted against depth
#' ([plot_depth_profile()], [plot_depth_heatmap()], [plot_section()]) and on
#' the map ([plot_map()]), plus [plot_ternary()] and [plot_kerogen()].
#'
#' @keywords internal
#' @importFrom rlang .data
#' @importFrom stats setNames weighted.mean median quantile sd
"_PACKAGE"

utils::globalVariables(c("."))

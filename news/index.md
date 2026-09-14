# Changelog

## geochemR 0.2.1

- **Colour separation.** The furniture stays monochrome; the data no
  longer is. The categorical palette rotates through eleven distinct
  hues muted for parchment (espresso, rust, slate, moss, ochre, plum,
  teal, tan, indigo, brick, sage); continuous scales default to the
  multi-hue `"scholar"` ramp (sand through ochre and rust to plum and
  ink, luminance falling monotonically), with `"tide"` (cool) and
  `"divergent"` (slate-parchment- rust) alongside the single-hue ramps;
  `gc_mineral_colours` /
  [`scale_fill_minerals()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  colour XRD minerals by kind (silicates warm, carbonates blue, clays
  green, sulfides dark) so stacked mineralogy reads at a glance.
  `plot_stacked_depth(fill_scale = )`.

## geochemR 0.2.0

- **Laboratory workbook reader.**
  [`read_workbook()`](https://mjorden.github.io/geochemR/reference/read_workbook.md)
  reads the multi-method cuttings-analysis deliverable layout — a group
  / analyte / unit header block, a QC row, then one sample per row with
  bottom depths and formation / zone labels — into a `gc_data` object in
  one call. Groups map to methods (TOC + pyrolysis → SRA, PAM → PAM, XRD
  bulk + clay speciation → XRD, XRF elements → XRF); lab-calculated
  columns are dropped by default so
  [`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
  stays the single source of derived values; clay speciation reported
  relative to total clay is converted to bulk wt% (auto-detected).
- **PAM pyrolysis** is a method: `Oil1` … `Oil4`, `K1` and their `Tmax`;
  [`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
  adds `Oil_total`, `Oil_TOC` and the fraction ratios;
  [`plot_pam()`](https://mjorden.github.io/geochemR/reference/plot_pam.md)
  draws the stacked pyrolysis log. `gc_pam_analytes`.
- `formation` and `zone` on the sample table; `gc_hole_summary(by = )`
  for stratigraphic summaries.
- [`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md):
  weighted brittleness `BI_w`; `min_toc` cutoff for HI / OI / S1/TOC on
  lean samples.
- **The look.**
  [`theme_gc()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  and the `scale_*_gc()` scales replace the default ggplot2 styling: a
  parchment page, brown ink, tan-to-espresso palette and serif type in
  the manner of econscape’s academic style, with Tufte’s restraint — no
  panel fill or gridlines, hairline axes, muted titles, direct labels on
  depth profiles where they fit.
  [`gc_colours()`](https://mjorden.github.io/geochemR/reference/theme_gc.md),
  [`gc_pal()`](https://mjorden.github.io/geochemR/reference/theme_gc.md).
- [`plot_stacked_depth()`](https://mjorden.github.io/geochemR/reference/plot_stacked_depth.md)
  (generic stacked-bar-by-depth;
  [`plot_mineralogy()`](https://mjorden.github.io/geochemR/reference/plot_mineralogy.md)
  now uses it).
- Second example dataset `gc_cuttings` — one well, 65 cuttings samples,
  all methods — shipped both as data and as the Excel workbook it was
  read from (`inst/extdata/cuttings_workbook.xlsx`).

## geochemR 0.1.0

First release.

- `gc_data` model: a sample table plus one long measurement table for
  XRD, XRF and SRA / Rock-Eval pyrolysis, with detection limits and
  qualifiers; validation on construction.
- Readers for wide laboratory tables
  ([`read_xrd()`](https://mjorden.github.io/geochemR/reference/read_geochem.md),
  [`read_xrf()`](https://mjorden.github.io/geochemR/reference/read_geochem.md),
  [`read_sra()`](https://mjorden.github.io/geochemR/reference/read_geochem.md),
  [`read_samples()`](https://mjorden.github.io/geochemR/reference/read_samples.md)):
  mineral-name aliases, unit suffixes, censored (`<5`) and blank values.
- Processing: LOD substitution, unit conversion, oxide/element
  conversion, renormalisation, centred and additive log-ratios, interval
  and per-hole summaries.
- [`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md):
  HI, OI, PI, S1/TOC, Ro-equivalent; CIA and element ratios; carbonate,
  clay, QFM and mineralogical brittleness.
- Plots: depth profiles, hole-by-depth heatmap, IDW cross-section,
  stacked mineralogy, planar map with IDW surface, ternary, kerogen-type
  plots.
- Synthetic `gc_example` dataset (12 holes, three units, all three
  methods).

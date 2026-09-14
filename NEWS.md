# geochemR 0.3.0

Schema and provenance (adversarial review, phase 2). Objects saved by 0.2.x
are upgraded in place the first time a function touches them.

* **`origin` column** on measurements: `"measured"`, `"reported"` (a value
  the laboratory calculated) or `"derived"` (computed by `gc_indices()`).
  `lab` is once again only the laboratory - the `"derived"` / `"reported"`
  sentinels are gone, and a lab called "Derived" is a lab (#8).
* `gc_indices(which = )` recomputes only the methods asked for; it used to
  delete every method's derived rows first (#8).
* `gc_wide()` no longer averages duplicate keys behind your back (#3). Rows
  of different origin are resolved by `prefer` (default measured >
  reported > derived) with a message; rows of the same origin from two
  labs are an error unless `fun` says how to combine them; an analyte in
  two units is an error. `validate_gc()` warns about multi-lab keys at
  construction.
* `gc_renormalize()` rescales measured rows only, closes a sample whose
  clay is reported only as `total_clay` to `total - total_clay`, and warns
  when a sample is more than `tolerance` away from `total` before
  rescaling (#4).
* **Provenance** (#14): `meta$sources` is a table of input files with MD5,
  size and modification time (readers fill the `source` column with the
  path and `gc_data()` hashes it; `read_workbook()` records path and
  sheet); `meta$schema_version`, `package_version`, `created`; and
  `meta$history` - every constructor, reader and processing step with its
  arguments and time, read with `gc_history()` and summarised by `print()`.
  `gc_bind()` merges sources and histories.
* `grDevices`, `grid` and `tools` declared in Imports.

# geochemR 0.2.2

Bug fixes from the adversarial review: four ways the package produced wrong
numbers without saying so.

* `gc_example` now has XRD on all 180 samples (#1). The generator clamped a
  data frame with `pmax()`, which injected `NA`, so 69 samples (most of the
  limestone) had no mineralogy and every XRD figure was drawn on a biased
  subset. Data, figures and the counts in the README are regenerated; a
  test asserts every sample has every method.
* Readers take `decimal_mark` / `grouping_mark` (#2). `.parse_values()` used
  to strip every comma, so a decimal-comma sheet read `"2,5"` as 25; it also
  failed on `"1 250"`. `read_xrd()`, `read_xrf()`, `read_sra()`,
  `read_geochem()`, `read_samples()` and `read_workbook()` all accept the
  marks, and a column that looks like decimal commas under the default
  locale raises a warning.
* `gc_interval_stats()` returns `NA` for a bin with no observation instead of
  `-Inf` (`fun = max`) or `NaN` (`fun = mean`) (#5); shared `.safe_fun()`
  with `gc_hole_summary()`.
* `gc_convert_units()` converts XRF rows only by default (`method = "XRF"`;
  `NULL` for all) (#7). Converting to ppm used to sweep up SRA TOC and XRD
  wt% too, after which `gc_indices()` reported HI of about 0.02 without
  complaint. `gc_indices()` now checks the units of its inputs and stops
  with a message naming the analyte and unit.
* The README figure script is in the package: `data-raw/make_figures.R`.

# geochemR 0.2.1

* **Colour separation.** The furniture stays monochrome; the data no longer
  is. The categorical palette rotates through eleven distinct hues muted for
  parchment (espresso, rust, slate, moss, ochre, plum, teal, tan, indigo,
  brick, sage); continuous scales default to the multi-hue `"scholar"` ramp
  (sand through ochre and rust to plum and ink, luminance falling
  monotonically), with `"tide"` (cool) and `"divergent"` (slate-parchment-
  rust) alongside the single-hue ramps; `gc_mineral_colours` /
  `scale_fill_minerals()` colour XRD minerals by kind (silicates warm,
  carbonates blue, clays green, sulfides dark) so stacked mineralogy reads at
  a glance. `plot_stacked_depth(fill_scale = )`.

# geochemR 0.2.0

* **Laboratory workbook reader.** `read_workbook()` reads the multi-method
  cuttings-analysis deliverable layout — a group / analyte / unit header
  block, a QC row, then one sample per row with bottom depths and
  formation / zone labels — into a `gc_data` object in one call. Groups map
  to methods (TOC + pyrolysis → SRA, PAM → PAM, XRD bulk + clay speciation →
  XRD, XRF elements → XRF); lab-calculated columns are dropped by default so
  `gc_indices()` stays the single source of derived values; clay speciation
  reported relative to total clay is converted to bulk wt% (auto-detected).
* **PAM pyrolysis** is a method: `Oil1` … `Oil4`, `K1` and their `Tmax`;
  `gc_indices()` adds `Oil_total`, `Oil_TOC` and the fraction ratios;
  `plot_pam()` draws the stacked pyrolysis log. `gc_pam_analytes`.
* `formation` and `zone` on the sample table; `gc_hole_summary(by = )` for
  stratigraphic summaries.
* `gc_indices()`: weighted brittleness `BI_w`; `min_toc` cutoff for HI / OI
  / S1/TOC on lean samples.
* **The look.** `theme_gc()` and the `scale_*_gc()` scales replace the
  default ggplot2 styling: a parchment page, brown ink, tan-to-espresso
  palette and serif type in the manner of econscape's academic style, with
  Tufte's restraint — no panel fill or gridlines, hairline axes, muted
  titles, direct labels on depth profiles where they fit. `gc_colours()`,
  `gc_pal()`.
* `plot_stacked_depth()` (generic stacked-bar-by-depth; `plot_mineralogy()`
  now uses it).
* Second example dataset `gc_cuttings` — one well, 65 cuttings samples, all
  methods — shipped both as data and as the Excel workbook it was read from
  (`inst/extdata/cuttings_workbook.xlsx`).

# geochemR 0.1.0

First release.

* `gc_data` model: a sample table plus one long measurement table for XRD,
  XRF and SRA / Rock-Eval pyrolysis, with detection limits and qualifiers;
  validation on construction.
* Readers for wide laboratory tables (`read_xrd()`, `read_xrf()`,
  `read_sra()`, `read_samples()`): mineral-name aliases, unit suffixes,
  censored (`<5`) and blank values.
* Processing: LOD substitution, unit conversion, oxide/element conversion,
  renormalisation, centred and additive log-ratios, interval and per-hole
  summaries.
* `gc_indices()`: HI, OI, PI, S1/TOC, Ro-equivalent; CIA and element
  ratios; carbonate, clay, QFM and mineralogical brittleness.
* Plots: depth profiles, hole-by-depth heatmap, IDW cross-section, stacked
  mineralogy, planar map with IDW surface, ternary, kerogen-type plots.
* Synthetic `gc_example` dataset (12 holes, three units, all three methods).

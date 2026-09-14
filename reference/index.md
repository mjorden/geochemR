# Package index

## Data model

One tidy object for every method’s results

- [`gc_data()`](https://mjorden.github.io/geochemR/reference/gc_data.md)
  : The geochemR data model

- [`validate_gc()`](https://mjorden.github.io/geochemR/reference/validate_gc.md)
  :

  Validate a `gc_data` object

- [`gc_samples()`](https://mjorden.github.io/geochemR/reference/gc_samples.md)
  [`gc_measurements()`](https://mjorden.github.io/geochemR/reference/gc_samples.md)
  [`gc_analytes()`](https://mjorden.github.io/geochemR/reference/gc_samples.md)
  : Accessors

- [`gc_wide()`](https://mjorden.github.io/geochemR/reference/gc_wide.md)
  : Wide table of one method's results joined to the sample table

- [`gc_bind()`](https://mjorden.github.io/geochemR/reference/gc_bind.md)
  : Combine measurement sets for the same samples

- [`gc_example`](https://mjorden.github.io/geochemR/reference/gc_example.md)
  : Synthetic example dataset

- [`gc_cuttings`](https://mjorden.github.io/geochemR/reference/gc_cuttings.md)
  : Synthetic cuttings-analysis well

## Reading laboratory tables

A whole deliverable workbook in one call, or wide tables per method

- [`read_workbook()`](https://mjorden.github.io/geochemR/reference/read_workbook.md)
  : Read a multi-method laboratory workbook
- [`read_samples()`](https://mjorden.github.io/geochemR/reference/read_samples.md)
  : Read a sample / location table
- [`read_geochem()`](https://mjorden.github.io/geochemR/reference/read_geochem.md)
  [`read_xrd()`](https://mjorden.github.io/geochemR/reference/read_geochem.md)
  [`read_xrf()`](https://mjorden.github.io/geochemR/reference/read_geochem.md)
  [`read_sra()`](https://mjorden.github.io/geochemR/reference/read_geochem.md)
  : Read a laboratory results table into long measurements
- [`gc_mineral_name()`](https://mjorden.github.io/geochemR/reference/gc_mineral_name.md)
  [`gc_mineral_group()`](https://mjorden.github.io/geochemR/reference/gc_mineral_name.md)
  : Canonical mineral names
- [`.parse_values()`](https://mjorden.github.io/geochemR/reference/dot-parse_values.md)
  : Parse laboratory value strings
- [`gc_minerals`](https://mjorden.github.io/geochemR/reference/dictionaries.md)
  [`gc_oxides`](https://mjorden.github.io/geochemR/reference/dictionaries.md)
  [`gc_sra_analytes`](https://mjorden.github.io/geochemR/reference/dictionaries.md)
  [`gc_pam_analytes`](https://mjorden.github.io/geochemR/reference/dictionaries.md)
  : Analyte dictionaries

## Processing

- [`gc_substitute_lod()`](https://mjorden.github.io/geochemR/reference/gc_substitute_lod.md)
  : Substitute censored values
- [`gc_convert_units()`](https://mjorden.github.io/geochemR/reference/gc_convert_units.md)
  : Convert concentration units
- [`gc_oxide_to_element()`](https://mjorden.github.io/geochemR/reference/gc_oxide_to_element.md)
  [`gc_element_to_oxide()`](https://mjorden.github.io/geochemR/reference/gc_oxide_to_element.md)
  : Oxide / element conversion for XRF
- [`gc_renormalize()`](https://mjorden.github.io/geochemR/reference/gc_renormalize.md)
  : Renormalise a composition to a fixed total
- [`gc_clr()`](https://mjorden.github.io/geochemR/reference/gc_clr.md)
  [`gc_alr()`](https://mjorden.github.io/geochemR/reference/gc_clr.md) :
  Log-ratio transforms for compositional data
- [`gc_interval_stats()`](https://mjorden.github.io/geochemR/reference/gc_interval_stats.md)
  : Interval statistics per hole
- [`gc_hole_summary()`](https://mjorden.github.io/geochemR/reference/gc_hole_summary.md)
  : Per-hole (or per-formation) summary

## Derived indices

- [`gc_indices()`](https://mjorden.github.io/geochemR/reference/gc_indices.md)
  : Derived indices

## Plots in depth

- [`plot_depth_profile()`](https://mjorden.github.io/geochemR/reference/plot_depth_profile.md)
  : Depth profiles
- [`plot_depth_heatmap()`](https://mjorden.github.io/geochemR/reference/plot_depth_heatmap.md)
  : Hole-by-depth heatmap
- [`plot_section()`](https://mjorden.github.io/geochemR/reference/plot_section.md)
  : Interpolated cross-section along a line of holes
- [`plot_stacked_depth()`](https://mjorden.github.io/geochemR/reference/plot_stacked_depth.md)
  : Stacked composition against depth
- [`plot_mineralogy()`](https://mjorden.github.io/geochemR/reference/plot_mineralogy.md)
  : Stacked mineralogy bars
- [`plot_pam()`](https://mjorden.github.io/geochemR/reference/plot_pam.md)
  : PAM pyrolysis log

## Plots in plan and cross-plots

- [`plot_map()`](https://mjorden.github.io/geochemR/reference/plot_map.md)
  : Planar map of one analyte
- [`plot_ternary()`](https://mjorden.github.io/geochemR/reference/plot_ternary.md)
  : Ternary diagram
- [`plot_kerogen()`](https://mjorden.github.io/geochemR/reference/plot_kerogen.md)
  : Kerogen-type and maturity plots from pyrolysis
- [`gc_idw()`](https://mjorden.github.io/geochemR/reference/gc_idw.md) :
  Inverse-distance-weighted interpolation to a grid

## The look

Parchment, brown ink, Tufte restraint

- [`theme_gc()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  [`gc_colours()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  [`gc_pal()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  [`scale_colour_gc()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  [`scale_fill_gc()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  [`scale_colour_gc_c()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  [`scale_fill_gc_c()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  [`scale_color_gc()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  [`scale_color_gc_c()`](https://mjorden.github.io/geochemR/reference/theme_gc.md)
  : The geochemR look: academic parchment, Tufte restraint

## Package

- [`geochemR`](https://mjorden.github.io/geochemR/reference/geochemR-package.md)
  [`geochemR-package`](https://mjorden.github.io/geochemR/reference/geochemR-package.md)
  : geochemR: import, process and map geochemical data

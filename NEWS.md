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

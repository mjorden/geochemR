# Canonical mineral names

Canonical mineral names

## Usage

``` r
gc_mineral_name(x, strict = FALSE)

gc_mineral_group(x)
```

## Arguments

- x:

  Character vector of mineral names as printed by a lab.

- strict:

  Error (rather than pass through unchanged) on names that no alias
  matches.

## Value

Character vector of canonical names (see
[gc_minerals](https://mjorden.github.io/geochemR/reference/dictionaries.md)).

## Examples

``` r
gc_mineral_name(c("Quartz", "K-Feldspar", "I/S", "Illite/Mica"))
#> [1] "quartz"      "k_feldspar"  "mixed_layer" "illite"     
```

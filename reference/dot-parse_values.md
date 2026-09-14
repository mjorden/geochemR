# Parse laboratory value strings

`"<5"` becomes `value = 5, lod = 5, qualifier = "<"`; `">1000"` becomes
`value = 1000, qualifier = ">"`; `"n.d."`, `"nd"`, `"bdl"`, `"-"`, `""`
and `"NA"` become `NA`; everything else is coerced to a number (a
thousands comma is removed).

## Usage

``` r
.parse_values(x)
```

## Arguments

- x:

  A character or numeric vector.

## Value

A list with numeric `value`, numeric `lod`, character `qualifier`.

## Examples

``` r
.parse_values(c("12.5", "<5", ">1000", "n.d.", "1,250"))
#> $value
#> [1]   12.5    5.0 1000.0     NA 1250.0
#> 
#> $lod
#> [1] NA  5 NA NA NA
#> 
#> $qualifier
#> [1] NA  "<" ">" NA  NA 
#> 
```

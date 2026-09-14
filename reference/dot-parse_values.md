# Parse laboratory value strings

`"<5"` becomes `value = 5, lod = 5, qualifier = "<"`; `">1000"` becomes
`value = 1000, qualifier = ">"`; `"n.d."`, `"nd"`, `"bdl"`, `"-"`, `""`
and `"NA"` become `NA`; everything else is coerced to a number after the
grouping mark and any whitespace are removed and the decimal mark is
normalised to `"."`.

## Usage

``` r
.parse_values(x, decimal_mark = ".", grouping_mark = ",")
```

## Arguments

- x:

  A character or numeric vector.

- decimal_mark, grouping_mark:

  Decimal and thousands separators used in the file, as in
  [`readr::locale()`](https://readr.tidyverse.org/reference/locale.html).

## Value

A list with numeric `value`, numeric `lod`, character `qualifier`.

## Details

With the defaults (`decimal_mark = "."`, `grouping_mark = ","`)
`"1,250"` is 1250 - and so is `"2,5"` read as 25. A sheet written with a
decimal comma must be read with `decimal_mark = ","` (and usually
`grouping_mark = " "` or `"."`); when a column looks like that (every
comma is followed by one or two digits and there is no `"."` anywhere) a
warning says so.

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
.parse_values(c("2,5", "1 250,75"), decimal_mark = ",", grouping_mark = " ")
#> $value
#> [1]    2.50 1250.75
#> 
#> $lod
#> [1] NA NA
#> 
#> $qualifier
#> [1] NA NA
#> 
```

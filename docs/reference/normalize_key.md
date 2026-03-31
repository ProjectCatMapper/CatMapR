# Normalize Key Expressions

Normalize key strings by removing stored-form prefixes (for example
`Key == `), trimming whitespace around separators, and standardizing
`&&`-joined segments.

## Usage

``` r
normalize_key(key)
```

## Arguments

- key:

  Character vector of key expressions.

## Value

Character vector of normalized key expressions.

## Examples

``` r
normalize_key("Key == Region == Flagstaff")
#> [1] "Region == Flagstaff"
normalize_key(" Region==Flagstaff  && Type== Adamana Brown ")
#> [1] "Region == Flagstaff && Type == Adamana Brown"
```

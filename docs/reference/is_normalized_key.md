# Check Whether Keys Are Normalized

Test whether key strings are already in normalized CatMapper expression
form.

## Usage

``` r
is_normalized_key(key)
```

## Arguments

- key:

  Character vector of key expressions.

## Value

Logical vector (`TRUE` when normalized).

## Examples

``` r
is_normalized_key("Region == Flagstaff")
#> [1] TRUE
is_normalized_key("Key == Region == Flagstaff")
#> [1] FALSE
```

# Build CatMapper Key Expressions

Build key expressions in the `FIELD == VALUE` format used by CatMapper
upload workflows.

## Usage

``` r
build_key(field, value)
```

## Arguments

- field:

  Field name(s) used on the left side of the expression.

- value:

  Value(s) used on the right side of the expression.

## Value

A character vector of key expressions.

## Examples

``` r
build_key("Type", "Adamana Brown")
#> [1] "Type == Adamana Brown"
build_key(c("Type", "Region"), c("Adamana Brown", "Flagstaff"))
#> [1] "Type == Adamana Brown" "Region == Flagstaff"  
```

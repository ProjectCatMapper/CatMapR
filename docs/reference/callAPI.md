# Call API

Helper function to call the CatMapper API.

## Usage

``` r
callAPI(
  endpoint,
  parameters,
  request = "GET",
  url = NULL,
  type = "default",
  headers = NULL
)
```

## Arguments

- endpoint:

  API endpoint

- parameters:

  API parameters

- request:

  GET or POST

- url:

  API URL override. If `NULL`, `CATMAPR_API_URL` is used when set,
  otherwise `"https://api.catmapper.org"`.

- type:

  default or stream

- headers:

  Optional named list of request headers, for example
  `list("X-API-Key" = "cmk_...")`.

## Value

API response

## Examples

``` r
if (FALSE) { # \dontrun{
CatMapR:::callAPI(
  endpoint = "search",
  parameters = list(
    term = "Dan",
    database = "SocioMap",
    property = "Name",
    domain = "ETHNICITY"
  ),
  request = "GET"
)
} # }
```

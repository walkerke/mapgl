# Coerce a time column to a numeric property for filtering

Helper for preparing a `Date` or `POSIXct` column for use with
[`add_slider_control()`](https://walker-data.com/mapgl/reference/add_slider_control.md).
Because `sf` objects are serialized to GeoJSON as JSON strings for
date/time columns, the slider needs a numeric counterpart to filter on.

## Usage

``` r
as_time_property(x, unit = c("year", "month", "day", "date", "seconds"))
```

## Arguments

- x:

  A `Date`, `POSIXct`, or numeric vector.

- unit:

  One of:

  - `"year"` — calendar year as integer (e.g. 2026).

  - `"month"` — zero-based month index (0 = January).

  - `"day"` — day of month.

  - `"date"` — days since `1970-01-01`.

  - `"seconds"` — seconds since the Unix epoch.

## Value

An integer or numeric vector appropriate for attaching to an `sf` object
as a new column before calling
[`add_slider_control()`](https://walker-data.com/mapgl/reference/add_slider_control.md).

## Examples

``` r
dates <- as.Date(c("2015-01-15", "2015-06-30", "2015-12-31"))
as_time_property(dates, "month")
#> [1]  0  5 11
as_time_property(dates, "year")
#> [1] 2015 2015 2015
as_time_property(dates, "date")
#> [1] 16450 16616 16800
```

# Update flowmap filter

Updates the filter state of a flowmap layer, including selected
locations and time range.

## Usage

``` r
set_flowmap_filter(
  proxy,
  id,
  selected_locations = NULL,
  location_filter_mode = NULL,
  selected_time_range = NULL
)
```

## Arguments

- proxy:

  A map proxy object.

- id:

  The ID of the flowmap layer to update.

- selected_locations:

  Optional vector of location IDs to select.

- location_filter_mode:

  Optional location filter mode: `"ALL"`, `"INCOMING"`, `"OUTGOING"`, or
  `"BETWEEN"`.

- selected_time_range:

  Optional vector of two dates for time filtering.

## Value

The modified map proxy.

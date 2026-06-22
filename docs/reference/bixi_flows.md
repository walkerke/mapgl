# BIXI Montréal Hourly Bike Sharing Flows (July 1-7, 2019)

A dataset containing hourly aggregated bike sharing trips between BIXI
stations in Montréal during the week of July 1 to July 7, 2019.

## Usage

``` r
bixi_flows
```

## Format

A data frame with 6,092 rows and 4 variables:

- time:

  Hourly timestamp (POSIXct, UTC)

- origin:

  Origin station ID (factor, matching `bixi_locations$id`)

- dest:

  Destination station ID (factor, matching `bixi_locations$id`)

- count:

  Aggregated number of bike sharing trips in that hour (integer)

## Source

BIXI Montréal Open Data (<https://bixi.com/fr/donnees-ouvertes>).
Prepared for <https://github.com/FlowmapBlue/FlowmapBlue> by Ilya
Boyandin (<https://github.com/ilyabo>). Data © BIXI Montréal, released
under the BIXI Montréal Open Data license
(<https://bixi.com/fr/donnees-ouvertes>). Original interactive
visualization on Flowmap.blue:
<https://www.flowmap.blue/1qTVOzkPB7U1ySI4g4uPtVBzzEDCI8n1WXAmQeZL15fE>

## Details

To minimize the package footprint, the dataset has been truncated to a
**minimum of three trips** (retaining only flows where `count > 2`),
which reduces the rows from 213,227 to 6,092, and compresses the final
size to just **~22 KB**.

## See also

[`bixi_locations`](https://walker-data.com/mapgl/reference/bixi_locations.md)

## Examples

``` r
# Check first few records
print(head(bixi_flows))
#>                  time origin dest count
#> 1 2019-07-01 15:00:00   6501 6501    22
#> 2 2019-07-06 13:00:00   6501 6501    18
#> 3 2019-07-05 16:00:00   6501 6501    18
#> 4 2019-07-03 12:00:00   6501 6501    17
#> 5 2019-07-01 12:00:00   6501 6501    15
#> 6 2019-07-07 15:00:00   6501 6501    15
```

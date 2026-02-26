# Add a video source to a Mapbox GL or Maplibre GL map

Add a video source to a Mapbox GL or Maplibre GL map

## Usage

``` r
add_video_source(map, id, urls, coordinates)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- id:

  A unique ID for the source.

- urls:

  A vector of URLs pointing to the video sources.

- coordinates:

  A list of coordinates specifying the video corners in clockwise order:
  top left, top right, bottom right, bottom left.

## Value

The modified map object with the new source added.

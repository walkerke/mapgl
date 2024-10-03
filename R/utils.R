bounds_to_zoom <-
  function(bounds) {
    xlength <- diff(bounds[c(1, 3)])
    ylength <- diff(bounds[c(2, 4)])
    xzoom <- log2(360 * 2 / xlength)
    yzoom <- log2(180 * 2 / ylength)
    min(yzoom, xzoom)
  }

bounds_to_center <-
  function(bounds) {
    center_lon <- (bounds[1] + bounds[3]) / 2
    center_lat <- (bounds[2] + bounds[4]) / 2

    c(center_lon, center_lat)
  }

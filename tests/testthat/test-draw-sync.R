test_that("drawn features keep full coordinate precision from Shiny input", {
  geojson <- '{"type":"FeatureCollection","features":[
    {"type":"Feature","id":"a","properties":{},
     "geometry":{"type":"Point","coordinates":[-85.831278645,33.659123456]}},
    {"type":"Feature","id":"b","properties":{},
     "geometry":{"type":"Polygon","coordinates":[[[-97.123456789,32.712345678],
       [-97.113456789,32.712345678],[-97.113456789,32.722345678],
       [-97.123456789,32.712345678]]]}}]}'

  # Shiny decodes object inputs into nested lists like this
  shiny_input <- jsonlite::fromJSON(geojson, simplifyVector = FALSE)

  from_list <- mapgl:::.mapgl_coerce_drawn_features(shiny_input)
  from_string <- mapgl:::.mapgl_coerce_drawn_features(geojson)

  expect_equal(
    sf::st_coordinates(from_list[1, ])[1, c("X", "Y")],
    c(X = -85.831278645, Y = 33.659123456),
    tolerance = 1e-9
  )
  expect_equal(
    sf::st_geometry(from_list),
    sf::st_geometry(from_string),
    tolerance = 1e-9
  )
})

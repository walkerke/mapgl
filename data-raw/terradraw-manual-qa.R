# Manual QA walkthrough for the Terra Draw provider in add_draw_control().
# Run section by section in RStudio (widgets render to the Viewer; the Shiny
# apps launch in a window). Each scenario lists what to VERIFY by hand.
#
# Not shipped with the package — dev use only.

library(mapgl)
library(sf)

# nc is MultiPolygon — perfect for testing Multi* explosion on load
nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE) |>
  st_transform(4326)

# ---------------------------------------------------------------------------
# 1. BACK-COMPAT: default provider is untouched
# ---------------------------------------------------------------------------
# VERIFY: the familiar mapbox-gl-draw toolbar (polygon/line/point/trash),
# drawing works exactly as before this branch.

maplibre() |>
  add_draw_control()

# ---------------------------------------------------------------------------
# 2. TERRA BASICS: default mode set on MapLibre
# ---------------------------------------------------------------------------
# VERIFY:
# * toolbar shows point, line, polygon, select (cursor), trash, in native
#   control chrome; tooltips on hover; active button highlights
# * draw one of each; after finishing a shape the control returns to the
#   select tool WITH the new feature selected (drag it to confirm)
# * clicking the active tool button again toggles back to select
# * select mode: drag whole features; drag vertices; insert via midpoints;
#   vertex deletion; click empty space deselects
# * trash is grayed out with nothing selected (and does nothing); with a
#   selection it deletes ONLY the selected feature
# * feature clicks are suppressed while a draw tool is active

maplibre() |>
  add_draw_control(provider = "terra-draw")

# Equivalent convenience wrapper — identical control:
maplibre() |>
  add_terradraw_control()

# ---------------------------------------------------------------------------
# 3. EVERY MODE + DOWNLOAD
# ---------------------------------------------------------------------------
# VERIFY:
# * each of the 11 buttons draws its shape (angled-rectangle: click, move,
#   click, move, click; sector: center, radius, sweep; sensor: center, arc
#   points; freehand variants: click then move (no drag needed), click again
#   to close)
# * download button exports a .geojson with everything drawn
# * downloaded features carry properties.mode per tool; circles carry
#   radiusKilometers

maplibre() |>
  add_draw_control(
    provider = "terra-draw",
    modes = c(
      "point", "linestring", "polygon", "rectangle", "circle",
      "freehand", "freehand-linestring", "angled-rectangle",
      "sector", "sensor", "select"
    ),
    download_button = TRUE,
    download_filename = "terra-qa"
  )

# ---------------------------------------------------------------------------
# 4. STYLING + COLOR COERCION (named R colors must work)
# ---------------------------------------------------------------------------
# VERIFY:
# * points tomato, lines/outlines dark green + width 4, fills orchid at 0.4
# * selected features/vertices turn gold; vertex dots radius ~8
# * horizontal toolbar orientation

maplibre() |>
  add_draw_control(
    provider = "terra-draw",
    modes = c("point", "linestring", "polygon", "circle", "select"),
    point_color = "tomato",
    line_color = "darkgreen",
    fill_color = "orchid",
    fill_opacity = 0.4,
    active_color = "gold",
    vertex_radius = 8,
    line_width = 4,
    orientation = "horizontal"
  )

# ---------------------------------------------------------------------------
# 5. terradraw_options(): snapping, rotate/scale, resize
# ---------------------------------------------------------------------------
# 5a. Snapping + rotate + scale.
# VERIFY:
# * drawing a second polygon snaps its vertices to the first's coordinates
#   and edges
# * in select mode, select a polygon and hold Control+R while dragging it to
#   rotate; hold Control+S while dragging it to scale (use Control on macOS too)
# * rotation and scaling do not show dedicated handles; resize below does

maplibre() |>
  add_draw_control(
    provider = "terra-draw",
    modes = c("polygon", "linestring", "select"),
    options = terradraw_options(
      snap_to_coordinates = TRUE,
      snap_to_lines = TRUE,
      rotate_features = TRUE,
      scale_features = TRUE
    )
  )

# 5b. Resize handles (midpoints auto-disabled — Terra Draw can't do both).
# VERIFY: dragging a selection point resizes the rectangle from the center;
# no midpoints appear.

maplibre() |>
  add_draw_control(
    provider = "terra-draw",
    modes = c("rectangle", "select"),
    options = terradraw_options(resize = "center")
  )

# 5c. keep_mode_active + click-drag interaction.
# VERIFY:
# * rectangle/circle draw by click-and-drag (not click-move-click)
# * after finishing a shape the tool STAYS active (draw several in a row)

maplibre() |>
  add_draw_control(
    provider = "terra-draw",
    modes = c("rectangle", "circle", "select"),
    options = terradraw_options(
      drag_interaction = "click-drag",
      keep_mode_active = TRUE
    )
  )

# ---------------------------------------------------------------------------
# 6. MEASUREMENTS
# ---------------------------------------------------------------------------
# VERIFY:
# * measurement box (bottom-left) updates live while drawing lines (length)
#   and polygons (area + perimeter)
# * circles report radius + area
# * box shows while a feature is selected, hides ~3s after deselect/finish
# * try measurement_units = "metric" or "imperial" too

maplibre() |>
  add_draw_control(
    provider = "terra-draw",
    modes = c("linestring", "polygon", "circle", "select"),
    show_measurements = TRUE,
    measurement_units = "both"
  )

# ---------------------------------------------------------------------------
# 7. ATTRIBUTE EDITOR
# ---------------------------------------------------------------------------
# VERIFY:
# * finishing a shape opens the editor with defaults applied
#   (confidence = 1); selecting exactly one feature reopens it
# * Save writes values; deselect hides the panel; deleting the feature
#   hides it too
# * after drawing + saving, run get_drawn_features(<this map>) below and
#   confirm the class/notes/confidence and mode columns

m_attrs <- maplibre() |>
  add_draw_control(
    provider = "terra-draw",
    modes = c("polygon", "freehand", "select"),
    attributes = list(
      class = draw_attribute(
        "select",
        choices = c("forest", "water", "urban"),
        required = TRUE
      ),
      notes = draw_attribute("textarea"),
      confidence = draw_attribute("numeric", min = 0, max = 1, step = 0.1, default = 1)
    )
  )
m_attrs

# ...draw + save attributes in the Viewer first, then:
get_drawn_features(m_attrs)

# ---------------------------------------------------------------------------
# 8. LOADING FEATURES + NON-SHINY ROUND TRIP
# ---------------------------------------------------------------------------
# VERIFY:
# * nc counties appear in the draw layer at load (MultiPolygons exploded to
#   polygons — check the browser console shows NO warnings about dropped
#   features)
# * loaded counties are selectable/editable/deletable like drawn features
# * get_drawn_features() returns them as sf with a mode column ("polygon")
#   plus the original attribute columns (NAME etc.)

m_loaded <- maplibre(bounds = nc) |>
  add_source(id = "nc", data = nc) |>
  add_draw_control(provider = "terra-draw", source = "nc")
m_loaded

get_drawn_features(m_loaded)

# ---------------------------------------------------------------------------
# 9. MAPBOX ENGINE (needs MAPBOX_PUBLIC_TOKEN)
# ---------------------------------------------------------------------------
# VERIFY: everything from scenarios 2-4 behaves identically on a Mapbox map
# (toolbar chrome, drawing, select/edit, trash, styling).

mapboxgl() |>
  add_draw_control(
    provider = "terra-draw",
    modes = c("point", "polygon", "rectangle", "circle", "select"),
    download_button = TRUE
  )

# ---------------------------------------------------------------------------
# 10. BOTH WIDGET TYPES ON ONE PAGE (mixed dependency resolution)
# ---------------------------------------------------------------------------
# VERIFY: BOTH maps get a working terra toolbar (this is the page setup that
# would break if the adapters collided in dependency resolution).

htmltools::browsable(htmltools::tagList(
  maplibre(height = "380px") |>
    add_draw_control(provider = "terra-draw"),
  mapboxgl(height = "380px") |>
    add_draw_control(provider = "terra-draw")
))

# ---------------------------------------------------------------------------
# 11. SHINY: proxies, reactivity, style survival, clear/re-add
# ---------------------------------------------------------------------------
# The map renders WITHOUT a draw control. Walk the buttons top to bottom:
#
# * "Add draw control (proxy)" — toolbar appears; draw some features; the
#   table updates live (mode column included); measurements + attribute
#   editor work on the proxy-added control
# * click "Add draw control (proxy)" AGAIN — console warns, no duplicate
#   toolbar, existing features untouched
# * "Load NC counties" — MultiPolygons explode in; clear_existing replaces
#   anything drawn
# * "Switch style" — WHILE a feature is selected and again while mid-draw:
#   features survive the basemap change, the unfinished shape is discarded,
#   selection clears, no console errors, no duplicated draw layers
# * "Get drawn features" — same collection as the live table
# * "Clear drawn features" — map empties, table empties, toolbar stays
# * "Remove draw control" — toolbar, measurement box, and editor all vanish;
#   style has no leftover mapgl-terradraw-* sources (check devtools);
#   then "Add draw control (proxy)" works again from scratch

if (interactive()) {
  library(shiny)

  shinyApp(
    ui = fluidPage(
      fluidRow(
        column(
          3,
          actionButton("add_draw", "Add draw control (proxy)"),
          actionButton("load_nc", "Load NC counties (clear first)"),
          actionButton("switch_style", "Switch style"),
          actionButton("get_feats", "Get drawn features"),
          actionButton("clear_feats", "Clear drawn features"),
          actionButton("remove_draw", "Remove draw control"),
          tags$hr(),
          tableOutput("feats")
        ),
        column(9, maplibreOutput("map", height = "640px"))
      )
    ),
    server = function(input, output, session) {
      output$map <- renderMaplibre(maplibre())
      styles <- c(carto_style("positron"), carto_style("dark-matter"))
      style_i <- reactiveVal(0)

      observeEvent(input$add_draw, {
        maplibre_proxy("map") |>
          add_draw_control(
            provider = "terra-draw",
            modes = c("point", "linestring", "polygon", "circle", "freehand", "select"),
            show_measurements = TRUE,
            attributes = list(
              class = draw_attribute("select", choices = c("a", "b", "c"))
            )
          )
      })
      observeEvent(input$load_nc, {
        maplibre_proxy("map") |>
          add_source(id = "nc", data = nc) |>
          add_features_to_draw(source = "nc", clear_existing = TRUE)
      })
      observeEvent(input$switch_style, {
        style_i(style_i() + 1)
        maplibre_proxy("map") |>
          set_style(styles[(style_i() %% 2) + 1])
      })
      observeEvent(input$get_feats, {
        maplibre_proxy("map") |> get_drawn_features()
      })
      observeEvent(input$clear_feats, {
        maplibre_proxy("map") |> clear_drawn_features()
      })
      observeEvent(input$remove_draw, {
        maplibre_proxy("map") |> clear_controls("draw")
      })
      output$feats <- renderTable({
        feats <- input$map_drawn_features
        req(feats)
        sf_obj <- mapgl:::.mapgl_coerce_drawn_features(feats)
        if (nrow(sf_obj) == 0) {
          return(data.frame(note = "no features"))
        }
        df <- st_drop_geometry(sf_obj)
        df$geom_type <- as.character(st_geometry_type(sf_obj))
        head(df, 12)
      })
    }
  )
}

# ---------------------------------------------------------------------------
# 12. COMPARE VIEWS
# ---------------------------------------------------------------------------
# VERIFY:
# * each side has its own working terra toolbar; drawing on one side does
#   not draw on the other
# * select/edit and trash work per side
# * (known, pre-existing limitation shared with mapbox-gl-draw: in Shiny,
#   both sides report to the same <id>_drawn_features input)

compare(
  maplibre() |>
    add_draw_control(provider = "terra-draw"),
  maplibre() |>
    add_draw_control(
      provider = "terra-draw",
      modes = c("rectangle", "circle", "select"),
      fill_color = "orchid"
    )
)

# Mapbox compare (needs token):
compare(
  mapboxgl() |> add_draw_control(provider = "terra-draw"),
  mapboxgl() |> add_draw_control(provider = "terra-draw", fill_color = "orange")
)

# Mixed providers across sides — mapbox-gl-draw on the left, terra on the
# right; both must work independently:
compare(
  maplibre() |> add_draw_control(),
  maplibre() |> add_draw_control(provider = "terra-draw")
)

# ---------------------------------------------------------------------------
# 13. COMPARE + SHINY PROXY (side targeting)
# ---------------------------------------------------------------------------
# VERIFY: the proxy adds the terra toolbar to the AFTER (right) side only;
# drawing there updates the table; clear works.

if (interactive()) {
  library(shiny)

  shinyApp(
    ui = fluidPage(
      actionButton("add_after", "Add terra draw to right side"),
      actionButton("clear", "Clear drawn features"),
      tableOutput("feats"),
      maplibreCompareOutput("cmp", height = "600px")
    ),
    server = function(input, output, session) {
      output$cmp <- renderMaplibreCompare(
        compare(maplibre(), maplibre())
      )
      observeEvent(input$add_after, {
        maplibre_compare_proxy("cmp", map_side = "after") |>
          add_draw_control(provider = "terra-draw")
      })
      observeEvent(input$clear, {
        maplibre_compare_proxy("cmp", map_side = "after") |>
          clear_drawn_features()
      })
      output$feats <- renderTable({
        feats <- input$cmp_drawn_features
        req(feats)
        df <- st_drop_geometry(mapgl:::.mapgl_coerce_drawn_features(feats))
        head(df, 10)
      })
    }
  )
}

# ---------------------------------------------------------------------------
# 14. CURVE MODES (pen-tool drawing)
# ---------------------------------------------------------------------------
# VERIFY (the basketball key test):
# * activate the curved-polygon tool; map panning is DISABLED while it is
#   active (try dragging the basemap) and restored when you switch tools
# * click 4 corners of the lane rectangle, then CLICK-AND-DRAG at the free
#   throw line to pull out curve handles (a dashed handle line + gray dots
#   preview while dragging; drag distance sets the curvature)
# * mouse move shows a live rubber-band preview; hovering the first point
#   switches the cursor to a pointer (close affordance); click it to finish
# * after finishing: back on the select tool with the key selected; move it
#   and confirm the curve shape is preserved exactly
# * Backspace removes the last point mid-draw; Enter finishes (needs >= 3
#   points); Escape cancels and leaves nothing behind
# * try to close a bow-tie (self-crossing outline): finishing is refused
#   with a console warning until you fix the shape
# * curve-linestring: trace a river with mixed straight and curved sections;
#   Enter or clicking the LAST point finishes
# * get_drawn_features() below: curve features carry a curveNodes JSON
#   column alongside the densified geometry; measurements/download work

m_curve <- maplibre() |>
  add_terradraw_control(
    modes = c("curve", "curve-linestring", "select"),
    show_measurements = TRUE,
    download_button = TRUE
  )
m_curve

get_drawn_features(m_curve)

# Style switch after drawing curves — curves survive with metadata intact
# (test in the Shiny app of scenario 11 by adding "curve" to its modes)

# Mapbox-engine curve smoke (needs token): draw + close + move one curve
mapboxgl() |>
  add_terradraw_control(modes = c("curve", "select"))

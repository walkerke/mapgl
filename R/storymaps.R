#' Create a story section for story maps
#' @param title Section title
#' @param content Section content - can be text, HTML, or Shiny outputs
#' @param position Position of text block ("left", "center", "right")
#' @param width Width of text block in pixels (default: 400)
#' @param bg_color Background color (with alpha) for text block
#' @param text_color Text color
#' @param font_family Font family for the section
#' @export
story_section <- function(
    title,
    content,
    position = c("left", "center", "right"),
    width = 400,
    bg_color = "rgba(255,255,255,0.9)",
    text_color = "#34495e",
    font_family = NULL) {
    position <- match.arg(position)

    # Calculate margin based on position
    margin_style <- switch(position,
        "left" = "margin-left: 50px;",
        "center" = if (is.numeric(width)) {
            sprintf("margin-left: calc(50%% - %dpx);", width / 2)
        } else {
            sprintf("margin-left: calc(50%% - (%s/2));", width)
        },
        "right" = sprintf("margin-right: 50px; margin-left: auto;")
    )

    # Create style
    panel_style <- sprintf(
        "width: %s; %s background: %s; color: %s;%s",
        if (is.numeric(width)) paste0(width, "px") else width,
        margin_style,
        bg_color,
        text_color,
        if (!is.null(font_family)) sprintf("font-family: %s;", font_family) else ""
    )

    div(
        class = "section-panel",
        style = panel_style,
        h2(title),
        # If content is a list or multiple elements, wrap them
        if (is.list(content) || length(content) > 1) {
            div(class = "section-content", content)
        } else {
            # Single string or element
            div(class = "section-content", p(content))
        }
    )
}

#' Create a scrollytelling story map
#' @param map_id The ID of your mapboxgl, maplibre, or leaflet output
#'        defined in the server, e.g. `"map"`
#' @param sections A named list of story_section objects.
#'        Names will correspond to map events defined within
#'        the server using `on_section()`.
#' @param map_type One of `"mapboxgl"`, `"maplibre"`, or `"leaflet"`.
#'        This will use either `mapboxglOutput()`, `maplibreOutput()`,
#'        or `leafletOutput()` respectively, and must
#'        correspond to the appropriate `render*()` function used in the server.
#' @param root_margin The margin around the viewport for triggering sections by
#'        the intersection observer. Should be specified as a string,
#'        e.g. `"-20% 0px -20% 0px"`.
#' @param threshold A number that indicates the visibility ratio for a story
#''       panel to be used to trigger a section; should be a number between
#'        0 and 1. Defaults to 0, meaning that the section is triggered as soon
#'        as the first pixel is visible.
#' @param styles Optional custom CSS styles. Should be specified as a
#'        character string within `shiny::tags$style()`.
#' @param bg_color Default background color for all sections
#' @param text_color Default text color for all sections
#' @param font_family Default font family for all sections
#' @export
story_map <- function(
    map_id,
    sections,
    map_type = c("mapboxgl", "maplibre", "leaflet"),
    root_margin = "-20% 0px -20% 0px",
    threshold = 0,
    styles = NULL,
    bg_color = "rgba(255,255,255,0.9)",
    text_color = "#34495e",
    font_family = NULL) {
    # Apply global styles to sections that don't override them
    sections <- lapply(sections, function(section) {
        # Only update attributes if they weren't explicitly set
        if (is.null(section$attribs$style)) {
            section$attribs$style <- ""
        }

        # Parse existing style string to get current values
        current_style <- section$attribs$style
        current_bg <- if (grepl("background:", current_style)) NULL else bg_color
        current_color <- if (grepl("color:", current_style)) NULL else text_color
        current_font <- if (grepl("font-family:", current_style)) NULL else font_family

        # Update section with global styles if not already set
        if (!is.null(current_bg)) {
            section$attribs$style <- paste(section$attribs$style, sprintf("background: %s;", current_bg))
        }
        if (!is.null(current_color)) {
            section$attribs$style <- paste(section$attribs$style, sprintf("color: %s;", current_color))
        }
        if (!is.null(current_font)) {
            section$attribs$style <- paste(section$attribs$style, sprintf("font-family: %s;", current_font))
        }

        section
    })

    default_styles <- tags$style("
    .section-panel {
      padding: 20px;
      margin-top: 20vh;
      margin-bottom: 20vh;
      box-shadow: 0 0 10px rgba(0,0,0,0.1);
      border-radius: 8px;
      pointer-events: auto;
    }
    .section-panel h2 {
      margin-bottom: 15px;
    }
    .section-panel p {
      line-height: 1.6;
    }
    .spacer {
      height: 60vh;
      pointer-events: none;
    }
    .scroll-container {
      position: relative;
      z-index: 2;
      pointer-events: none;
    }
  ")

    # Intersection Observer setup (same as before)
    observer_js <- sprintf("
    var observer;

    $(document).ready(function() {
      var options = {
        root: null,
        rootMargin: '%s',
        threshold: %s
      };

      var callback = function(entries) {
        entries.forEach(function(entry) {
          if (entry.isIntersecting) {
            Shiny.setInputValue('%s_active_section', entry.target.id, {priority: 'event'});
          }
        });
      };

      observer = new IntersectionObserver(callback, options);

      $('.section').each(function() {
        observer.observe(this);
      });
    });
  ", root_margin, threshold, map_id)

    map_output_fn <- switch(match.arg(map_type),
        mapboxgl = mapboxglOutput,
        maplibre = maplibreOutput,
        leaflet = leaflet::leafletOutput
    )

    # Create container structure
    tagList(
        div(
            style = "position: fixed; top: 0; left: 0; width: 100%; height: 100vh; z-index: 1;",
            map_output_fn(map_id, height = "100%")
        ),
        div(
            class = "scroll-container",
            tags$head(
                default_styles,
                if (!is.null(styles)) styles,
                tags$script(observer_js)
            ),
            Map(function(id, section) {
                # Modify the section's class and id to include the list name
                section$attribs$class <- paste(section$attribs$class, id)
                section$attribs$id <- paste0("section-", id)

                tagList(
                    div(
                        class = "section",
                        id = id,
                        section # story_section object
                    ),
                    div(class = "spacer")
                )
            }, names(sections), sections)
        )
    )
}

#' Observe events on story map section transitions
#'
#' For a given `story_section()`, you may want to trigger an event when the section becomes visible.
#' This function wraps `shiny::observeEvent()` to allow you to modify the state of your map or
#' invoke other Shiny actions on user scroll.
#'
#' @param map_id The ID of your map output
#' @param section_id The ID of the section to trigger on, defined in `story_section()`
#' @param handler Expression to execute when section becomes visible.
#' @export
on_section <- function(map_id, section_id, handler) {
    # Get the current reactive domain
    domain <- shiny::getDefaultReactiveDomain()
    if (is.null(domain)) {
        stop("on_section() must be called from within a Shiny reactive context")
    }

    # Capture the handler expression
    handler_expr <- substitute(handler)

    # Create a reactive environment for evaluation
    parent_env <- parent.frame()

    shiny::observeEvent(domain$input[[paste0(map_id, "_active_section")]], {
        active_section <- domain$input[[paste0(map_id, "_active_section")]]
        if (active_section == section_id) {
            local({
                eval(handler_expr, envir = parent_env)
            })
        }
    })
}

#' Create a scrollytelling story map with MapLibre
#' @inheritParams story_map
#' @export
story_maplibre <- function(
    map_id,
    sections,
    root_margin = "-20% 0px -20% 0px",
    threshold = 0,
    styles = NULL,
    bg_color = "rgba(255,255,255,0.9)",
    text_color = "#34495e",
    font_family = NULL) {
    story_map(
        map_id = map_id,
        sections = sections,
        map_type = "maplibre",
        root_margin = root_margin,
        threshold = threshold,
        styles = styles,
        bg_color = bg_color,
        text_color = text_color,
        font_family = font_family
    )
}

#' Create a scrollytelling story map with Leaflet
#' @inheritParams story_map
#' @export
story_leaflet <- function(
    map_id,
    sections,
    root_margin = "-20% 0px -20% 0px",
    threshold = 0,
    styles = NULL,
    bg_color = "rgba(255,255,255,0.9)",
    text_color = "#34495e",
    font_family = NULL) {
    story_map(
        map_id = map_id,
        sections = sections,
        map_type = "leaflet",
        root_margin = root_margin,
        threshold = threshold,
        styles = styles,
        bg_color = bg_color,
        text_color = text_color,
        font_family = font_family
    )
}

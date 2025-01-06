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
    font_family = NULL
) {
  position <- match.arg(position)

  # Calculate margin based on position
  margin_style <- switch(position,
                         "left" = "margin-left: 50px;",
                         "center" = sprintf("margin-left: calc(50%% - %dpx);", width/2),
                         "right" = sprintf("margin-right: 50px; margin-left: auto;")
  )

  # Create style
  panel_style <- sprintf(
    "width: %dpx; %s background: %s; color: %s;%s",
    width,
    margin_style,
    bg_color,
    text_color,
    if (!is.null(font_family)) sprintf("font-family: %s;", font_family) else ""
  )

  div(
    class = "text-panel",
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
#' @param map_id The ID of your mapboxgl/maplibre output
#' @param sections Named list of story_section objects
#' @param root_margin Margin around viewport for triggering sections
#' @param styles Optional custom CSS styles
#' @export
story_map <- function(
    map_id,
    sections,
    root_margin = '-20% 0px -20% 0px',
    styles = NULL
) {
  # Default styles (simplified as some styling moves to story_section)
  default_styles <- tags$style("
    .text-panel {
      padding: 20px;
      margin-top: 20vh;
      margin-bottom: 20vh;
      box-shadow: 0 0 10px rgba(0,0,0,0.1);
      border-radius: 8px;
      pointer-events: auto;
    }
    .text-panel h2 {
      margin-bottom: 15px;
    }
    .text-panel p {
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
        threshold: 0
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
  ", root_margin, map_id)

  # Create container structure
  tagList(
    div(
      style = "position: fixed; top: 0; left: 0; width: 100%; height: 100vh; z-index: 1;",
      mapboxglOutput(map_id, height = "100%")
    ),
    div(
      class = "scroll-container",
      tags$head(
        default_styles,
        if (!is.null(styles)) styles,
        tags$script(observer_js)
      ),
      Map(function(id, section) {
        tagList(
          div(
            class = "section",
            id = id,
            section  # story_section object
          ),
          div(class = "spacer")
        )
      }, names(sections), sections)
    )
  )
}

#' Handle story map section visibility
#' @param map_id The ID of your mapboxgl/maplibre output
#' @param section_id The ID of the section to trigger on
#' @param handler Expression to execute when section becomes visible
#' @export
on_section <- function(map_id, section_id, handler) {
  # Get the current reactive domain
  domain <- shiny::getDefaultReactiveDomain()
  if (is.null(domain)) {
    stop("on_section() must be called from within a Shiny reactive context")
  }

  # Capture the handler expression
  handler_expr <- substitute(handler)

  observeEvent(domain$input[[paste0(map_id, "_active_section")]], {
    active_section <- domain$input[[paste0(map_id, "_active_section")]]
    if (active_section == section_id) {
      eval(handler_expr, envir = parent.frame())
    }
  })
}

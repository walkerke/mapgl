# Observe events on story map section transitions

For a given
[`story_section()`](https://walker-data.com/mapgl/reference/story_section.md),
you may want to trigger an event when the section becomes visible. This
function wraps
[`shiny::observeEvent()`](https://rdrr.io/pkg/shiny/man/observeEvent.html)
to allow you to modify the state of your map or invoke other Shiny
actions on user scroll.

## Usage

``` r
on_section(map_id, section_id, handler)
```

## Arguments

- map_id:

  The ID of your map output

- section_id:

  The ID of the section to trigger on, defined in
  [`story_section()`](https://walker-data.com/mapgl/reference/story_section.md)

- handler:

  Expression to execute when section becomes visible.

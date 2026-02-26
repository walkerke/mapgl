# Create a story section for story maps

Create a story section for story maps

## Usage

``` r
story_section(
  title,
  content,
  position = c("left", "center", "right"),
  width = 400,
  bg_color = NULL,
  text_color = NULL,
  font_family = NULL
)
```

## Arguments

- title:

  Section title

- content:

  Section content - can be text, HTML, or Shiny outputs

- position:

  Position of text block ("left", "center", "right")

- width:

  Width of text block in pixels (default: 400)

- bg_color:

  Background color (with alpha) for text block

- text_color:

  Text color

- font_family:

  Font family for the section

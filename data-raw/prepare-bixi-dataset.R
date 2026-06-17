# data-raw/prepare-bixi-dataset.R
# Script to prepare the BIXI Montréal 2019 example dataset for the mapgl package.
# Downloads the data directly from the public Google Sheet provided by the user,
# cleans IDs and coordinates, and filters out low flows (minimum 3 trips, count > 2) to minimize footprint.

library(readxl)
library(usethis)

# 1. Sheet Details & Download
sheet_id <- "1qTVOzkPB7U1ySI4g4uPtVBzzEDCI8n1WXAmQeZL15fE"
xlsx_url <- paste0("https://docs.google.com/spreadsheets/d/", sheet_id, "/export?format=xlsx")

tmp_xlsx <- tempfile(fileext = ".xlsx")
message("Downloading BIXI Montréal Google Sheet as Excel workbook...")
download.file(xlsx_url, tmp_xlsx, mode = "wb", quiet = TRUE)
message("Download complete!")

# 2. Read Raw Sheets
locations_raw <- read_excel(tmp_xlsx, sheet = "locations")
flows_raw <- read_excel(tmp_xlsx, sheet = "flows")
unlink(tmp_xlsx)

# Helper function to clean Excel float-like ID formatting (e.g. "4000.0" -> "4000")
clean_id <- function(x) {
  num_val <- suppressWarnings(as.numeric(x))
  ifelse(!is.na(num_val) & num_val == floor(num_val), as.character(as.integer(num_val)), x)
}

# 3. Clean Locations
message("Cleaning locations dataset...")
bixi_locations <- as.data.frame(locations_raw)
bixi_locations$id <- clean_id(bixi_locations$id)

# 4. Clean Flows, Filter for Low Flows (count > 2), and Optimize Types
message("Cleaning and optimizing flows dataset (filtering for count > 2 to minimize package footprint)...")
bixi_flows <- as.data.frame(flows_raw)
bixi_flows$origin <- clean_id(bixi_flows$origin)
bixi_flows$dest <- clean_id(bixi_flows$dest)
bixi_flows$count <- as.integer(bixi_flows$count)

# Clean matching (only keep flows that correspond to valid locations)
bixi_flows <- bixi_flows[bixi_flows$origin %in% bixi_locations$id & bixi_flows$dest %in% bixi_locations$id, ]

# Filter count > 2 (retaining minimum 3 trips in an hour)
bixi_flows <- bixi_flows[bixi_flows$count > 2, ]

# Convert origin/dest to factor types matching locations$id for optimal serialization and memory
bixi_flows$origin <- factor(bixi_flows$origin, levels = bixi_locations$id)
bixi_flows$dest <- factor(bixi_flows$dest, levels = bixi_locations$id)

# 5. Save and Package
message("Packaging datasets into the package data/ folder using xz compression...")
usethis::use_data(bixi_locations, overwrite = TRUE, compress = "xz")
usethis::use_data(bixi_flows, overwrite = TRUE, compress = "xz")

message("Data preparation and packaging completed successfully!")
message("  - bixi_locations: ", nrow(bixi_locations), " stations")
message("  - bixi_flows: ", nrow(bixi_flows), " flow paths (count > 2)")


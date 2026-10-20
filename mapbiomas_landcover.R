# https://gis.stackexchange.com/questions/432321/parallelize-raster-area-calculation-per-class-in-r
# https://gis.stackexchange.com/questions/433375/calculate-area-for-raster-in-r

cli::cli_h1("Land cover area routine")

# Packages
library(geobr)
library(dplyr)
library(tidyr)
library(sf)
library(terra)
library(purrr)
library(DBI)
library(duckdb)
library(cli)

# Database
con <- dbConnect(duckdb(), "land.duckdb")

# Delete table
if (dbExistsTable(con, "land_cover")) {
  dbRemoveTable(con, "land_cover")
}

# Load municipalities boundaries
geo <- read_municipality(year = 2010) |>
  st_transform(crs = 4326)

# Split to list
geo_split <- geo |>
  group_by(code_muni) |>
  group_split()

# Land cover files
land_cover_files <- tibble(
  ano = 1985:2025,
  file = sort(list.files(
    #path = "/media/raphaelsaldanha/lacie/mapbiomas/cobertura/",
    path = "/dados2/data/mapbiomas/cobertura/",
    full.names = TRUE,
    pattern = "\\.tif$"
  ))
)

# Only 2025
land_cover_files <- land_cover_files |>
  filter(ano == 2025)

# Land cover codes
land_cover_codes <- c(
  3,
  4,
  5,
  6,
  49,
  11,
  12,
  32,
  29,
  50,
  15,
  39,
  20,
  40,
  62,
  41,
  46,
  47,
  35,
  48,
  9,
  21,
  23,
  24,
  30,
  25,
  33,
  31,
  27
)

# Functions
## Compute area
code_area <- function(rst, geo, code) {
  # Crop area
  rs <- crop(rst, geo, mask = TRUE)

  # Isolate code
  rs <- ifel(rs == code, 1, NA)

  # Compute cell area
  rs <- cellSize(rs, unit = "m") * rs

  # Compute total
  res <- global(rs, "sum", na.rm = TRUE) |> unlist()
  names(res) <- NULL

  # Return
  return(res)
}

total_area <- function(rst, geo) {
  # Crop area
  rs <- crop(rst, geo, mask = TRUE)

  # Compute cell area
  rs <- cellSize(rs, unit = "m") * rs

  # Compute total
  res <- global(rs, "sum", na.rm = TRUE) |> unlist()
  names(res) <- NULL

  # Return
  return(res)
}

area_geo <- function(geo_split, year, rst, land_cover_codes, con) {
  # Compute area for each code
  tmp_area <- map_vec(
    .x = land_cover_codes,
    .f = code_area,
    rst = rst,
    geo = geo_split,
    .progress = FALSE
  )

  # Replace NAs with zero
  tmp_area <- replace_na(data = tmp_area, replace = 0)

  # Compute percentage
  total_area_value <- total_area(rst = rst, geo = geo_split)
  total_area_perc <- round(tmp_area / total_area_value * 100, 2)

  # Prepare table
  tmp_table <- tibble(
    code_muni = geo_split$code_muni,
    year = year,
    code = land_cover_codes,
    area = tmp_area,
    perc = total_area_perc
  )

  # Write to database
  dbWriteTable(
    conn = con,
    name = "land_cover",
    value = tmp_table,
    append = TRUE
  )

  return(TRUE)
}

# For each land cover year
for (y in 1:nrow(land_cover_files)) {
  # Year
  year <- land_cover_files[y, 1]

  cli_alert_info("Year {year}")

  # Read raster
  rst <- rast(land_cover_files[y, 2]$file)

  res <- map(
    .x = geo_split,
    .f = area_geo,
    year = year,
    rst = rst,
    land_cover_codes = land_cover_codes,
    con = con,
    .progress = TRUE
  )
}

# Check
tbl(con, "land_cover")

cli_alert_info("Exporting files...")
dbExecute(
  con,
  "COPY (SELECT * FROM 'land_cover') TO 'land_cover.parquet' (FORMAT 'PARQUET')"
)
dbExecute(
  con,
  "COPY (SELECT * FROM 'land_cover') TO 'land_cover.csv' (FORMAT 'CSV')"
)
cli_alert_success("Done!")


# Database disconnect
dbDisconnect(con)

cli_h1("END")

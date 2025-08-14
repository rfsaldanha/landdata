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
  ano = 1985:2023,
  file = sort(list.files(
    path = "/media/raphaelsaldanha/lacie/mapbiomas/cobertura/",
    full.names = TRUE,
    pattern = "\\.tif$"
  ))
)

# Land cover codes
land_cover_codes <- c(23, 24, 25)

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

# For each land cover year
for (y in 1:nrow(land_cover_files)) {
  # Year
  year <- land_cover_files[y, 1]

  # Read raster
  rst <- rast(land_cover_files[y, 2]$file)

  # For each municipality
  for (g in 1:length(geo_split)) {
    cli_alert_info("Year {year}, municipality {geo_split[[g]]$code_muni}")

    # Compute area for each code
    tmp_area <- map_vec(
      .x = land_cover_codes,
      .f = code_area,
      rst = rst,
      geo = geo_split[[g]],
      .progress = TRUE
    )

    # Replace NAs with zero
    tmp_area <- replace_na(data = tmp_area, replace = 0)

    # Compute percentage
    total_area_value <- total_area(rst = rst, geo = geo_split[[g]])
    total_area_perc <- round(tmp_area / total_area_value * 100, 2)

    # Prepare table
    tmp_table <- tibble(
      code_muni = geo_split[[g]]$code_muni,
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

    cli_alert_success("Done!")
  }
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

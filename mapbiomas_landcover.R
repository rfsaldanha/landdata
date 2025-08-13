# Packages
library(geobr)
library(dplyr)
library(sf)
library(terra)
library(purrr)


geo <- read_municipality(year = 2010) |>
  st_transform(crs = 4326)

teste_mun <- geo |>
  filter(code_muni == 3304557)

rst <- rast(
  "/media/raphaelsaldanha/lacie/mapbiomas/cobertura/brasil_coverage_2023.tif"
)

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

code_area(rst, teste_mun, 24)

map_vec(c(23, 24, 25), code_area, rst = rst, geo = teste_mun)

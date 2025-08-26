# Packages
library(terra)
library(geobr)
library(sf)
library(tibble)
library(stringr)
library(purrr)
library(exactextractr)
library(DBI)
library(duckdb)

# Database
con <- dbConnect(duckdb(), "land_ndvi.duckdb")

if (dbExistsTable(con, "ndvi_mean")) {
  dbRemoveTable(con, "ndvi_mean")
}
if (dbExistsTable(con, "ndvi_max")) {
  dbRemoveTable(con, "ndvi_max")
}
if (dbExistsTable(con, "ndvi_min")) {
  dbRemoveTable(con, "ndvi_min")
}
if (dbExistsTable(con, "ndvi_sd")) {
  dbRemoveTable(con, "ndvi_sd")
}

dbListTables(con)

# Folders
monthly_data_folder <- "/media/raphaelsaldanha/seagate_ext_01/ndvi_time_agg/"

# List files
files <- list.files(
  monthly_data_folder,
  full.names = TRUE,
  pattern = ".nc$"
)

# Municipalities
mun <- read_municipality(year = 2010, simplified = TRUE)
mun <- st_transform(x = mun, crs = 4326)

# Function
agg <- function(x, fun, tb_name) {
  # Read raster and project
  rst <- rast(x)
  rst <- project(x = rst, "EPSG:4326")

  # Zonal statistic computation
  tmp <- exact_extract(x = rst, y = mun, fun = fun, progress = FALSE)

  # Table output
  res <- tibble(
    code_muni = mun$code_muni,
    date = as.Date(
      x = paste0(str_sub(string = basename(x), start = 6, end = 11), "01"),
      format = "%Y%m%d"
    ),
    value = round(x = tmp, digits = 2),
  )

  # Write to database
  dbWriteTable(conn = con, name = tb_name, value = res, append = TRUE)

  return(TRUE)
}

# Compute zonal mean
res_mean <- map(
  .x = files,
  .f = agg,
  fun = "mean",
  tb_name = "ndvi_mean",
  .progress = TRUE
)

res_max <- map(
  .x = files,
  .f = agg,
  fun = "max",
  tb_name = "ndvi_max",
  .progress = TRUE
)

res_min <- map(
  .x = files,
  .f = agg,
  fun = "min",
  tb_name = "ndvi_min",
  .progress = TRUE
)

res_sd <- map(
  .x = files,
  .f = agg,
  fun = "sd",
  tb_name = "ndvi_sd",
  .progress = TRUE
)

# Export parquet file
dbExecute(
  con,
  "COPY (SELECT * FROM 'ndvi_mean') TO 'ndvi_mean.parquet' (FORMAT 'PARQUET')"
)

dbExecute(
  con,
  "COPY (SELECT * FROM 'ndvi_max') TO 'ndvi_max.parquet' (FORMAT 'PARQUET')"
)

dbExecute(
  con,
  "COPY (SELECT * FROM 'ndvi_min') TO 'ndvi_min.parquet' (FORMAT 'PARQUET')"
)

dbExecute(
  con,
  "COPY (SELECT * FROM 'ndvi_sd') TO 'ndvi_sd.parquet' (FORMAT 'PARQUET')"
)

# Export CSV file
dbExecute(
  con,
  "COPY (SELECT * FROM 'ndvi_mean') TO 'ndvi_mean.csv' (FORMAT 'CSV')"
)

dbExecute(
  con,
  "COPY (SELECT * FROM 'ndvi_max') TO 'ndvi_max.csv' (FORMAT 'CSV')"
)

dbExecute(
  con,
  "COPY (SELECT * FROM 'ndvi_min') TO 'ndvi_min.csv' (FORMAT 'CSV')"
)

dbExecute(
  con,
  "COPY (SELECT * FROM 'ndvi_sd') TO 'ndvi_sd.csv' (FORMAT 'CSV')"
)

# Database disconnect
dbDisconnect(conn = con)

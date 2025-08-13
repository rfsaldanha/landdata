# Packages
library(fs)
library(stringr)
library(tibble)
library(lubridate)
library(dplyr)
library(terra)
library(purrr)
library(DBI)
library(duckdb)

# Files path
files_path <- path("/media/raphaelsaldanha/seagate_ext_01/ndvi_2020_current/")
dest_path <- path(
  "/media/raphaelsaldanha/seagate_ext_01/ndvi_2020_current_time_agg/"
)

# Files data frame
files <- tibble(
  files = list.files(path = files_path, full.names = TRUE, pattern = "*.nc"),
  date = ymd(substr(basename(files), 15, 22)),
  year = year(date),
  month = month(date)
)

# Convert to list
files_list <- files |>
  group_by(year, month) |>
  group_split(.keep = TRUE)

for (l in 1:length(files_list)) {
  # Year and month
  year <- files_list[[l]]$year[1]
  month <- str_pad(files_list[[l]]$month[1], width = 2, pad = 0)

  dest_filename <- path(dest_path, paste0("ndvi_", year, month, ".nc"))

  # Stack rasters and select layer NDVI
  rst <- NULL
  for (f in files_list[[l]]$files) {
    tmp <- rast(f)
    tmp <- tmp$NDVI
    rst <- c(rst, tmp)
  }
  rst <- rast(rst)

  # Average
  rst_time_avg <- app(
    x = rst,
    mean,
    na.rm = TRUE,
    cores = 4
  )

  # Write
  writeCDF(x = rst_time_avg, filename = dest_filename, compression = 9)
}

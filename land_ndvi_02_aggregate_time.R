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
library(cli)

# Files path
files_path_a <- path("/media/raphaelsaldanha/seagate_ext_01/ndvi_1999_2020/")
files_path_b <- path("/media/raphaelsaldanha/seagate_ext_01/ndvi_2014_2020/")
files_path_c <- path("/media/raphaelsaldanha/seagate_ext_01/ndvi_2020_current/")

# Files data frame and remove overlaps
files_a <- tibble(
  files = list.files(path = files_path_a, full.names = TRUE, pattern = "*.nc"),
  date = ymd(substr(basename(files), 12, 19)),
  year = year(date),
  month = month(date)
) |>
  filter(date >= ymd("1999-01-01") & date <= ymd("2019-12-01"))

files_b <- tibble(
  files = list.files(path = files_path_b, full.names = TRUE, pattern = "*.nc"),
  date = ymd(substr(basename(files), 15, 22)),
  year = year(date),
  month = month(date)
) |>
  filter(date >= ymd("2020-01-01") & date <= ymd("2020-06-01"))

files_c <- tibble(
  files = list.files(path = files_path_c, full.names = TRUE, pattern = "*.nc"),
  date = ymd(substr(basename(files), 15, 22)),
  year = year(date),
  month = month(date)
) |>
  filter(date >= ymd("2020-07-01"))

files <- bind_rows(files_a, files_b, files_c)
rm(files_a, files_b, files_c)
rm(files_path_a, files_path_b, files_path_c)

# Dest path
dest_path <- path(
  "/media/raphaelsaldanha/seagate_ext_01/ndvi_time_agg/"
)

# Convert to list
files_list <- files |>
  group_by(year, month) |>
  group_split(.keep = TRUE)

for (l in 1:length(files_list)) {
  # Year and month
  year <- files_list[[l]]$year[1]
  month <- str_pad(files_list[[l]]$month[1], width = 2, pad = 0)

  cli_alert_info("Year {year} month {month}")

  dest_filename <- path(dest_path, paste0("ndvi_", year, month, ".nc"))

  if (file_exists(dest_filename)) {
    cli_alert_warning("File already exist. Going for next...")
    next
  }

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

  cli_alert_success("Done!")
}

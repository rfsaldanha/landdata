cli::cli_h1("Copernicus Land NDVI 2020-current routine")

# Packages
library(cli)
library(readr)
library(dplyr)
library(fs)
library(glue)

# Normalised Difference Vegetation Index 2020-present (raster 300 m), global, 10-daily – version 2
# https://land.copernicus.eu/en/products/vegetation/normalised-difference-vegetation-index-v2-0-300m#download

cli_alert_info("Retrieving files list...")
# Files list
files_list <- read_csv2(
  "https://s3.waw3-1.cloudferro.com/swift/v1/CatalogueCSV/bio-geophysical/vegetation_indices/ndvi_global_300m_10daily_v2/ndvi_global_300m_10daily_v2_nc.csv"
) |>
  select(name, s3_path)
cli_alert_success("Done!")

# Destination path
dest_path <- path("/media/raphaelsaldanha/seagate_ext_01/ndvi_2020_current/")

# Download files
# This section uses the system tool s3cmd with a config file (.s3cfg) with credentials
cli_alert_info("Starting sequential download...")
for (i in 1:nrow(files_list)) {
  # File name and uri
  file_name <- gsub(
    pattern = "_nc",
    x = files_list[[i, 1]],
    replacement = ".nc"
  )
  base_uri <- files_list[[i, 2]]
  uri <- paste0(base_uri, "/", file_name)

  cli_inform(file_name)

  # Destination
  download_path <- path(dest_path, file_name)

  # Skip if exist
  if (file.exists(download_path)) {
    cli_alert_warning("File already exists. Going for next.")
    next
  }

  # Download
  system(glue("s3cmd -c ~/.s3cfg get {uri} --force --progress"))

  # Move to destination
  fs::file_move(path = file_name, new_path = dest_path)
}
cli_alert_success("Done!")
cli_h1("END")

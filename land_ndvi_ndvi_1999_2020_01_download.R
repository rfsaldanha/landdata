cli::cli_h1("Copernicus Land NDVI 1999-2020 routine")

# Packages
library(readr)
library(curl)
library(fs)
library(cli)

# Normalised Difference Vegetation Index 1999-2020 (raster 1 km), global, 10-daily – version 3
# https://land.copernicus.eu/en/products/vegetation/normalised-difference-vegetation-index-v3-0-1km#download

cli_alert_info("Retrieving files list...")
# Files list
files <- read_lines(
  "https://globalland.vito.be/download/manifest/ndvi_1km_v3_10daily_netcdf/manifest_clms_global_ndvi_1km_v3_10daily_netcdf_latest.txt"
)
cli_alert_success("Done!")

# Destination path
dest_path <- path("/media/raphaelsaldanha/seagate_ext_01/ndvi_1999_2020/")

# Download files
cli_alert_info("Starting sequential download...")
for (f in files) {
  cli_inform(f)

  # Dest file
  download_path <- path(
    dest_path,
    basename(f)
  )

  # Skip if exist
  if (file.exists(download_path)) {
    cli_alert_warning("File already exists. Going for next.")
    next
  }

  curl_download(url = f, destfile = download_path, quiet = FALSE)
}
cli_alert_success("Done!")

cli_h1("END")

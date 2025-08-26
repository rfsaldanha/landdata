cli::cli_h1("Copernicus Land NDVI 2020-current routine")

# Packages
library(readr)
library(curl)
library(fs)
library(cli)

# Normalised Difference Vegetation Index 2020-present (raster 300 m), global, 10-daily – version 2
# https://land.copernicus.eu/en/products/vegetation/normalised-difference-vegetation-index-v2-0-300m#download

cli_alert_info("Retrieving files list...")
# Files list
files <- read_lines(
  "https://globalland.vito.be/download/manifest/ndvi_300m_v2_10daily_netcdf/manifest_clms_global_ndvi_300m_v2_10daily_netcdf_latest.txt"
)
cli_alert_success("Done!")

# Destination path
dest_path <- path("/media/raphaelsaldanha/seagate_ext_01/ndvi_2020_current/")

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

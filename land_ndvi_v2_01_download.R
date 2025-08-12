# Packages
library(readr)
library(curl)
library(fs)

# Normalised Difference Vegetation Index 2020-present (raster 300 m), global, 10-daily – version 2
# https://land.copernicus.eu/en/products/vegetation/normalised-difference-vegetation-index-v2-0-300m#download

# Files list
files <- read_lines(
  "https://globalland.vito.be/download/manifest/ndvi_300m_v2_10daily_netcdf/manifest_clms_global_ndvi_300m_v2_10daily_netcdf_latest.txt"
)

# Dest files
file_names <- basename(files)
download_path <- path(
  "/media/raphaelsaldanha/seagate_ext_01/ndvi_v2/",
  file_names
)

# Download files
multi_download(
  urls = files,
  destfiles = download_path,
  progress = TRUE
)

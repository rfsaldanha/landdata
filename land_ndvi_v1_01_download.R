# Packages
library(readr)
library(curl)
library(fs)

# Normalised Difference Vegetation Index 2014-2020 (raster 300 m), global, 10-daily – version 1
# https://land.copernicus.eu/en/products/vegetation/normalized-difference-vegetation-index-300m-v1.0#download

# Files list
files <- read_lines(
  "https://globalland.vito.be/download/manifest/ndvi_300m_v1_10daily_netcdf/manifest_clms_global_ndvi_300m_v1_10daily_netcdf_latest.txt"
)

# Dest files
file_names <- basename(files)
download_path <- path(
  "/media/raphaelsaldanha/seagate_ext_01/ndvi_v1/",
  file_names
)

# Download files
multi_download(
  urls = files,
  destfiles = download_path,
  progress = TRUE
)

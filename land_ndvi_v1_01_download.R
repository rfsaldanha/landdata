# Packages
library(readr)
library(curl)
library(fs)

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
  urls = files[1:5],
  destfiles = download_path[1:5],
  progress = TRUE
)

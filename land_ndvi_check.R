# Packages
library(dplyr)
library(lubridate)
library(DBI)
library(duckdb)
library(ggplot2)

# Database
con <- dbConnect(duckdb(), "land_ndvi.duckdb")

dbListTables(con)

tbl(con, "ndvi_mean") |>
  filter(code_muni == 1502103) |>
  ggplot(aes(x = date, y = value)) +
  geom_line() +
  ylim(0, 1)

tbl(con, "ndvi_mean") |>
  filter(code_muni == 2510808) |>
  ggplot(aes(x = date, y = value)) +
  geom_line() +
  ylim(0, 1)

tbl(con, "ndvi_mean") |>
  filter(code_muni == 2510808) |>
  arrange(date) |>
  collect() |>
  View()

dbDisconnect(conn = con)

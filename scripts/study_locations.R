library(sf)
library(tidyverse)

d <- read_delim("data/transect_UTM33_start.txt", delim = "\t")

d <- d %>% st_as_sf(coords = c("Longitude","Latitude"), crs = 32633)

d %>% st_write("data/transect_UTM33_start.gpkg")

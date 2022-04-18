library(sf)
library(tidyverse)

d <- read_delim("data/transect_UTM33_start.txt", delim = "\t")

d <- d %>% st_as_sf(coords = c("Longitude","Latitude"), crs = 32633)

# d %>% st_write("data/transect_UTM33_start.gpkg")

bb <- d %>% st_bbox() + c(-10000,-10000,10000,1000)
aoi <- bb %>% 
  st_as_sfc() %>% 
  st_as_sf()

aoi %>% st_write("data/aoi.gpkg")

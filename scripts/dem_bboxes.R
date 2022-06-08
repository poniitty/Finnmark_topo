library(raster)
library(tidyverse)
library(sf)

f <- list.files("/scratch/project_2003061/finnmark_dems",
                pattern = ".tif$", full.names = T)

for(i in f){
  
  r <- raster(i)
  
  bb <- st_bbox(r) %>% 
    st_as_sfc() %>% 
    st_as_sf() %>% 
    mutate(raster = i)
  
  if(i == f[1]){
    all <- bb
  } else {
    all <- bind_rows(all, bb)
  }
  
}

all %>% st_write("data/dem_bboxes.gpkg")

library(terra)
library(tidyverse)
library(sf)

setwd("/scratch/project_2003061/finnmark_dems/")

if(!dir.exists("output")){
  dir.create("output")
}

vars <- unique(unlist(lapply(list.files("pisr/", pattern = "tif$"), function(x) str_split(x, "_")[[1]][1])))

for(i in vars){
  print(i)
  # i <- "pisr"
  f <- list.files("pisr", pattern = paste0(i,"_"), full.names = T)
  
  for(ii in f){
    
    r <- raster::raster(ii)
    
    bb <- st_bbox(r) %>% 
      st_as_sfc() %>% 
      st_as_sf() %>% 
      mutate(raster = ii)
    
    if(ii == f[1]){
      all <- bb
    } else {
      all <- bind_rows(all, bb)
    }
    
  }
  
  aoi <- st_read("/projappl/project_2003061/repos/Finnmark_topo/data/aoi.gpkg") %>% 
    st_as_sf()
  
  grid_cells <- st_make_grid(aoi, n = 3) %>% 
    st_as_sf() %>% 
    mutate(id = 1:nrow(.))
  
  for(ii in grid_cells$id){
    
    temp_aoi <- grid_cells %>% filter(id == ii) %>% 
      st_transform(crs = st_crs(all))
    
    bboxes <- all[temp_aoi,]
    
    f2 <- bboxes$raster
    
    rast.list <- list()
    for(iii in 1:length(f2)) { rast.list[iii] <- rast(f2[iii]) }
    rsrc <- terra::src(rast.list)
    rast.mosaic <- mosaic(rsrc, fun = "mean")
    
    writeRaster(round(rast.mosaic), paste0("output/",i,"_",ii,".tif"),
                datatype = "INT2U", overwrite = T)
    
    unlink(list.files(tempdir(), full.names = T))
  }
  
}

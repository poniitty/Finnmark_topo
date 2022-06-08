library(sf)
library(tidyverse)
library(foreach)
library(doMPI)

setwd("/projappl/project_2003061/repos/Finnmark_topo")

aoi <- st_read("data/aoi.gpkg") %>% 
  st_as_sf()

dem_bboxes <- st_read("data/dem_bboxes.gpkg") %>% 
  st_set_crs(st_crs(aoi))

grid_cells <- st_make_grid(aoi, cellsize = 10000) %>% 
  st_as_sf() %>% 
  mutate(id = 1:nrow(.))

cl <- startMPIcluster()
registerDoMPI(cl)

foreach(i = grid_cells$id) %dopar% {
  # i <- 2
  library(sf)
  library(tidyverse)
  library(terra)
  library(Rsagacmd, lib.loc = "/projappl/project_2003061/Rpackages/")
  
  saga <- saga_gis(cores = 1)
  
  temp_aoi <- grid_cells %>% filter(id == i) %>% 
    st_bbox() + c(-5000,-5000,5000,5000)
  
  temp_aoi <- temp_aoi %>% 
    st_as_sfc() %>% 
    st_as_sf()
  
  bboxes <- dem_bboxes[temp_aoi,]
  
  if(nrow(bboxes) > 0){
    
    rl <- lapply(bboxes$raster, rast)
    rl <- src(rl)
    
    r <- mosaic(rl)
    r <- crop(r, temp_aoi)
    
    dem_filled <- saga$ta_preprocessor$fill_sinks_xxl_wang_liu(elev = r, minslope = 0.01)
    
    swi <- saga$ta_hydrology$saga_wetness_index(dem = dem_filled, area_type = 2, slope_type = 0)
    
    temp_aoi <- grid_cells %>% filter(id == i) %>% 
      st_bbox() + c(-100,-100,100,100)
    
    temp_aoi <- temp_aoi %>% 
      st_as_sfc() %>% 
      st_as_sf()
    
    swi$twi <- crop(swi$twi, temp_aoi, snap = "out")
    
    writeRaster(rast(round(swi$twi*100)), 
                paste0("/scratch/project_2003061/finnmark_dems/twi/twi_", i,".tif"), 
                filetype = "GTiff", overwrite = T, datatype = "INT2S")
    
  }
  
  saga_remove_tmpfiles(h = 0.30)
  
}

closeCluster(cl)
mpi.quit()

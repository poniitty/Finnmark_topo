library(sf)
library(tidyverse)
library(foreach)
library(doMPI)
# devtools::install_github("stevenpawley/Rsagacmd", lib = "/projappl/project_2003061/Rpackages/")

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
  
  if(!file.exists(paste0("/scratch/project_2003061/finnmark_dems/tpi100/tpi100", i,".tif"))){
    
    temp_aoi <- grid_cells %>% filter(id == i) %>% 
      st_bbox() + c(-10,-10,10,10)
    
    temp_aoi <- temp_aoi %>% 
      st_as_sfc() %>% 
      st_as_sf()
    
    bboxes <- dem_bboxes[temp_aoi,]
    
    if(nrow(bboxes) > 0){
      
      saga <- saga_gis(cores = 1)
      
      temp_aoi2 <- grid_cells %>% filter(id == i) %>% 
        st_bbox() + c(-100,-100,100,100)
      
      temp_aoi2 <- temp_aoi2 %>% 
        st_as_sfc() %>% 
        st_as_sf()
      
      bboxes <- dem_bboxes[temp_aoi2,]
      
      rl <- lapply(bboxes$raster, rast)
      rl <- src(rl)
      
      r <- mosaic(rl)
      r <- crop(r, temp_aoi2)
      
      tpi <- saga$ta_morphometry$topographic_position_index_tpi(raster::raster(r), radius_max = 100)
      
      tpi <- crop(tpi, temp_aoi, snap = "out")
      # plot(r)
      # plot(st_geometry(temp_aoi), add = T)
      writeRaster(rast(round(tpi*10)), 
                  paste0("/scratch/project_2003061/finnmark_dems/tpi100/tpi100_", i,".tif"), 
                  filetype = "GTiff", overwrite = T, datatype = "INT2S")
      plot(rast(round(tpi*10)))
      saga_remove_tmpfiles(h = 0.10)
      
    }
  }
}

closeCluster(cl)
mpi.quit()

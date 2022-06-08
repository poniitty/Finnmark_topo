library(sf)
library(tidyverse)
library(terra)
library(Rsagacmd, lib.loc = "/projappl/project_2003061/Rpackages/")

saga <- saga_gis(cores = 8)

setwd("/projappl/project_2003061/repos/Finnmark_topo")

aoi <- st_read("data/aoi.gpkg") %>% 
  st_as_sf()

dem_bboxes <- st_read("data/dem_bboxes.gpkg") %>% 
  st_set_crs(st_crs(aoi))

grid_cells <- st_make_grid(aoi, cellsize = 10000) %>% 
  st_as_sf() %>% 
  mutate(id = 1:nrow(.))

for(i in grid_cells$id){
  # i <- 2
  
  if(!file.exists(paste0("/scratch/project_2003061/finnmark_dems/pisr/pisr_", i,".tif"))){
    
    temp_aoi <- grid_cells %>% filter(id == i) %>% 
      st_bbox() + c(-100,-100,100,100)
    
    temp_aoi <- temp_aoi %>% 
      st_as_sfc() %>% 
      st_as_sf()
    
    bboxes <- dem_bboxes[temp_aoi,]
    
    if(nrow(bboxes) > 0){
      
      print(i)
      
      temp_aoi2 <- grid_cells %>% filter(id == i) %>% 
        st_bbox() + c(-5000,-5000,5000,5000)
      
      temp_aoi2 <- temp_aoi2 %>% 
        st_as_sfc() %>% 
        st_as_sf()
      
      bboxes <- dem_bboxes[temp_aoi2,]
      
      rl <- lapply(bboxes$raster, rast)
      rl <- src(rl)
      
      r <- mosaic(rl)
      r <- crop(r, temp_aoi2)
      
      lat <- st_coordinates(st_transform(st_centroid(st_as_sf(st_as_sfc(st_bbox(raster::raster(r))))),4326))[1,"Y"]
      
      svf <- saga$ta_lighting$sky_view_factor(dem = r, ndirs = 8, radius = 5000)
      
      pisr <- saga$ta_lighting$potential_incoming_solar_radiation(grd_dem = r,
                                                                  grd_svf = svf$svf,
                                                                  latitude = lat,
                                                                  period = 2, 
                                                                  days_step = 15,
                                                                  day = "2021-06-01", 
                                                                  day_stop = "2021-08-31",
                                                                  hour_step = 1)
      
      pisr$grd_total <- crop(pisr$grd_total, temp_aoi, snap = "out")
      # plot(r)
      # plot(st_geometry(temp_aoi), add = T)
      writeRaster(rast(round(pisr$grd_total*10)), 
                  paste0("/scratch/project_2003061/finnmark_dems/pisr/pisr_", i,".tif"), 
                  filetype = "GTiff", overwrite = T, datatype = "INT2U")
      
      saga_remove_tmpfiles(h = 0.30)
      
    }
  }
  
}


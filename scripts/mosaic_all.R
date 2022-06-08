library(terra)
library(tidyverse)
library(sf)

setwd("/scratch/project_2003061/finnmark_dems/")

if(!dir.exists("output")){
  dir.create("output")
}

vars <- unique(unlist(lapply(list.files("output/", pattern = "tif$"), function(x) str_split(x, "_")[[1]][1])))

for(i in vars){
  print(i)
  # i <- "tpi100"
  f <- list.files("output", pattern = paste0(i,"_"), full.names = T)
  
  rast.list <- list()
  for(iii in 1:length(f)) { 
    rast.list[iii] <- rast(f[iii])
  }
  rsrc <- terra::src(rast.list)
  rast.mosaic <- mosaic(rsrc, fun = "mean")
  
  writeRaster(round(rast.mosaic), paste0("output/",i,".tif"),
              datatype = ifelse(rast.mosaic@ptr$range_min < 0, "INT2S", "INT2U"), 
              overwrite = T)
  
  unlink(list.files(tempdir(), full.names = T))
  
}

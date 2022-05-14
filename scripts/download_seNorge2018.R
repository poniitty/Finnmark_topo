library(tidyverse)


years <- c(2013:2018)

tg_urls <- paste0("https://thredds.met.no/thredds/fileServer/Northern_Forest/seNorge_2018_northernforest_tile2/TG/seNorge2018_northernforest_tile2_TG_",
                  years,
                  ".nc")

tg_folder <- "/scratch/project_2003061/finnmark_climate/TG/"

# dir.create("/scratch/project_2003061/finnmark_climate")
# dir.create("/scratch/project_2003061/finnmark_climate/TG")

for(i in tg_urls){
  
  print(i)
  
  file_name <- tail(strsplit(i, "/")[[1]],1)
  
  download.file(url = i,
                destfile = paste0(tg_folder, file_name), 
                method = "curl")
  
}

# Precip

rr_urls <- paste0("https://thredds.met.no/thredds/fileServer/Northern_Forest/seNorge_2018_northernforest_tile2/RR/seNorge2018_northernforest_tile2_RR_",
                  years,
                  ".nc")

rr_folder <- "/scratch/project_2003061/finnmark_climate/RR/"

# dir.create("/scratch/project_2003061/finnmark_climate/RR")

for(i in rr_urls){
  
  print(i)
  
  file_name <- tail(strsplit(i, "/")[[1]],1)
  
  download.file(url = i,
                destfile = paste0(rr_folder, file_name), 
                method = "curl")
  
}


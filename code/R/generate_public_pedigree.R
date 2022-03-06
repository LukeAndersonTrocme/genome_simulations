# load library
library(dplyr)
library(data.table)
# load function
source("maximum_genealogical_depth.R")
# load lon lat coordinates
locations <- fread("location_key.csv") %>% dplyr::rename(lieum = lieu)
# load pedigree
pedigree <- fread("tout_balsac.csv") %>% left_join(locations, by ="lieum")

# individuals who married between 1890 and 1920
time_slice <- pedigree %>% filter(datem > 1890 & datem < 1920) 
# remove parents to keep a single generation
probands <- time_slice %>% filter(!ind %in% c(time_slice$mother, time_slice$father))
# create single list of IDs
list_of_probands <- probands %>% pull(ind)

# climb tree and keep track of maximum generation relative to probands
ascending_pedigree <- maximum_genealogical_depth(pedigree, list_of_probands)
# select columns of interest
out <- ascending_pedigree %>% dplyr::select(ind, mother, father, generation, lon, lat, datem)

# write output file
fwrite(out, file = "public_ascending_pedigree_1890-1920_space_time.txt")
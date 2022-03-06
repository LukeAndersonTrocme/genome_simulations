# load library
library(dplyr)
library(data.table)
# load function
source("maximum_genealogical_depth.R")
# load lon lat coordinates
locations <- fread("../misc/watershed_locations_feb2022.csv") %>% dplyr::rename(lieum = lieu)
# load pedigree
pedigree <- fread("tout_balsac.csv") %>% left_join(locations, by ="lieum")

# individuals who married between since 1920
time_slice <- pedigree %>% filter(datem > 1920) 
# remove parents to keep a single generation
probands <- time_slice %>% filter(!ind %in% c(time_slice$mother, time_slice$father),
                                  min_wts_name == "Lac Saint-Jean")
# create single list of IDs
list_of_probands <- probands %>% pull(ind)

# climb tree and keep track of maximum generation relative to probands
ascending_pedigree <- maximum_genealogical_depth(pedigree, list_of_probands)
# select columns of interest
out <- ascending_pedigree %>% dplyr::select(ind, mother, father, generation)

# write output file
fwrite(out, file = "lac_saint_jean_ascending_pedigree.txt")

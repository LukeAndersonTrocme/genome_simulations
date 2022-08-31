#setwd("/Users/luke/Documents/genome_simulations/code/R")
# load library
library(dplyr)
library(data.table)
# load function
source("maximum_genealogical_depth.R")
# load function
source("get_extended_family.R")

# load lon lat coordinates
locations <- fread("../../misc/watershed_locations_feb2022.csv") %>% dplyr::rename(lieum = lieu)
# load pedigree
raw_pedigree <- fread("/Users/luke/Documents/Genizon/BALSAC/Balsac_aout_2021_v2/tout_balsac.csv")%>% left_join(locations, by ="lieum")

probands <- raw_pedigree %>% 
  filter(!ind %in% father,
         !ind %in% mother,
         !is.na(datem),
         datem > 1900)

three_col_ped <- pedigree %>% select(ind, mother, father)

extended_families <- get_extended_family(three_col_ped, probands$ind)
relatives <- c("mother","father","grand_mother.mom","grand_father.mom","grand_mother.dad","grand_father.dad")
# count number of missing ancestors
extended_families$n_in <- rowSums( !is.na( select(extended_families, all_of(relatives))))
# keep track of individuals who are missing grand-parents
missing_grand_parents <- extended_families %>% filter(n_in<6) %>% pull(ind)
# NOTE: there are 311545 individuals removed

# create single list of IDs
list_of_probands <- probands %>% filter(!ind %in% missing_grand_parents) %>% pull(ind)
# NOTE: there are 1426749 probands included

for( loc in unique(locations$lieum) ){
  subset_of_probands <-
    raw_pedigree %>%
    filter(ind %in% list_of_probands,
           lieum == loc) %>% pull(ind)
  
  if(length(subset_of_probands) < 100){next}
  print(paste("town",loc,"size",length(subset_of_probands)))
  
  # climb tree and keep track of maximum generation relative to probands
  ascending_pedigree <- maximum_genealogical_depth(pedigree, subset_of_probands)
  # select columns of interest
  out <- ascending_pedigree %>% dplyr::select(ind, mother, father, generation)
  
  # write output file
  fwrite(out, file = paste0("town_pedigree/ascending_pedigree_",loc,".txt"))
  
}


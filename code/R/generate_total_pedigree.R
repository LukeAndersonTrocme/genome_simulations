#setwd("/Users/luke/Documents/genome_simulations/code/R")
# load library
library(dplyr)
library(data.table)
# load function
source("maximum_genealogical_depth.R")
# load function
source("get_extended_family.R")

# load pedigree
raw_pedigree <- fread("/Users/luke/Documents/Genizon/BALSAC/Balsac_aout_2021_v2/tout_balsac.csv")
locations <- fread("/Users/luke/Documents/genome_simulations/misc/location_key.csv") %>% dplyr::rename(lieum = lieu)

pedigree <- left_join(raw_pedigree, locations, by = "lieum")
pedigree$decade <- pedigree$datem - pedigree$datem %% 10

probands <- pedigree %>% 
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

# climb tree and keep track of maximum generation relative to probands
ascending_pedigree <- maximum_genealogical_depth(pedigree, list_of_probands)
# select columns of interest
out <- ascending_pedigree %>% dplyr::select(ind, mother, father, generation, lon, lat, sex, decade, lieum)

# write output file
fwrite(out, file = "revised_ascending_pedigree.txt")
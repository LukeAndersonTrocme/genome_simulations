# load library
library(dplyr)
library(data.table)
# load function
setwd("/Users/luke/Documents/genome_simulations/code/R/")
source("maximum_genealogical_depth.R")
source("get_extended_family.R")
# set random seed for reproducibility
set.seed(456)

# load lon lat coordinates
locations <- fread("../../misc/watershed_locations_feb2022.csv") %>% dplyr::rename(lieum = lieu)
# load pedigree
pedigree <- fread("../tout_balsac.csv") %>% left_join(locations, by ="lieum")

# individuals who married between since 1920
time_slice <- pedigree %>% filter(datem > 1920) 
# remove parents to keep a single generation
probands <- time_slice %>% filter(!ind %in% c(time_slice$mother, time_slice$father),
                                  min_wts_name == "Lac Saint-Jean")


# three columns for extended family function
three_col_ped <- pedigree %>% select(ind, mother, father)

# get the grand parents for each individual
extended_families <- get_extended_family(three_col_ped, probands$ind) %>%
  dplyr::select(ind, grand_mother.mom, grand_father.mom, grand_mother.dad, grand_father.dad) 

# get both sets of grand parents
maternal_grand_parents <- extended_families %>% dplyr::select(ind, grand_mother.mom, grand_father.mom) %>% rename_with(~stringr::str_remove(., '.mom'))
paternal_grand_parents <- extended_families %>% dplyr::select(ind, grand_mother.dad, grand_father.dad) %>% rename_with(~stringr::str_remove(., '.dad'))

# create single list of IDs
list_of_probands  <- 
  # bind both sets of grand parents
  bind_rows(maternal_grand_parents, 
            paternal_grand_parents) %>% 
  # remove missing data
  filter(complete.cases(.)) %>% 
  # for each set of grand parents
  group_by(grand_mother, grand_father) %>% 
  # choose one grand child
  slice_sample(n=1) %>%
  # avoid duplicate individuals (chosen from both sets of gp)
  distinct(ind) %>%
  pull(ind)

# climb tree and keep track of maximum generation relative to probands
ascending_pedigree <- maximum_genealogical_depth(pedigree, list_of_probands)
# select columns of interest
out <- ascending_pedigree %>% dplyr::select(ind, mother, father, generation)

# write output file
fwrite(out, file = "lac_saint_jean_ascending_pedigree_no_cousins.txt")

# write output file
fwrite(as.data.frame(list_of_probands), file = "lac_saint_jean_ascending_pedigree_no_cousins_probands.txt")

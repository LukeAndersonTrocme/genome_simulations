#setwd("/Users/luke/Documents/genome_simulations/")

# load library
library(dplyr)
library(data.table)

# load function
source("code/R/maximum_genealogical_depth.R")

# load pedigree
pedigree <- fread("quick_start/pedigrees/sample_pedigree.csv")

# identify probands
probands <- pedigree %>% filter(!ind %in% father, !ind %in% mother) %>%  pull(ind)

# climb tree and keep track of maximum generation relative to probands
ascending_pedigree <- maximum_genealogical_depth(pedigree, probands)

# select columns of interest
out <- ascending_pedigree %>% dplyr::select(ind, mother, father, generation)

# write output file
fwrite(out, file = "quick_start/pedigrees/ascending_sample_pedigree.txt")
import os
import pandas as pd
import numpy as np
import msprime


chromosome = 22
out_file = "./test_run_chr%s.ts" % chromosome
# define appropriate mutation rate
mutation_rate = 2.36e-8 # From Gutenkunst 2009
# define appropriate demography model
demography = msprime.Demography._ooa_model()

# recombination map from stdpopsim
# https://stdpopsim.s3-us-west-2.amazonaws.com/genetic_maps/HomSap/HapmapII_GRCh37_RecombinationHotspots.tar.gz
fn = "./genetic_map_GRCh37_chr%s.txt" % chromosome
map = pd.read_csv(fn, sep = "\t", nrows = 5)

pos = map.loc[:,"Position(bp)"].values
pos = np.insert(pos, 0, 0) # add start position
rate = map.loc[:,"Map(cM)"].values
# make custom rate map
rate_map = msprime.RateMap(position=pos, rate=rate)

# initialize msprime pedigree


labaie_str = "./test_genealogy.txt"
source_pop_id = "CEU"  # population ID of founders


pedigree = balsac_tools.read_balsac_file(labaie_str, "CEU", pop_id=0, )

assert
assert
assert
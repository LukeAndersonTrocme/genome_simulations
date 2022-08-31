import os
import argparse
import sys
import pandas as pd
import numpy as np
import msprime
import demes
import pedigree_tools

def main(args):
    # input pedigree file name
    pedigree_file_name = '{}/{}.txt'.format(args.dir, args.pedigree_name)
    # load input pedigree
    txt_ped = pedigree_tools.load_and_verify_pedigree(pedigree_file_name)

    # Two population out-of-Africa
    # demography model from Tennessen et al., 2012
    yaml_file = '{}/../maps/Tennessen_ooa_2T12.yaml'.format(args.dir)
    graph = demes.load(yaml_file)
    ooa_2T12 = msprime.Demography.from_demes(graph)
    # define recombination map file name from stdpopsim
    map_file_name = '{}/../maps/genetic_map_GRCh37_chr{}.txt'.format(args.dir, args.chromosome)
    map = msprime.intervals.RateMap.read_hapmap(map_file_name)
    # identify centromere
    centromeres=pd.read_csv('{}/../maps/centromeres.csv'.format(args.dir))
    centromere_intervals=centromeres.loc[centromeres['chrom'] == str(args.chromosome),["start","end"]].values
    # get chromosome length
    # from https://www.ncbi.nlm.nih.gov/grc/human/data?asm=GRCh37
    chromosome_length=pd.read_csv('{}/../maps/GRCh37_chromosome_length.csv'.format(args.dir))
    assembly_len=chromosome_length.loc[chromosome_length['chrom'] == str(args.chromosome),["length_bp"]].values
    # sequence_length from map fileq:
    len =  map.right.max()

    print('pedigree: {}, chromosome: {}, length: {}, mutation_rate: {}, censor: {}'.format(
          args.pedigree_name, args.chromosome, len, args.mut_rate, args.censor))

    # run genome simulations
    ts = pedigree_tools.simulate_genomes_with_known_pedigree(
         text_pedigree = txt_ped,
         demography = ooa_2T12,
         model = 'hudson',
         mutation_rate = args.mut_rate,
         rate_map = map,
         sequence_length = len,
         sequence_length_from_assembly = assembly_len,
         centromere_intervals = centromere_intervals,
         censor = args.censor,
         seed = args.chromosome + args.seed_offset
         )

    # run some basic sanity checks
    pedigree_tools.simulation_sanity_checks(ts, txt_ped)

    # write output tree sequence
    out = '{}/{}_{}_{}.ts'.format(
           args.out, args.pedigree_name, args.chromosome, args.suffix)
    ts.dump(out)

    print('output: ', out)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    # required arguments
    parser.add_argument("-d", "--dir",
        help="directory of input text pedigree"
        )
    parser.add_argument("-o", "--out",
        help="directory of output files"
        )
    parser.add_argument("-ped", "--pedigree_name",
        help="name of input text pedigree (no file extention)"
        )
    # optional arguments
    parser.add_argument("-sfx", "--suffix",
        default="sim",
        help="output file suffix"
        )
    parser.add_argument("-censor", "--censor",
        action="store_true",
        help="removes pedigree information from tree sequence"
        )
    parser.add_argument("-chr", "--chromosome",
        type=int,
        help="specify chromosome number to be simulated"
        )
    parser.add_argument("-m", "--mut_rate",
        default=3.62e-8,
        type=float,
        help="specify mutation rate"
        )
    parser.add_argument("-seed", "--seed_offset",
        default=0,
        type=int,
        help="specify random seed"
        )
    args = parser.parse_args()

    main(args)

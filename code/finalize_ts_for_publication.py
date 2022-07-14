import os
import pandas as pd
import numpy as np
import msprime
import tszip
import pedigree_tools

def main(args):

    # load input tree sequence
    ts = tskit.load(args.input)

    ts = pedigree_tools.clean_pedigree_for_publication(ts)

    # compress tree
    tszip.compress(ts, args.output)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    # required arguments
    parser.add_argument("-i", "--input",
        help="name of input tree sequence"
        )
    parser.add_argument("-o", "--output",
        help="name of output tree sequence"
        )
    # optional arguments
    parser.add_argument("-seed", "--seed_offset",
        default=0,
        type=int,
        help="specify random seed"
        )
    args = parser.parse_args()

    main(args)

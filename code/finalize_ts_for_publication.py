import os
import argparse
import sys
import pandas as pd
import numpy as np
import msprime
import tskit
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

    args = parser.parse_args()

    main(args)

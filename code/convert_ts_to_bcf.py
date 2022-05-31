import os
import argparse
import subprocess
import numpy as np
import tempfile

import tskit


class Runner:
    def __init__(self, args):
        self.test = args.test
        self.verbose = args.verbose or args.test

    def run(self, cmd):
        prefix = "Running:"
        if self.test:
            prefix = "Testing:"

        if self.verbose:
            print(prefix, cmd)

        if not self.test:
            subprocess.run(cmd, shell=True, check=True)


def ts_to_bcf_single(
    ts_file,
    out_file,
    runner,
    af_cutoff=0,
    contig_id=1,
    keep_sample_id=True,
    remove_singletons=False,
    use_vcf=False,
):

    ts = tskit.load(ts_file)
    if ts.num_individuals == 0:
        bcf_cmd = "tskit vcf --ploidy 2 {} | bcftools view -O b > {}".format(
            ts_file, out_file
        )
        runner.run(bcf_cmd)
    else:
        # remove sites based on allele frequency cutoff
        sample_nodes = ts.samples()

        if (af_cutoff != 0) or remove_singletons:
            sites_to_delete = []
            for tree in ts.trees():
                for mutation in tree.mutations():
                    # should this be count-1 since the node itself is included?
                    count = tree.num_samples(mutation.node)
                    # note that this is non-polarized frequency ( > 50% possible)
                    if (count / len(sample_nodes)) < af_cutoff:
                        sites_to_delete.append(mutation.site)
                    if remove_singletons and count == 1:
                        sites_to_delete.append(mutation.site)

            # bulk-remove sites
            tables = ts.dump_tables()
            tables.delete_sites(sites_to_delete, record_provenance=False)
            ts = tables.tree_sequence()

        sample_individuals = []
        for ind in ts.individuals():
            if len(ind.nodes) == 0:
                continue
            # diploid - two nodes, both the same individual
            if ind.nodes[0] in sample_nodes:
                assert len(ind.nodes) == 2
                assert ind.nodes[1] in sample_nodes
                sample_individuals.append(ind)

        sample_ids = [ind.id for ind in sample_individuals]

        if keep_sample_id :
            sample_names = [
                str(ind.metadata["individual_name"]) for ind in sample_individuals
                ]
        else:
            try:
                sample_names = [
                    str(ind.metadata["new_id"]) for ind in sample_individuals
                    ]
            except ValueError:
                print("ValueError: reverting to sample_names = [str(n) for n in sample_ids]")
                sample_names = [str(n) for n in sample_ids]

        read_fd, write_fd = os.pipe()
        write_pipe = os.fdopen(write_fd, "w")
        with open(out_file, "w") as f:
            output_format = "v" if use_vcf else "b"
            proc = subprocess.Popen(
                ["bcftools", "view", "-O", output_format], stdin=read_fd, stdout=f
            )
            ts.write_vcf(
                write_pipe,
                individuals=sample_ids,
                individual_names=sample_names,
                contig_id=contig_id
            )
            write_pipe.close()
            os.close(read_fd)
            proc.wait()
            if proc.returncode != 0:
                raise RuntimeError("bcftools failed with status:", proc.returncode)


def main(args):

    filename_suffix = "vcf" if args.use_vcf else "bcf"
    out_bcf_file = os.path.join(args.out_dir, args.file_name + "." + filename_suffix)
    runner = Runner(args)

    ts_to_bcf_single(
        args.ts_file,
        out_bcf_file,
        runner,
        keep_sample_id=args.keep_sample_id,
        af_cutoff=args.af_cutoff,
        contig_id=args.contig_id,
        remove_singletons=args.remove_singletons,
        use_vcf=args.use_vcf,
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i",
        "--ts_file",
        required=True,
        help="input tree sequence")
    parser.add_argument(
        "-o",
        "--out_dir",
        required=True,
        help="output directory")
    parser.add_argument(
        "-c",
        "--contig_id",
        required=True,
        help="contig id (chromosome name)")
    parser.add_argument(
        "-n",
        "--file_name",
        required=True,
        help="output file name")
    parser.add_argument(
        "-rename",
        "--keep_sample_id",
        action="store_false",
        help="Censor by renaming sample IDs. Default - False",
    )
    parser.add_argument(
        "-f",
        "--af_cutoff",
        type=float,
        default=0,
        help="Drop sites below this allele frequency cutoff. Default - 0",
    )
    parser.add_argument(
        "-r",
        "--remove-singletons",
        action="store_true",
        help="Drop sites with a single mutation",
    )
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("-vcf", "--use-vcf", action="store_true")
    parser.add_argument("-T", "--test", action="store_true")

    args = parser.parse_args()

    main(args)

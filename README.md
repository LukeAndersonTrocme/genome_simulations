# Pedigree aware genome simulations

This repository contains scripts that run msprime genome simulations based on a input text pedigree. `tskit` and `msprime` provide extensive [documentation](https://tskit.dev/msprime/docs/latest/api.html#msprime.sim_ancestry) about these simulations. New to this? A good starting point is the msprime [introduction](https://tskit.dev/msprime/docs/stable/intro.html). 

## Scripts in this repository
### Python
These python files are what interact directly with the `msprime` and `tskit`. They can be run on a local machine so long as all [*requirements*](https://github.com/sgravel/msprime_genealogy_test/blob/main/misc/pedsim_requirements.txt) are met. 

[`run_genome_sim.py`](https://github.com/sgravel/msprime_genealogy_test/blob/main/code/run_genome_sim.py) is the driver script that defines input parameters and runs the genome simulation.

[`pedigree_tools.py`](https://github.com/sgravel/msprime_genealogy_test/blob/main/code/pedigree_tools.py) contains functions used to `load_and_verify_pedigree`, `add_individuals_to_pedigree`, and `simulate_genomes_with_known_pedigree`.   

[`convert_to_bcf.py`](https://github.com/sgravel/msprime_genealogy_test/blob/main/code/convert_to_bcf.py) is a python wrapper for ([`write_vcf`](https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.write_vcf) to convert tree sequences to bcf files.

### Bash
To run these genome simulations on a compute cluster, we use a series of shell scripts meant to be submitted to a SLURM scheduler.

[`0_run_all_jobs.sh`](https://github.com/sgravel/msprime_genealogy_test/blob/main/code/0_run_all_jobs.sh) _job farming_ shell script that schedules all jobs

[`1_simulate_genomes_as_ts.sh`](https://github.com/sgravel/msprime_genealogy_test/blob/main/code/1_simulate_genomes_as_ts.sh) runs an array job of 22 autosomes

[`2_ts_to_bcf.sh`](https://github.com/sgravel/msprime_genealogy_test/blob/main/code/2_ts_to_bcf.sh) converts simulated tree sequence to a bcf file

[`3_bcf_to_plink.sh`](https://github.com/sgravel/msprime_genealogy_test/blob/main/code/3_bcf_to_plink.sh) converts bcf file to a plink file

[`4_ld_prune.sh`](https://github.com/sgravel/msprime_genealogy_test/blob/main/code/4_ld_prune.sh) prunes with linkage disequilibrium and strict [mask](http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/accessible_genome_masks/20140520.strict_mask.autosomes.bed)

[`5_concatenate_chromosomes.sh`](https://github.com/sgravel/msprime_genealogy_test/blob/main/code/5_concatenate_chromosomes.sh) concatenates all chromosomes 

_note: for principal component analysis we use [flashpca2](https://github.com/gabraham/flashpca)._

## Computational requirements
This software can run on a local machine, but given the large computational resource requirements of population scale genome simulations, we used the [Compute Canada cluster](https://docs.computecanada.ca/).

## Input Pedigree
The input pedigree file must have the following four columns `ind` , `mother`, `father`, `generation`. 

The `generation` column is the _maximum generation_ for each individual in the pedigree relative to the probands at generation 0. This generation time is required so that parents are added to the msprime PedigreeBuilder before their children. [pedigree_tools.R](https://github.com/sgravel/msprime_genealogy_test/blob/main/misc/pedigree_tools.R) has a function called `maximum_genealogical_depth(pedigree, list_of_probands)` that will recusively climb an input pedigree and output a four column pedigree file that can be used for msprime genome simulations. (see [prep_pedigree_file.Rmd](https://github.com/sgravel/msprime_genealogy_test/blob/main/misc/prep_pedigree_file.Rmd))


## Model parameters
These parameters can be modified in `run_genome_sim.py`, but in our case we used the following set of parameters:

_demography beyond the input pedigree_: [Out of Africa model](https://tskit.dev/msprime/docs/latest/demography.html) from [Tennessen et al., 2012](https://www.science.org/doi/10.1126/science.1219240) (defined [here](https://popsim-consortium.github.io/stdpopsim-docs/stable/catalog.html?highlight=ooa#sec_catalog_homsap_models_outofafrica_2t12) and loaded from [here](https://github.com/sgravel/msprime_genealogy_test/blob/main/misc/https://github.com/sgravel/msprime_genealogy_test/blob/main/code/Tennessen_ooa_2T12.yaml))

_model to recapitulate the tree_: [hudson](https://tskit.dev/msprime/docs/latest/ancestry.html#hudson-coalescent)

_mutation rate_: 3.62e-8 from [Gravel et al., 2011](https://www.pnas.org/content/108/29/11983) ([stdpopsim](https://github.com/popsim-consortium/stdpopsim/blob/70bc680c41c3e64cc8bc0e2d2586403ac7a39d6b/stdpopsim/catalog/HomSap/demographic_models.py#L369))

_recombination map_: [HapmapII_GRCh37](https://popsim-consortium.github.io/stdpopsim-docs/stable/index.html) ([download](https://stdpopsim.s3-us-west-2.amazonaws.com/genetic_maps/HomSap/HapmapII_GRCh37_RecombinationHotspots.tar.gz))


## Citations

The genome simuations are based on the work described in the following papers, please cite them:

[Jerome Kelleher, Alison M Etheridge and Gilean McVean (2016), Efficient Coalescent Simulation and Genealogical Analysis for Large Sample Sizes, PLOS Comput Biol 12(5): e1004842. doi: 10.1371/journal.pcbi.1004842](http://dx.doi.org/10.1371/journal.pcbi.1004842)

[Dominic Nelson, Jerome Kelleher, Aaron P. Ragsdale, Claudia Moreau, Gil McVean and Simon Gravel (2020), Accounting for long-range correlations in genome-wide simulations of large cohorts, PLOS Genetics 16(5): e1008619. https://doi.org/10.1371/journal.pgen.1008619](https://doi.org/10.1371/journal.pgen.1008619)

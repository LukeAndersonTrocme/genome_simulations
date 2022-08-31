       ___                                  __ _                 _       _             
      / _ \___ _ __   ___  _ __ ___   ___  / _(_)_ __ ___  _   _| | __ _| |_ ___  _ __ 
     / /_\/ _ | '_ \ / _ \| '_ ` _ \ / _ \ \ \| | '_ ` _ \| | | | |/ _` | __/ _ \| '__|
    / /_\|  __| | | | (_) | | | | | |  __/ _\ | | | | | | | |_| | | (_| | || (_) | |   
    \____/\___|_| |_|\___/|_| |_| |_|\___| \__|_|_| |_| |_|\__,_|_|\__,_|\__\___/|_|   
                                                                                   
                                                                                                                                                                                                                  
# Pedigree aware genome simulations

This repository contains scripts that run msprime genome simulations based on a input text pedigree. `tskit` and `msprime` provide extensive [documentation](https://tskit.dev/msprime/docs/latest/api.html#msprime.sim_ancestry) about these simulations. New to this? A good starting point is the msprime [introduction](https://tskit.dev/msprime/docs/stable/intro.html). 

# Quick Start

## Input Pedigree
For this example we use a sample pedigree released with [GenLib](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-015-0581-5)
```
ind,father,mother,sex
10086,0,0,1
10087,0,0,2
10102,0,0,1
10103,0,0,2
```
*text pedigree ([file](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/quick_start/pedigrees/sample_pedigree.csv))*


In order to correctly build the msprime.[Pedigree](https://tskit.dev/msprime/docs/stable/pedigrees.html) object, we must include generation numbers to ensure that parents are added before their children. We use the [generate_ascending_sample_pedigree.R](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/quick_start/code/generate_ascending_sample_pedigree.R) script to identifies probands as individuals who do not have any children, and then ascend the pedigree starting from the probads while keeping track of the [maximum genealogical depth](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/R/maximum_genealogical_depth.R) for internal nodes.
```
ind,mother,father,generation
409153,295170,295169,0
443151,442562,442561,0
408477,861890,861889,0
408790,863184,863183,0
```
*text pedigree with generation time ([file](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/quick_start/pedigrees/ascending_sample_pedigree.txt))*


## Model parameters
These parameters can be modified in `run_genome_sim.py`, but in our case we used the following set of parameters:

_demography beyond the input pedigree_: [Out of Africa model](https://tskit.dev/msprime/docs/latest/demography.html) from [Tennessen et al., 2012](https://www.science.org/doi/10.1126/science.1219240) (defined [here](https://popsim-consortium.github.io/stdpopsim-docs/stable/catalog.html?highlight=ooa#sec_catalog_homsap_models_outofafrica_2t12) and loaded from [here](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/misc/https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/Tennessen_ooa_2T12.yaml))

_model to recapitulate the tree_: [hudson](https://tskit.dev/msprime/docs/latest/ancestry.html#hudson-coalescent)

_mutation rate_: 3.62e-8 from [Gravel et al., 2011](https://www.pnas.org/content/108/29/11983) ([stdpopsim](https://github.com/popsim-consortium/stdpopsim/blob/70bc680c41c3e64cc8bc0e2d2586403ac7a39d6b/stdpopsim/catalog/HomSap/demographic_models.py#L369))

_recombination map_: [HapmapII_GRCh37](https://popsim-consortium.github.io/stdpopsim-docs/stable/index.html) ([download](https://stdpopsim.s3-us-west-2.amazonaws.com/genetic_maps/HomSap/HapmapII_GRCh37_RecombinationHotspots.tar.gz))

## Computational requirements
This software can run on a local machine, but given the large computational resource requirements of population scale genome simulations, we used the [Compute Canada cluster](https://docs.computecanada.ca/).


## Driver Script

To run the genomes simulation on this pedigree, we use the [sample_pedigree_simulation_job.sh](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/quick_start/code/sample_pedigree_simulation_job.sh) script which runs on compute clusters that use a [slurm](https://slurm.schedmd.com/sbatch.html) job scheduler. Note these commands could be run direclty with a command line interface with some user specified inputs. 

```
python code/run_genome_sim.py \
-d /path/to/pedigree/ \
-o /path/to/tree_sequences/ \
-p ascending_sample_pedigree \
-chr 22
```
*This will run the genome simulation pipeline using the input pedigree and following the recombination map of Chromosome 22.*

## Output Tree Sequence

The output of the simulation yields a tszipped formatted tree sequence as shown here : 
```
import msprime
import tszip
ts = tszip.decompress("ascending_sample_pedigree_22_sim.tsz")
print(ts)
╔═══════════════════════════╗
║TreeSequence               ║
╠═══════════════╤═══════════╣
║Trees          │     111516║
╟───────────────┼───────────╢
║Sequence Length│   51304566║
╟───────────────┼───────────╢
║Time Units     │generations║
╟───────────────┼───────────╢
║Sample Nodes   │        280║
╟───────────────┼───────────╢
║Total Size     │   33.5 MiB║
╚═══════════════╧═══════════╝
╔═══════════╤══════╤═════════╤════════════╗
║Table      │Rows  │Size     │Has Metadata║
╠═══════════╪══════╪═════════╪════════════╣
║Edges      │409211│ 12.5 MiB│          No║
╟───────────┼──────┼─────────┼────────────╢
║Individuals│   369│ 23.0 KiB│         Yes║
╟───────────┼──────┼─────────┼────────────╢
║Migrations │     0│  8 Bytes│          No║
╟───────────┼──────┼─────────┼────────────╢
║Mutations  │221856│  7.8 MiB│          No║
╟───────────┼──────┼─────────┼────────────╢
║Nodes      │ 65701│  1.8 MiB│          No║
╟───────────┼──────┼─────────┼────────────╢
║Populations│     5│507 Bytes│         Yes║
╟───────────┼──────┼─────────┼────────────╢
║Provenances│     4│  3.0 MiB│          No║
╟───────────┼──────┼─────────┼────────────╢
║Sites      │221107│  5.3 MiB│          No║
╚═══════════╧══════╧═════════╧════════════╝
```
*tree sequence ([file](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/quick_start/tree_sequences/ascending_sample_pedigree_22_sim.tsz))*


### Tips: 
- Simulate multiple chromosomes? Easy! Just specify `#SBATCH --array=1-22` to run all autosomes as separate jobs.
- installed the proper [*requirements*](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/misc/pedsim_requirements.txt).
- mirror the folder structure in the quick_start directory. In particular, make sure the 'maps' folder is in the same folder as the pedigree folder (e.g `path/to/pedigree/../maps/Tennessen_ooa_2T12.yaml`)


# Other scripts in this repository
### Python
These python files are what interact directly with the `msprime` and `tskit`. They can be run on a local machine so long as all [*requirements*](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/misc/pedsim_requirements.txt) are met. 

[`run_genome_sim.py`](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/run_genome_sim.py) is the driver script that defines input parameters and runs the genome simulation.

[`pedigree_tools.py`](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/pedigree_tools.py) contains functions used to `load_and_verify_pedigree`, `add_individuals_to_pedigree`, and `simulate_genomes_with_known_pedigree`.   

[`convert_to_bcf.py`](https://github.com/LukeAndersonTrocme/genome_simulationst/blob/main/code/convert_to_bcf.py) is a python wrapper for ([`write_vcf`](https://tskit.dev/tskit/docs/stable/python-api.html#tskit.TreeSequence.write_vcf) to convert tree sequences to bcf files.

### Bash
Note this pipeline has additional steps that may not be relevant for you! In particular, this pipeline converts tree sequences to inefficient file formats and prunes variants in order to run a PCA.

[`0_run_all_jobs.sh`](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/0_run_all_jobs.sh) _job farming_ shell script that schedules all jobs

[`1_simulate_genomes_as_ts.sh`](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/1_simulate_genomes_as_ts.sh) runs an array job of 22 autosomes

[`2_ts_to_bcf.sh`](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/2_ts_to_bcf.sh) converts simulated tree sequence to a bcf file

[`3_bcf_to_plink.sh`](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/3_bcf_to_plink.sh) converts bcf file to a plink file

[`4_ld_prune.sh`](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/4_ld_prune.sh) prunes with linkage disequilibrium and strict [mask](http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/supporting/accessible_genome_masks/20140520.strict_mask.autosomes.bed)

[`5_concatenate_chromosomes.sh`](https://github.com/LukeAndersonTrocme/genome_simulations/blob/main/code/5_concatenate_chromosomes.sh) concatenates all chromosomes 

_note: for principal component analysis we use [flashpca2](https://github.com/gabraham/flashpca)._



## Citations

The genome simuations are based on the work described in the following papers, please cite them:

[Jerome Kelleher, Alison M Etheridge and Gilean McVean (2016), Efficient Coalescent Simulation and Genealogical Analysis for Large Sample Sizes, PLOS Comput Biol 12(5): e1004842. doi: 10.1371/journal.pcbi.1004842](http://dx.doi.org/10.1371/journal.pcbi.1004842)

[Dominic Nelson, Jerome Kelleher, Aaron P. Ragsdale, Claudia Moreau, Gil McVean and Simon Gravel (2020), Accounting for long-range correlations in genome-wide simulations of large cohorts, PLOS Genetics 16(5): e1008619. https://doi.org/10.1371/journal.pgen.1008619](https://doi.org/10.1371/journal.pgen.1008619)

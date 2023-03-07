#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=2GB
#SBATCH --time=00:04:00

dir="/home/luke1111/projects/ctb-sgravel/luke1111/simulated_genomes/final_revised_ascending_pedigree_sim/"

module load r/4.1.2

Rscript code/make_pca_umap_plot.R \
$dir/plink_files/pcs_revised_ascending_pedigree_sim_ld_25.txt \
$dir/big_sim_25_a2D_0.7_b2D_0.9.jpg \
$dir/big_sim_25_a2D_0.7_b2D_0.9.csv \
0.7 0.9 0.1 2 25

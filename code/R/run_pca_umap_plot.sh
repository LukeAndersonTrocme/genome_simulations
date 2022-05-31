#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=4GB
#SBATCH --time=01:30:00
#SBATCH --array=60-120:1
#SBATCH --output=log/%x-%A_%a.out
#SBATCH --mail-user=luke.anderson.trocme@gmail.com
#SBATCH --mail-type=FAIL

# load software and environments
module load r/4.1.2

# set variables
a_2D=0.7
b_2D=`echo "print(${SLURM_ARRAY_TASK_ID}/100)" | python3`

a_3D=0.1
#`echo "print(${SLURM_ARRAY_TASK_ID}/100)" | python3`
#0.55
b_3D=2.
#0.60
#_a3D_${a_3D}_b3D_${b_3D}
pca_filename=$1
figure_filename="${2%.jpg}_a2D_${a_2D}_b2D_${b_2D}.jpg"
csv_filename="${2%.csv}_a2D_${a_2D}_b2D_${b_2D}.csv"

cd /home/luke1111/projects/ctb-sgravel/luke1111/simulated_genomes/code/R/

echo "Job started at: `date`"

# run flashpca on input file
Rscript make_pca_umap_plot.R $pca_filename $figure_filename $csv_filename $a_2D $b_2D $a_3D $b_3D

echo "Job finished with exit code $? at: `date`"

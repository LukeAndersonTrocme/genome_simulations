#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=16GB
#SBATCH --time=04:00:00
#SBATCH --array=1-22
#SBATCH --output=log/%x-%A_%a.out


# load software
module load plink/2.00-10252019-avx2

# set variables
chromosome=$SLURM_ARRAY_TASK_ID
input_file=$1/${2}_${chromosome}_${3}

af_cutoff=0.05
window_size=1000
step_size=100
r_squared=0.25 #0.05
#king_cutoff=0.0884
mask_file="$HOME/projects/ctb-sgravel/luke1111/simulated_genomes/maps/20140520.strict_mask.autosomes.bed"

echo "Job started at: `date`"

# linkage disequilibrium and exlude centromeres (and other weird regions)
srun plink2 \
--bfile $input_file \
--indep-pairwise $window_size $step_size $r_squared \
--maf $af_cutoff \
--extract range $mask_file \
--out $input_file

srun plink2 --bfile $input_file \
--extract ${input_file}.prune.in \
--make-bed \
--out ${input_file}_ld

# identify close relations with KING-robust kinship estimator
#srun plink2 --bfile ${input_file}_ld \
#--make-king triangle bin \
#--out ${input_file}_ld

#srun plink2 --bfile ${input_file}_ld \
#--king-cutoff ${input_file}_ld $king_cutoff \
#--make-bed \
#--out ${input_file}_ld_kin

echo "Job finished with exit code $? at: `date`"

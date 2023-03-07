#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4GB
#SBATCH --time=01:00:00
#SBATCH --array=1-22
#SBATCH --output=log/%x-%A_%a.out

# set variables
bcf_path=$1
plink_path=$2
chromosome=$SLURM_ARRAY_TASK_ID
file_name=${3}_${chromosome}_${4}

af_cutoff=0.05
window_size=1000
step_size=100
r_squared=0.4 #0.05
#king_cutoff=0.0884
mask_file="$HOME/projects/ctb-sgravel/luke1111/simulated_genomes/maps/20140520.strict_mask.autosomes.bed"

echo "Job started at: `date`"

# load software and environments
module load plink/1.9b_6.21-x86_64

# make a bed/bim/fam file
srun plink \
--bcf $bcf_path/${file_name}.bcf \
--maf $af_cutoff \
--extract range $mask_file \
--make-bed \
--out $plink_path/${file_name}

# load software
module load plink/2.00-10252019-avx2

# linkage disequilibrium and exlude centromeres (and other weird regions)
srun plink2 \
--bfile $plink_path/${file_name} \
--max-alleles 2 \
--set-all-var-ids @:\#:\$1:\$2 \
--indep-pairwise $window_size $step_size $r_squared \
--out $plink_path/${file_name}

srun plink2 --bfile $plink_path/${file_name} \
--set-all-var-ids @:\#:\$1:\$2 \
--extract $plink_path/${file_name}.prune.in \
--make-bed \
--out $plink_path/${file_name}_ld

# identify close relations with KING-robust kinship estimator
#srun plink2 --bfile ${input_file}_ld \
#--make-king triangle bin \
#--out ${input_file}_ld

#srun plink2 --bfile ${input_file}_ld \
#--king-cutoff ${input_file}_ld $king_cutoff \
#--make-bed \
#--out ${input_file}_ld_kin

echo "Job finished with exit code $? at: `date`"

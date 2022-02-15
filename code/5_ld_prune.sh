#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4GB
#SBATCH --time=03:00:00
#SBATCH --output=log/%x-%j.out
#SBATCH --mail-user=luke.anderson.trocme@gmail.com
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

# load software
module load plink/2.00-10252019-avx2

# set variables
mask_file=$1
file_name=$2
window_size=$3
step_size=$4
r_squared=$5
king_cutoff=$6

echo "Job started at: `date`"

# linkage disequilibrium and exlude centromeres (and other weird regions)
srun plink2 \
--bfile $file_name \
--indep-pairwise $window_size $step_size $r_squared \
--maf 0.05 \
--extract range $mask_file \
--out $file_name

srun plink2 --bfile $file_name \
--extract ${file_name}.prune.in \
--make-bed \
--out ${file_name}_ld_${window_size}_${step_size}_${r_squared}

# identify close relations with KING-robust kinship estimator
srun plink2 --bfile ${file_name}_ld_${window_size}_${step_size}_${r_squared} \
--make-king triangle bin \
--out ${file_name}_ld_${window_size}_${step_size}_${r_squared}

srun plink2 --bfile ${file_name}_ld_${window_size}_${step_size}_${r_squared} \
--king-cutoff ${file_name}_ld_${window_size}_${step_size}_${r_squared} $king_cutoff \
--make-bed \
--out ${file_name}_ld_${window_size}_${step_size}_${r_squared}_${king_cutoff}

echo "Job finished with exit code $? at: `date`"

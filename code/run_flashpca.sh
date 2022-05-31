#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=2GB
#SBATCH --time=09:00:00
#SBATCH --output=log/%x-%j.out
#SBATCH --mail-user=luke.anderson.trocme@gmail.com
#SBATCH --mail-type=FAIL

# load software and environments
module load gcc flashpca

# set variables
plink_path=$1
file_name=$2

cd $plink_path

echo "Job started at: `date`"

# run flashpca on input file
srun flashpca \
--bfile $file_name \
--ndim 100 \
--numthreads 12 \
--suffix _${file_name}_100.txt

echo "Job finished with exit code $? at: `date`"

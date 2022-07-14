#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=16GB
#SBATCH --time=02:00:00
#SBATCH --output=log/%x-%j.out
#SBATCH --mail-user=luke.anderson.trocme@gmail.com
#SBATCH --mail-type=FAIL

# load software and environments
module load plink/1.9b_6.21-x86_64

# set variables
plink_path=$1
prefix=$2
suffix=$3
out=$plink_path/${prefix}_${suffix}

echo "Job started at: `date`"

# list all chromomes to be merged
ls $plink_path/${prefix}_*_${suffix}.bed | sed 's/.bed//g' > merge.txt

# merge all chromosomes
srun plink --merge-list merge.txt --make-bed --out $out

echo "Job finished with exit code $? at: `date`"

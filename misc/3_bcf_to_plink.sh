#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=128GB
#SBATCH --time=12:00:00
#SBATCH --array=1-22
#SBATCH --output=log/%x-%A_%a.out
#SBATCH --mail-user=luke.anderson.trocme@gmail.com
#SBATCH --mail-type=FAIL

# load software and environments
module load StdEnv/2020
module load gcc/9.3.0
module load bcftools/1.13
module load plink/2.00-10252019-avx2

# set variables
bcf_path=$1
plink_path=$2
chromosome=$SLURM_ARRAY_TASK_ID
file_name=${3}_${chromosome}_${4}
temp_file=$SLURM_TMPDIR/${file_name}

echo "Job started at: `date`"

# make file to explicitly rename chromosome
#echo "1 chr${chromosome}" > ${temp_file}_chromosme.txt

# rename the chromosome
#bcftools annotate --rename-chrs ${temp_file}_chromosme.txt \
#$bcf_path/${file_name}.bcf \
#-Ov -o ${temp_file}.vcf

# make a bed/bim/fam file
srun plink2 \
--vcf ${temp_file}.vcf \
--max-alleles 2 \
--set-all-var-ids @:\#:\$1:\$2 \
--make-bed \
--out $plink_path/${file_name}

# remove temp files
rm ${temp_file}*

echo "Job finished with exit code $? at: `date`"

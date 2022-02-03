#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=2GB
#SBATCH --time=01:00:00
#SBATCH --array=1-22
#SBATCH --output=log/%x-%A_%a.out
#SBATCH --mail-user=luke.anderson.trocme@gmail.com
#SBATCH --mail-type=FAIL

# load software and environments
module load StdEnv/2020
module load gcc/9.3.0
module load bcftools/1.13
module load python/3.9
source $HOME/projects/ctb-sgravel/python_environments/pedsim/bin/activate

# set variables
dir=$1
ts_path=$2
bcf_path=$3
temp_dir=$SLURM_TMPDIR
chromosome=$SLURM_ARRAY_TASK_ID
file_name=${4}_${chromosome}_${5}


echo "Job started at: `date`"

srun python $dir/code/convert_ts_to_bcf.py \
-i $ts_path/${file_name}.ts \
-o $temp_dir \
-n $file_name \
-f 0.01

mv $temp_dir/${file_name}.bcf $bcf_path/

echo "Job finished with exit code $? at: `date`"

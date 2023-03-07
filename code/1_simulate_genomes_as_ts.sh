#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=16GB
#SBATCH --time=6-00:00:00
#SBATCH --array=1-22
#SBATCH --output=log/%x-%A_%a.out
#SBATCH --mail-user=luke.anderson.trocme@gmail.com
#SBATCH --mail-type=START,FAIL,END

# load software and environments
module load python/3.9
source $HOME/projects/ctb-sgravel/python_environments/pedsim/bin/activate
#pip install --no-index --upgrade pip
#pip install --no-index -r $HOME/projects/ctb-sgravel/python_environments/pedsim_requirements.txt

dir=$1
ts_path=$2
pedigree_name=$3

echo "Job started at: `date`"

srun python $dir/code/run_genome_sim.py \
-d $dir \
-o $ts_path \
-p $pedigree_name \
-chr $SLURM_ARRAY_TASK_ID
#-censor

echo "Job finished with exit code $? at: `date`"

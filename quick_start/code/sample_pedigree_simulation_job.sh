#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=1GB
#SBATCH --time=00:10:00
#SBATCH --array=22
#SBATCH --output=log/%x-%A_%a.out
#SBATCH --mail-user=luke.anderson.trocme@gmail.com
#SBATCH --mail-type=FAIL

# set working directory
cd $HOME/projects/ctb-sgravel/luke1111/quick_start/

# load software and environments
module load python/3.9
source $HOME/projects/ctb-sgravel/python_environments/pedsim/bin/activate
#pip install --no-index --upgrade pip
#pip install --no-index -r $HOME/projects/ctb-sgravel/python_environments/pedsim_requirements.txt

pedigree_name="ascending_sample_pedigree"
dir="$HOME/projects/ctb-sgravel/luke1111/quick_start/pedigrees/"

ts_path="$HOME/projects/ctb-sgravel/luke1111/quick_start/tree_sequences/"

echo "Job started at: `date`"

srun python code/run_genome_sim.py \
-d $dir \
-o $ts_path \
-p $pedigree_name \
-chr $SLURM_ARRAY_TASK_ID

echo "Job finished with exit code $? at: `date`"

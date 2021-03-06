#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1
#SBATCH --time=00:01:00
#SBATCH --array=2-15
#SBATCH --output=log/%x-%A_%a.out
#SBATCH --mail-user=luke.anderson.trocme@gmail.com
#SBATCH --mail-type=FAIL

# load software and environments
module load r/4.1.2

# set variables
a_2D=`echo "print(${SLURM_ARRAY_TASK_ID}/2)" | python3`
b_2D=0.9
pca_filename=$1
figure_filename="${2%.jpg}_a_${a_2D}_b_0.9.jpg"

echo $a_2D
echo $figure_filename

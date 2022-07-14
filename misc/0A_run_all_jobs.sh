#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=1GB
#SBATCH --array=1-10
#SBATCH --time=00:50:00
#SBATCH --output=log/%x-%j.out

# scheduling all jobs related to genome simulations

time_stamp=$(date +"%F")
dir="$HOME/projects/def-sgravel/shared_projects/simulation_p_value/simulated_genomes/"
p="${dir}/code"
ped_name="lac_saint_jean_ascending_pedigree"
suffix="sim"
random_seed=$SLURM_ARRAY_TASK_ID

path=${dir}${ped_name}_${suffix}_replicate_${SLURM_ARRAY_TASK_ID}_${time_stamp}
ts_path=$path/tree_sequences
bcf_path=$path/bcf_files
plink_path=$path/plink_files
log_path=$path/log

mkdir -p $ts_path $bcf_path $plink_path $log_path

cp $p/*.sh $log_path/
cp $p/*.py $log_path/

cd $path

# input: four column text pedigree
# output: tree sequences of 22 separate chromosomes
J1=$(sbatch --parsable \
    $p/1_simulate_genomes_as_ts.sh \
    $dir $ts_path \
    $ped_name $suffix -seed $random_seed)

# input: tree sequences of 22 separate chromosomes
# output: bcf files of 22 separate chromosomes
J2=$(sbatch --dependency=afterok:$J1 --parsable \
     $p/2_ts_to_bcf.sh \
     $dir $ts_path $bcf_path \
     $ped_name $suffix)

# input: bcf files of 22 separate chromosomes
# output: pruned plink files (linkage disequilibrium)
J3=$(sbatch --dependency=afterok:$J2 --parsable \
     $p/3_bcf_to_pruned_plink.sh \
     $bcf_path $plink_path \
     $ped_name $suffix)

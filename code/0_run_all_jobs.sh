#!/bin/bash
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=1GB
#SBATCH --time=72:00:00
#SBATCH --output=log/%x-%j.out

# scheduling all jobs related to genome simulations

time_stamp=$(date +"%F_%H:%M")
dir="/home/luke1111/projects/ctb-sgravel/luke1111/simulated_genomes/"
p="${dir}/code"
ped_name="public_ascending_pedigree_1890-1920_2k_cap"
suffix="sim"

path=${dir}${ped_name}_${suffix}_${time_stamp}
ts_path=$path/tree_sequences
bcf_path=$path/bcf_files
plink_path=$path/plink_files
log_path=$path/log

mkdir -p $ts_path $bcf_path $plink_path $log_path

cd $path

# input: four column text pedigree
# output: tree sequences of 22 separate chromosomes
J1=$(sbatch --parsable \
    $p/1_simulate_genomes_as_ts.sh \
    $dir $ts_path \
    $ped_name $suffix)

# input: tree sequences of 22 separate chromosomes
# output: bcf files of 22 separate chromosomes
J2=$(sbatch --dependency=afterok:$J1 --parsable \
     $p/2_ts_to_bcf.sh \
     $dir $ts_path $bcf_path \
     $ped_name $suffix)

# input: bcf files of 22 separate chromosomes
# output: plink files of 22 separate chromosomes
J3=$(sbatch --dependency=afterok:$J2 --parsable \
     $p/3_bcf_to_plink.sh \
     $bcf_path $plink_path \
     $ped_name $suffix)

# input: plink files of 22 separate chromosomes
# output: plink file of 22 concatentated chromosomes
J4=$(sbatch --dependency=afterok:$J3 --parsable \
     $p/4_concatenate_chromosomes.sh \
     $plink_path \
     $ped_name $suffix)

# input: plink file of 22 concatentated chromosomes
# output: pruned plink file (linkage disequilibrium and relatedness)
sbatch --dependency=afterok:$J4 \
$p/5_ld_prune.sh \
$dir/maps/20140520.strict_mask.autosomes.bed \
$plink_path/${ped_name}_${suffix} \
1000 100 0.05 0.0884

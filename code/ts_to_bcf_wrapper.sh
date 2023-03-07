#!/bin/bash
for argument in "$@"
do
  key=$(echo $argument | cut -f 1 -d'=')
  value=$(echo $argument | cut -f 2 -d'=')
  case "$key" in
    "job_name")     job_name="$value" ;;
    "cpus")         cpus="$value" ;;
    "memory")       memory="$value" ;;
    "time")         time="$value" ;;

    "input_file")   input_file="$value" ;;
    "use_temp")     use_temp="$value" ;;
    "make_plink")   use_temp="$value" ;;
    "temp_path")    temp_path="$value" ;;
    "output_path")  output_file="$value" ;;
    "output_plink") output_plink="$value" ;;
    "output_file")  output_file="$value" ;;
    "af_cutoff")    af_cutoff="$value" ;;
    "array")        array="$value" ;;

    "window_size")        array="$value" ;;
    "step_size")        array="$value" ;;
    "r_squared")        array="$value" ;;



    "environment")  environment="$value" ;;
    "working_dir")  working_dir="$value" ;;
    *)
  esac
done

{ tee /dev/stderr | sbatch; } <<EOT
#!/bin/sh
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=${cpus:-2}
#SBATCH --mem-per-cpu=${memory:-2}GB
#SBATCH --time=${time:-00:10:00}
#SBATCH --array=${array:-"22-22"}
#SBATCH --job-name=${job_name:-Default_Job_Name}
#SBATCH --output=${working_dir:-$HOME/projects/ctb-sgravel/luke1111/quick_start/}log/%x-%A_%a.out

INPUT=${input_file:-$HOME/projects/ctb-sgravel/luke1111/quick_start/tree_sequences/ascending_sample_pedigree_\${SLURM_ARRAY_TASK_ID\}_sim.tsz}
OUT=${output_path:-$HOME/projects/ctb-sgravel/luke1111/quick_start/bcf_files/}
PLINK_PATH=${output_plink:-$HOME/projects/ctb-sgravel/luke1111/quick_start/plink_files/}
NAME=${output_file:-ascending_sample_pedigree_\${SLURM_ARRAY_TASK_ID\}_sim}

echo "Job started at: `date`"
echo
echo "With SBATCH parameters:"
echo "job_name: ${job_name:-\"Default_Job_Name\"}"
echo "cpus: ${cpus:-2}"
echo "memory: ${memory:-2}GB"
echo "time: ${time:-00:10:00}"
echo "array: \$SLURM_ARRAY_TASK_ID"
echo
echo "With ts to bcf parameters :"
echo "input_file: \$INPUT"
echo "use_temp: ${use_temp:-true}"
echo "output_path: \$OUT"
echo "output_file: \$NAME"
echo
echo "environment: ${environment:-$HOME/projects/ctb-sgravel/python_environments/pedsim/bin/activate}"
echo "working_dir: ${working_dir:-$HOME/projects/ctb-sgravel/luke1111/quick_start/}"


# set working directory
cd ${working_dir:-$HOME/projects/ctb-sgravel/luke1111/quick_start/}

# load software and environments
module load StdEnv/2020
module load gcc/9.3.0
module load bcftools/1.13
module load python/3.9
source ${environment:-$HOME/projects/ctb-sgravel/python_environments/pedsim/bin/activate}

if [[ \$INPUT == *.tsz ]]
then
  echo
  echo "Decompressing Tree Sequence"
  python3 -m tszip -k -c -d \$INPUT > \${INPUT%.*}.ts
fi

if ${use_temp:-true}
then
  python code/convert_ts_to_bcf.py \
  -i \${INPUT%.*}.ts \
  -o ${temp_path:-\$SLURM_TMPDIR} \
  -c \$SLURM_ARRAY_TASK_ID \
  -n \$NAME \
  -f ${af_cutoff:-0.001}
  # writing to temp speeds up the process
  mv ${temp_path:-\$SLURM_TMPDIR}/\$NAME.* \$OUT
else
  python $dir/code/convert_ts_to_bcf.py \
  -i \${INPUT%.*}.ts  \
  -o \$OUT \
  -c \$SLURM_ARRAY_TASK_ID \
  -n \$NAME \
  -f ${af_cutoff:-0.001}
fi


if ${make_plink:-true}
then
  echo
  echo "Converting BCF to PLINK"
  echo "window_size: ${window_size:-1000}"
  echo "step_size: ${step_size:-100}"
  echo "r_squared: ${r_squared:-0.4}"

  # load software
  module load plink/2.00a3.6

  plink2 \
  --bcf \$OUT/\${NAME}.bcf \
  --max-alleles 2 \
  --make-bed \
  --threads ${cpus:-2} \
  --out \$PLINK_PATH/\$NAME

  plink2 \
  --bfile \$PLINK_PATH/\$NAME \
  --set-all-var-ids @:\#:\$1:\$2 \
  --indep-pairwise \
  ${window_size:-1000} \
  ${step_size:-100} \
  ${r_squared:-0.4} \
  --threads ${cpus:-2} \
  --out \$PLINK_PATH/\$NAME

  plink2 --bfile \$PLINK_PATH/\$NAME \
  --set-all-var-ids @:\#:\$1:\$2 \
  --extract \$PLINK_PATH/\${NAME}.prune.in \
  --make-bed \
  --threads ${cpus:-2} \
  --out \$PLINK_PATH/\${NAME}_ld
else
  echo
  echo "Not converting BCF to PLINK"
fi

echo
echo "Job finished at: `date`"

EOT

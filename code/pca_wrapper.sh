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
    "output_path")  output_file="$value" ;;
    "output_file")  output_file="$value" ;;
    "ndim")         ndim="$value" ;;

    "make_plot")    make_plot="$value" ;;
    "a_2D")         a_2D="$value" ;;
    "b_2D")         b_2D="$value" ;;
    "a_3D")         a_3D="$value" ;;
    "b_3D")         b_3D="$value" ;;

    "working_dir")  working_dir="$value" ;;
    *)
  esac
done

{ tee /dev/stderr | sbatch; } <<EOT
#!/bin/sh
#SBATCH --account=ctb-sgravel
#SBATCH --cpus-per-task=${cpus:-10}
#SBATCH --mem-per-cpu=${memory:-2}GB
#SBATCH --time=${time:-00:10:00}
#SBATCH --job-name=${job_name:-Default_Job_Name}
#SBATCH --output=${working_dir:-$HOME/projects/ctb-sgravel/luke1111/quick_start/}log/%x-%A.out

WD=${working_dir:-$HOME/projects/ctb-sgravel/luke1111/quick_start/}
INPUT=${input_file:-$HOME/projects/ctb-sgravel/luke1111/quick_start/plink_files/ascending_sample_pedigree_22_sim_ld}
OUT=${output_path:-$HOME/projects/ctb-sgravel/luke1111/quick_start/pca_files/}
NAME=${output_file:-ascending_sample_pedigree_sim}

echo "Job started at: `date`"
echo
echo "With SBATCH parameters:"
echo "job_name: ${job_name:-\"Default_Job_Name\"}"
echo "cpus: ${cpus:-10}"
echo "memory: ${memory:-2}GB"
echo "time: ${time:-00:10:00}"
echo
echo "With PCA parameters :"
echo "number of dimensions : ${ndim:-20}"
echo "input_file: \$INPUT"
echo "output_path: \$OUT"
echo "output_file: \$NAME"

# load software and environments
module load gcc flashpca

cd \$OUT

echo "Job started at: `date`"

# run flashpca on input file
flashpca \
--bfile \$INPUT \
--ndim ${ndim:-20} \
--numthreads ${cpus:-10} \
--suffix _\${NAME}_${ndim:-20}.txt

if ${make_plot:-true}
then
  echo
  echo "Making a PCA plot"

  module load r/4.1.2
  Rscript \$WD/code/make_pca_umap_plot.R \
  pcs_\${NAME}_${ndim:-20}.txt \
  \${OUT}_\${NAME}_${ndim:-20}_a2D_${a_2D:-0.7}_b2D_${b_2D:-0.9}.jpg \
  \${OUT}_\${NAME}_${ndim:-20}_a2D_${a_2D:-0.7}_b2D_${b_2D:-0.9}.csv \
  ${a_2D:-0.7} ${b_2D:-0.9} ${a_3D:-0.1} ${b_3D:-2} ${ndim:-20}

else
  echo
  echo "Not making a PCA plot"
fi

echo "Job finished at: `date`"

EOT

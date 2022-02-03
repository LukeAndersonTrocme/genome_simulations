
# this script contains a few snippets of code that are not currently used

# the following could be relevant for run_balsac.py
# for specifying demographic models and recombination maps
# directly from stdpopsim

# import stdpopsim
# stdpopsim human demographic models
# hom_sap = stdpopsim.get_species('HomSap')
# demographic_model = hom_sap.get_demographic_model("OutOfAfrica_2T12")
# load HapMap Phase II lifted over to GRCh37
# recombination_map = hom_sap.get_genetic_map("HapMapII_GRCh37")

# in case of uniform recombination rate
# uniform_rate = 1.203828130094258e-08



# convert tree sequence to vcf
python convert_to_bcf.py -vcf -f 0.01 \
${pth}pedigree/${pedigree_name}_${chromosome}_${mutation_rate}_${suffix}.ts \
${pth}pedigree/${pedigree_name}_${chromosome}_${mutation_rate}_${suffix}_tmp.vcf

# explicitly rename chromosome
echo "1 ${chromosome}" > chr_${chromosome}_name_conv.txt
# rename the chromosome
bcftools annotate --rename-chrs chr_${chromosome}_name_conv.txt \
${pth}pedigree/${pedigree_name}_${chromosome}_${mutation_rate}_${suffix}_tmp.vcf \
-Ov -o ${pth}pedigree/${pedigree_name}_${chromosome}_${mutation_rate}_${suffix}.vcf

# remove temp file
rm ${pth}pedigree/${pedigree_name}_${chromosome}_${mutation_rate}_${suffix}_tmp.vcf
# make a bed/bim/fam file



plink2 \
--vcf ${pth}pedigree/${pedigree_name}_${mutation_rate}_${suffix}.bcf \
--max-alleles 2 \
--set-all-var-ids @:\#:\$1:\$2 \
--make-bed \
--out ${pth}pedigree/${pedigree_name}_${chromosome}_${mutation_rate}_${suffix}

#############################################
# Centromere locations for GRCh37 (aka hg19) from UCSC
# See https://www.biostars.org/p/2349/
# and https://github.com/mcveanlab/treeseq-inference/blob/0cbbb062c96ad4433d8b4d0f120f93ac2d985345/human-data/Makefile#L60
#############################################
curl http://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/cytoBand.txt.gz > cytoband.txt.gz
echo "chrom,start,end" > centromeres.csv
# Start and end coordinates are on different lines, so we merge them.
gzcat cytoband.txt.gz | grep acen | sort | paste -d " " - - \
| cut -f 1,2,7 | tr '\t' ',' | sed 's/chr//g' >> centromeres.csv
rm cytoband.txt.gz

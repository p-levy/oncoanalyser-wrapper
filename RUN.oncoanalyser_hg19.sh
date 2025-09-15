#!/bin/bash

# DO NOT CHANGE THESE LINES
INPUT=${1}
OUTPUT=${2}
OPT_ARGS=${3:-""} # optional arguments to pass to nextflow

# Create cache and tmp directories if they don't exist
mkdir -p cache
mkdir -p tmp

# Nextflow Run OA 2.0
nextflow run nf-core/oncoanalyser \
  -profile singularity \
  -revision 2.0.0 \
  --mode wgts \
  --genome GRCh37_hmf \
  --ref_data_hmf_data_path /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref/hmf_pipeline_resources.37_v2.0--3 \
  --input ${INPUT} \
  --outdir ${OUTPUT} \
  -c /mnt/bioinfnas/immuno/plevy/proj/hmftools/hmf.local.config \
  -resume \
  ${OPT_ARGS}

  ## INFOS #################################################################################################################################################################################################################################################################
  # Make sure the following command was previously ran to consider Ensembl NMD-labeled transcripts as protein coding
  # sed -i 's/nonsense_mediated_decay/protein_coding/g' ensembl_trans_exon_data.csv in the hmf_pipeline_resources.37_v2.0--3/common/ensembl_data folder
  # 
  # Make sure the following commands were previously ran to skip the PONGnomad filtering in Pave variant annotation
  # cp /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref/hmf_pipeline_resources.37_v2.0--3/dna/variants/gnomad_variants_v37.csv.gz /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref/hmf_pipeline_resources.37_v2.0--3/dna/variants/gnomad_variants_v37.csv.gz.bak
  # {
  #   echo "Chromosome,Position,Ref,Alt,Frequency"
  #   for chr in {1..22} X Y; do
  #     echo "$chr,1,T,C,0.0001"
  #   done
  # } > gnomad_variants_v37.csv
  # gzip gnomad_variants_v37.csv (overwrite yes)
  # The new gnomad_variants_v37.csv.gz needs to have data for each chr but here it's only reporting on position 1 and we never have variants theresque so no PONGnomad filter is added during Pave annotation
  ###########################################################################################################################################################################################################################################################################

  # Useful Options
  # --processes_manual \
  # --processes_include alignment,redux,cobalt,amber,sage
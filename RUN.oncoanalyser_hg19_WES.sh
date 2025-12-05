#!/bin/bash
#SBATCH --job-name=OA    # Job name
#SBATCH --mem=8gb # Job memory request
#SBATCH -c 2 # max nr threads
#SBATCH --time=5-00:00:00           # Time limit hrs:min:sec
#SBATCH --output=R-%x.%j.out   # Standard output and error log
#SBATCH --error=R-%x.%j.err
#SBATCH --partition=highmem
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=plevy@vhio.net

# DO NOT CHANGE THESE LINES
INPUT=${1:-"input.csv"}
OUTPUT=${2:-"output"}
OPT_ARGS=${3:-""} # optional arguments to pass to nextflow

# Create cache and tmp directories if they don't exist
mkdir -p cache
mkdir -p tmp

# Nextflow Run OA 2.2
nextflow run nf-core/oncoanalyser \
  -profile singularity \
  -revision 2.2.0 \
  --mode targeted \
  --panel wes \
  --genome GRCh37_hmf \
  --force_panel \
  --input ${INPUT} \
  --outdir ${OUTPUT} \
  --ref_data_hmf_data_path /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref/reference_data/2.2.0/hmf_pipeline_resources.37_v2.2.0--3 \
  -c /mnt/bioinfnas/immuno/plevy/proj/hmftools/hmf.local.config \
  -resume

  ## INFOS #################################################################################################################################################################################################################################################################
  # Make sure the following command was previously ran to consider Ensembl NMD-labeled transcripts as protein coding
  # sed -i 's/nonsense_mediated_decay/protein_coding/g' ensembl_trans_exon_data.csv in the ${ref_data_hmf_data_path}/common/ensembl_data folder
  # 
  # Make sure the following commands were previously ran to skip the PONGnomad filtering in Pave variant annotation
  # cp ${ref_data_hmf_data_path}/dna/variants/gnomad_variants_v37.csv.gz ${ref_data_hmf_data_path}/dna/variants/gnomad_variants_v37.csv.gz.bak
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
  # --processes_manual alignment,redux,cobalt,amber,sage
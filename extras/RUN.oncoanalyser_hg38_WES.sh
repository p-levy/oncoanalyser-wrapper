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
  --genome GRCh38_hmf \
  --force_panel \
  --input ${INPUT} \
  --outdir ${OUTPUT} \
  --ref_data_hmf_data_path /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref/reference_data/2.2.0/hmf_pipeline_resources.38_v2.2.0--3 \
  -c /mnt/bioinfnas/immuno/plevy/proj/hmftools/hmf.local.config \
  -resume

  ## INFOS #################################################################################################################################################################################################################################################################
  # Make sure the following command was previously ran to consider Ensembl NMD-labeled transcripts as protein coding
  # sed -i 's/nonsense_mediated_decay/protein_coding/g' ensembl_trans_exon_data.csv in the hmf_pipeline_resources.38_v2.2.0--3/common/ensembl_data folder
  # 
  # Make sure the hmf_pipeline_resources.38_v2.2.0--3/dna/variants/gnomad folder contains all the files but empty to skip the PONGnomad filtering in Pave variant annotation
  # cp gnomad gnomad_bak && mkdir gnomad && ls gnomad_bak | xargs -I{} touch gnomad/{}
  ###########################################################################################################################################################################################################################################################################

  # Useful Options
  # --processes_manual alignment,redux,cobalt,amber,sage
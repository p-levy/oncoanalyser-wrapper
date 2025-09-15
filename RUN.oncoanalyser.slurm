#!/bin/bash
#SBATCH --mem=8gb # Job memory request
#SBATCH -c 1 # max nr threads
#SBATCH --time=2-00:00:00           # Time limit hrs:min:sec
#SBATCH --output=R-%x.%j.out   # Standard output and error log
#SBATCH --error=R-%x.%j.err
#SBATCH --partition=highmem
#SBATCH --mail-type=FAIL,END


# DO NOT CHANGE THESE LINES
INPUT=${1:-input.csv}
OUTPUT=${2:-output}
GENOME=${3:-hg38} # either hg19 or hg38
OA_ITAG_DIR=${4:-/mnt/bioinfnas/immuno/plevy/proj/hmftools/oncoanalyser-wrapper} # path to this directory, change if required
OPT_ARGS=${5:-""} # optional arguments to pass to nextflow
bash ${OA_ITAG_DIR}/RUN.oncoanalyser_${GENOME}.sh ${INPUT} ${OUTPUT} "${OPT_ARGS}"

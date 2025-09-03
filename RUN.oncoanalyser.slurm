#!/bin/bash
#SBATCH --mem=8gb # Job memory request
#SBATCH -c 1 # max nr threads
#SBATCH --time=2-00:00:00           # Time limit hrs:min:sec
#SBATCH --output=R-%x.%j.out   # Standard output and error log
#SBATCH --error=R-%x.%j.err
#SBATCH --partition=highmem
#SBATCH --mail-type=FAIL,END

### INSTRUCTIONS TO RUN #################################################################################################################
#  Modify following command and copy/paste in cluster terminal (modify variables as explained below)				                    #
#																																	    #
#  sbatch -J OA-patient_X --mail-user=your.email@domain.com RUN.oncoanalyser.slurm input.csv output genome	path/to/oncoanalyser-wrapper	#
#																																	    #
#  input.csv  	path to input.csv file																				                    #
#  output  path to desired output directory                                                                                             #
#  /path/to/oncoanalyser-wrapper   path to oncoanalyser-wrapper directory																        #
#  -J specifies the job name and .out and .err slurm outputs, change TIL0XX by patient ID                                               #
#  --mail-user specifies the email address for slurm reports (if job fails and ends only)										        #
#########################################################################################################################################

# DO NOT CHANGE THESE LINES
INPUT=${1:-input.csv}
OUTPUT=${2:-output}
GENOME=${3:-hg38} # either hg19 or hg38
OA_ITAG_DIR=${4:-/mnt/bioinfnas/immuno/plevy/proj/hmftools/oncoanalyser-wrapper} # path to this directory, change if required
bash ${OA_ITAG_DIR}/RUN.oncoanalyser_${GENOME}.sh ${INPUT} ${OUTPUT}

#!/bin/bash
#SBATCH --mem=8gb # Job memory request
#SBATCH -c 1 # max nr threads
#SBATCH --time=2-00:00:00           # Time limit hrs:min:sec
#SBATCH --output=R-%x.%j.out   # Standard output and error log
#SBATCH --error=R-%x.%j.err
#SBATCH --partition=highmem
#SBATCH --mail-user=plevy@vhio.net
#SBATCH --mail-type=FAIL,END

### INSTRUCTIONS TO RUN #############################################################################################################
#  Modify following command and copy/paste in cluster terminal (modify job name and input/output as explained below)				#
#																																	#
#  sbatch -J OA-TIL0XX RUN.oncoanalyser.slurm input.csv output genome																		#
#																																	#
#  /path/to/input.csv  	absolute path to input.csv file																				#
#  /path/to/output_dir  absolute path to desired output directory																	#
#  -J specifies the job name and .out and .err slurm outputs, change TIL0XX by patient ID											#
#####################################################################################################################################

# DO NOT CHANGE THESE LINES
INPUT=${1}
OUTPUT=${2}
GENOME=${3} # either hg19 or hg38
bash /mnt/bioinfnas/immuno/plevy/proj/hmftools/scripts/RUN.oncoanalyser_${GENOME}.sh ${INPUT} ${OUTPUT}

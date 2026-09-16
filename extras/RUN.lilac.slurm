#!/bin/bash
#SBATCH --mem=20gb # Job memory request
#SBATCH -c 6 # max nr threads
#SBATCH --time=5:00:00           # Time limit hrs:min:sec
#SBATCH --output=R-%x.%j.out   # Standard output and error log
#SBATCH --error=R-%x.%j.err
#SBATCH --partition=highmem

# VARIABLES TO CHANGE #############################################################
sample_name=PATIENT # <<<<<<<<<<<---------------- SAMPLE NAME (ALWAYS CHANGE)     #
###################################################################################

# VARIABLES TO CHECK (Change only if required) #####################################################################################################
data=/mnt/bioinfnas/immuno/plevy/proj/hmftools/${sample_name}/output/${sample_name} # <<<<<<<<<<<---------------- PATH OF ONCOANALYSER OUTPUTS
ref_genome_version=38 # <<<<<<<<<<<---------------- 37 or 38
output_dir=lilac_detailed # will be created automatically
sample_id=${sample_name}T # <<<<<<< Double check, same as in input.csv
normal_id=${sample_name}N # <<<<<<< Double check normal sample ID
threads=6 # Should match SBATCH -c setting
####################################################################################################################################################

# VARIABLES TO KEEP (Only change if you know what you're doing!) ###################################################################################
tumor_bam=/data/alignments/dna/${sample_id}.redux.bam
normal_bam=/data/alignments/dna/${normal_id}.redux.bam
somatic_vcf=/data/purple/${sample_id}.purple.somatic.vcf.gz
gene_copy_number=/data/purple/${sample_id}.purple.cnv.gene.tsv

if [[ "$ref_genome_version" == "37" ]]; then
	ref_genome=/ref/ref_genome/37/Homo_sapiens.GRCh37.GATK.illumina.fasta
	resource_dir=/ref/hmf_pipeline_resources.37_v2.0--3/misc/lilac
	ref_genome_version_arg=V37
elif [[ "$ref_genome_version" == "38" ]]; then
	ref_genome=/ref/ref_genome/38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
	resource_dir=/ref/hmf_pipeline_resources.38_v2.0--3/misc/lilac
	ref_genome_version_arg=V38
else
    echo "Unsupported ref_genome_version: $ref_genome_version"
    exit 1
fi
###########################################################################################################################################

# Create Lilac output dir
mkdir -p ${data}/${output_dir}

# Run Lilac with maximum detail
docker run --rm \
    -v ${PWD}:/work \
    -w /work \
    -v ${data}:/data \
    -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools:/tools \
    -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref:/ref \
    openjdk:latest \
    java \
    -Xmx16G \
    -jar /tools/lilac_v1.7.3.jar \
    \
    -sample ${sample_id} \
    -ref_genome ${ref_genome} \
    -ref_genome_version ${ref_genome_version_arg} \
    -resource_dir ${resource_dir} \
    -output_dir /data/${output_dir} \
    -reference_bam ${normal_bam} \
    -tumor_bam ${tumor_bam} \
    -somatic_vcf ${somatic_vcf} \
    -gene_copy_number ${gene_copy_number} \
    -threads ${threads} \
    -log_level DEBUG \
    -write_types ALL

echo "Lilac completed. Output files in: ${data}/${output_dir}"
echo "Key output files:"
echo "  - ${sample_id}.lilac.tsv                      : HLA allele calls summary"
echo "  - ${sample_id}.lilac.candidates.coverage.tsv  : Top ranked solutions"
echo "  - ${sample_id}.lilac.qc.tsv                   : Quality control metrics"
echo "  - ${sample_id}.lilac.somatic.vcf.gz           : Annotated somatic variants"
echo "  - ${sample_id}.lilac.fragments.csv            : Fragment details (ALL mode)"
echo "  - ${sample_id}.lilac.HLA-*.aminoacids.txt     : Amino acid matrices"
echo "  - ${sample_id}.lilac.HLA-*.nucleotides.txt    : Nucleotide matrices"

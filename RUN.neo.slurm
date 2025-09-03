#!/bin/bash
#SBATCH --job-name=neo_PATIENT    # Job name <<<<<<<<<<<---------------- ALWAYS CHANGE
#SBATCH --mem=20gb # Job memory request
#SBATCH -c 1 # max nr threads
#SBATCH --time=5:00:00           # Time limit hrs:min:sec
#SBATCH --output=R-%x.%j.out   # Standard output and error log
#SBATCH --error=R-%x.%j.err
#SBATCH --partition=highmem

# VARIABLES TO CHANGE ########################################################################################################################################
sample_name=PATIENT # <<<<<<<<<<<---------------- SAMPLE NAME (ALWAYS CHANGE)
##############################################################################################################################################################

# VARIABLES TO CHECK (Change only if required) ###############################################################################################################
rna_analysis=yes # <<<<<<<<<<<---------------- CHANGE TO "no" if DNA only analysis
flanks_size=15 # <<<<<<<<<<<---------------- flank+MUT+flank (15 generates 31mers, 12 generates 25mers...)
data=/mnt/bioinfnas/immuno/plevy/proj/hmftools/${sample_name}/output/${sample_name} # <<<<<<<<<<<---------------- PATH OF ONCOANALYSER OUTPUTS
ref_genome_version=38 # <<<<<<<<<<<---------------- 37 or 38
output_dir=neo_31 # created automatically
sample_id=${sample_name}T
rna_sample_id=${sample_id}_RNA # <<<<<<< Double check that one, sometimes {sample_id}RNA (without "_")
##############################################################################################################################################################

# VARIABLES TO KEEP (Only change if you know what you're doing!) ##############################################################################################
purple_sv_vcf=/data/purple/${sample_id}.purple.sv.vcf.gz
purple_somatic_vcf=/data/purple/${sample_id}.purple.somatic.vcf.gz
sample_rna_bam=/data/alignments/rna/${rna_sample_id}.md.bam
sage_rna_vcf=/data/sage/append/${sample_id}.sage.append.vcf.gz

cancer_type=Skin

if [[ "$ref_genome_version" == "37" ]]; then
	ref_genome=/ref/ref_genome/37/Homo_sapiens.GRCh37.GATK.illumina.fasta
	ensembl_dir=/ref/hmf_pipeline_resources.37_v2.0--3/common/ensembl_data
	known_fusion_file=/ref/hmf_pipeline_resources.37_v2.0--3/dna/sv/known_fusion_data.37.csv
	cohort_tpm_medians=/ref/neo/hmf_tpm_medians.37.csv
elif [[ "$ref_genome_version" == "38" ]]; then
	ref_genome=/ref/ref_genome/38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
	ensembl_dir=/ref/hmf_pipeline_resources.38_v2.0--3/common/ensembl_data
	known_fusion_file=/ref/hmf_pipeline_resources.38_v2.0--3/dna/sv/known_fusion_data.38.csv
	cohort_tpm_medians=/ref/neo/hmf_tpm_medians.38.csv
else
    echo "Unsupported ref_genome_version: $ref_genome_version"
    exit 1
fi

purple_dir=/data/purple
isofox_dir=/data/isofox
lilac_dir=/data/lilac
binding_dir=/ref/neo/binding
###########################################################################################################################################

# Create Neo output dir
mkdir -p ${data}/${output_dir}

# LINX (for SV-fusion-derived neoepitopes)
docker run --rm \
    -v ${PWD}:/work \
    -w /work \
    -v ${data}:/data \
    -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools:/tools \
    -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref:/ref \
    openjdk:latest \
    java -jar /tools/linx_v1.25.jar \
    -sample ${sample_id} \
    -sv_vcf ${purple_sv_vcf} \
    -purple_dir ${purple_dir} \
    -ref_genome_version ${ref_genome_version} \
    -ensembl_data_dir ${ensembl_dir} \
    -known_fusion_file ${known_fusion_file} \
    -write_neo_epitopes \
    -no_vis_files \
    -output_dir /data/${output_dir}

# Run Neo to find neoepitopes
docker run --rm \
    -v ${PWD}:/work \
    -w /work \
    -v ${data}:/data \
    -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools:/tools \
    -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref:/ref \
    openjdk:latest \
    java \
    -Xmx16G \
    -jar /tools/neo_v1.2_beta.jar \
    \
    -sample ${sample_id} \
    -somatic_vcf ${purple_somatic_vcf} \
    -ref_genome ${ref_genome} \
    -ref_genome_version ${ref_genome_version} \
    -ensembl_data_dir ${ensembl_dir} \
    -output_dir /data/${output_dir} \
    -log_debug \
    -req_amino_acids ${flanks_size} \
    -linx_dir /data/${output_dir}

# Run Isofox to annotate fusions with RNA (optional)
if [ -n "$rna_analysis" ] && [ "$rna_analysis" = "yes" ]; then
    docker run --rm \
        -v ${PWD}:/work \
        -w /work \
        -v ${data}:/data \
        -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools:/tools \
        -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref:/ref \
        openjdk:latest \
        java \
        -Xmx16G \
        -jar /tools/isofox_v1.7.1.jar \
        -sample ${sample_id} \
        -functions NEO_EPITOPES \
        -neo_dir /data/${output_dir} \
        -bam_file ${sample_rna_bam} \
        -ref_genome ${ref_genome} \
        -ref_genome_version ${ref_genome_version} \
        -ensembl_data_dir ${ensembl_dir} \
        -output_dir ${isofox_dir} \
        -log_debug
fi

# Finally Neo-Scorer

if [ -n "$rna_analysis" ] && [ "$rna_analysis" = "yes" ]; then
    docker run --rm \
        -v ${PWD}:/work \
        -w /work \
        -v ${data}:/data \
        -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools:/tools \
        -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref:/ref \
        openjdk:latest \
        java \
        -Xmx16G \
        -cp /tools/neo_v1.2_beta.jar com.hartwig.hmftools.neo.score.NeoScorer\
        -sample ${sample_id} \
        -rna_sample ${rna_sample_id} \
        -cancer_type ${cancer_type} \
        -neo_dir /data/${output_dir} \
        -isofox_dir ${isofox_dir} \
        -lilac_dir ${lilac_dir} \
        -purple_dir ${purple_dir} \
        -rna_somatic_vcf ${sage_rna_vcf} \
        -ensembl_data_dir ${ensembl_dir} \
        -score_file_dir ${binding_dir} \
        -cancer_tpm_medians_file ${cohort_tpm_medians} \
        -rank_threshold 0 \
        -write_types "ALLELE_PEPTIDE;NEOEPITOPE" \
        -output_dir /data/${output_dir} \
        -log_debug
else
    docker run --rm \
        -v ${PWD}:/work \
        -w /work \
        -v ${data}:/data \
        -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools:/tools \
        -v /mnt/bioinfnas/immuno/Jonatan/References/hmftools_ref:/ref \
        openjdk:latest \
        java \
        -Xmx16G \
        -cp /tools/neo_v1.2_beta.jar com.hartwig.hmftools.neo.score.NeoScorer\
        -sample ${sample_id} \
        -cancer_type ${cancer_type} \
        -neo_dir /data/${output_dir} \
        -lilac_dir ${lilac_dir} \
        -purple_dir ${purple_dir} \
        -ensembl_data_dir ${ensembl_dir} \
        -score_file_dir ${binding_dir} \
        -cancer_tpm_medians_file ${cohort_tpm_medians} \
        -rank_threshold 0 \
        -write_types "ALLELE_PEPTIDE;NEOEPITOPE" \
        -output_dir /data/${output_dir} \
        -log_debug
fi

# Add ProximalVariant column to the neoepitope file (indicates if there is another variant potentially in the same epitope)
python3 add_neighbor.py ${data}/${output_dir}/${sample_id}.neo.neoepitope.tsv ${data}/${output_dir}/${sample_id}.neo.neoepitope.final.tsv ${flanks_size}

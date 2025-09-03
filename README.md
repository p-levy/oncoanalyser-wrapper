# Run nf-core/oncoanalyser

⚠️ Always refer to official [nf-co.re/oncoanalyser](https://nf-co.re/oncoanalyser) website for detailed documentation about the pipeline and its different running options. 

Here, we provide a **wrapper** to run the whole-genome (`wgts`) mode of the pipeline on an HPC using `sbatch` ([slurm workload manager](https://slurm.schedmd.com/documentation.html))

## How to run oncoanalyser
- Create a working directory to copy your input files and scripts
    - Example: `mkdir PATIENT_X && cd PATIENT_X`

- Create an `input.csv` file in your working directory (e.g. in your `PATIENT_X` dir) as the following example:
```
group_id,subject_id,sample_id,sample_type,sequence_type,filetype,info,filepath
patient1,patient1,patient1N,normal,dna,fastq,library_id:patient1N;lane:1,/mnt/petasan_immuno/raw_data/itag/VHIO/patient1/Fastq/patient1_Normal_1.fastq.gz;/mnt/petasan_immuno/raw_data/itag/VHIO/patient1/Fastq/patient1_Normal_2.fastq.gz
patient1,patient1,patient1T,tumor,dna,fastq,library_id:patient1T;lane:1,/mnt/petasan_immuno/raw_data/itag/VHIO/patient1/Fastq/patient1_Tumor_DNA_1.fastq.gz;/mnt/petasan_immuno/raw_data/itag/VHIO/patient1/Fastq/patient1_Tumor_DNA_2.fastq.gz
patient1,patient1,patient1T_RNA,tumor,rna,fastq,library_id:patient1T_RNA;lane:1,/mnt/petasan_immuno/raw_data/itag/VHIO/patient1/Fastq/patient1_Tumor_RNA_1.fastq.gz;/mnt/petasan_immuno/raw_data/itag/VHIO/patient1/Fastq/patient1_Tumor_RNA_2.fastq.gz
patient2,patient2,patient2N,normal,dna,fastq,library_id:patient2N;lane:1,/mnt/petasan_immuno/raw_data/itag/VHIO/patient2/Fastq/patient2_Normal_1.fastq.gz;/mnt/petasan_immuno/raw_data/itag/VHIO/patient2/Fastq/patient2_Normal_2.fastq.gz
patient2,patient2,patient2T,tumor,dna,fastq,library_id:patient2T;lane:1,/mnt/petasan_immuno/raw_data/itag/VHIO/patient2/Fastq/patient2_Tumor_DNA_1.fastq.gz;/mnt/petasan_immuno/raw_data/itag/VHIO/patient2/Fastq/patient2_Tumor_DNA_2.fastq.gz
patient2,patient2,patient2T_RNA,tumor,rna,fastq,library_id:patient2T_RNA;lane:1,/mnt/petasan_immuno/raw_data/itag/VHIO/patient2/Fastq/patient2_Tumor_RNA_1.fastq.gz;/mnt/petasan_immuno/raw_data/itag/VHIO/patient2/Fastq/patient2_Tumor_RNA_2.fastq.gz
patient3,patient3,patient3N,normal,dna,fastq,library_id:patient3N;lane:1,/mnt/petasan_immuno/raw_data/itag/VHIO/patient3/Fastq/patient3_Normal_1.fastq.gz;/mnt/petasan_immuno/raw_data/itag/VHIO/patient3/Fastq/patient3_Normal_2.fastq.gz
patient3,patient3,patient3T,tumor,dna,fastq,library_id:patient3T;lane:1,/mnt/petasan_immuno/raw_data/itag/VHIO/patient3/Fastq/patient3_Tumor_DNA_1.fastq.gz;/mnt/petasan_immuno/raw_data/itag/VHIO/patient3/Fastq/patient3_Tumor_DNA_2.fastq.gz
patient3,patient3,patient3T_RNA,tumor,rna,fastq,library_id:patient3T_RNA;lane:1,/mnt/petasan_immuno/raw_data/itag/VHIO/patient3/Fastq/patient3_Tumor_RNA_1.fastq.gz;/mnt/petasan_immuno/raw_data/itag/VHIO/patient3/Fastq/patient3_Tumor_RNA_2.fastq.gz
```

- Copy a version of the `RUN.oncoanalyser.slurm` script in your working directory

- Run the `RUN.oncoanalyser.slurm` script using `sbatch` as follows:
```bash
sbatch -J OA-patient_X --mail-user=your.email@domain.com RUN.oncoanalyser.slurm input.csv output genome	path/to/oncoanalyser-itag
```

- Modify the following variables before running:
    - `OA-patient_X`: replace by desired slurm job name
    - `your.email@domain.com`: replace by your email address
    - `output`: path to desired output (leave `output` for default name)
    - `genome`: **hg38** or **hg19**
    - `path/to/oncoanalyser-itag`: point to where you `git clone`'d this repo

<br>

### Important considerations
> - 🚨 This wrapper is prepared to run on [VHIO](https://www.vhio.net)'s cluster. If running on a different system, you'll have to **modify the paths** to **references and singularity images** in the `hmf.local.config`, `RUN.oncoanalyser_hg19.sh` and `RUN.oncoanalyser_hg38.sh` files. 🚨

> - 🧬 So far, this wrapper runs the **whole-genome** (`--mode wgts`) version of oncoanalyser. The **exome** (`--mode targeted`) version is currently still under development. As a **consequence**, **purity, ploidy, and CNV calls from `PURPLE`** should not be considered as reliable.

## How to run `NEO`

- Copy a version of the `RUN.neo.slurm` script in your working directory

- Modify the following variables in the copied `RUN.neo.slurm` script: 

```bash
# VARIABLES TO CHANGE #############################################################
sample_name=PATIENT # <<<<<<------ SAMPLE NAME (ALWAYS CHANGE)                    #
###################################################################################
```
```bash
# VARIABLES TO CHECK (Change only if required) #####################################################################################################
rna_analysis=yes # <<<<<<<<<<<---------------- CHANGE TO "no" if DNA only analysis
flanks_size=15 # <<<<<<<<<<<---------------- flank+MUT+flank (15 generates 31mers, 12 generates 25mers...)
data=/mnt/bioinfnas/immuno/plevy/proj/hmftools/${sample_name}/output/${sample_name} # <<<<<<<<<<<---------------- PATH OF ONCOANALYSER OUTPUTS
ref_genome_version=38 # <<<<<<<<<<<---------------- 37 or 38
output_dir=neo_31 # will be created automatically
sample_id=${sample_name}T # <<<<<<< Double check, same as in input.csv
rna_sample_id=${sample_id}_RNA # <<<<<<< Double check that one, sometimes {sample_id}RNA (without "_")
####################################################################################################################################################
```

- Run the `RUN.neo.slurm` script using `sbatch` as follows:
```bash
sbatch -J NEO-patient_X RUN.neo.slurm # Replace NEO-patient_X by desired slurm job name
```

### Important consideration
> - 🚨 This wrapper is prepared to run on [VHIO](https://www.vhio.net)'s cluster. If running on a different system, you'll have to **modify the paths** to **references** in the `RUN.neo.slurm` file. 🚨
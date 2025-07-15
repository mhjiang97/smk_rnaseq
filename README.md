# SMK_RNASEQ

![License GPLv3](https://img.shields.io/badge/License-GPLv3-blue.svg)

A Snakemake workflow for RNA-seq analysis

## Recommended Project Structure

```text
project/
├── analysis/              # Output directory
|   └── rnaseq/
|       ├── fastp/                 # Trimmed reads
|       ├── fastqc/
|       |   └── fastp/                 # QC reports after trimming
|       ├── haplotypecaller/       # Variant calling with HaplotypeCaller
|       ├── multiqc/
|       |   └── fastp/                 # Aggregated QC reports
|       ├── salmon/                # Transcript quantification
|       └── star/                  # Alignment with STAR
├── code/
│   └── rnaseq/
│       └── smk_rnaseq/            # This workflow
├── data/                  # Raw input data
|   └── rnaseq/
|       ├── *.fq.gz                # Single-end reads
|       ├── *_R1.fq.gz             # Paired-end forward reads
|       └── *_R2.fq.gz             # Paired-end reverse reads
└── doc/
```

## Prerequisites

- [**Python**](https://www.python.org)
- [**Snakemake**](https://snakemake.github.io) (tested on 9.8.0)
- [**eido**](https://pep.databio.org/eido/)
- [**SAMtools**](https://www.htslib.org)
- [**Mamba**](https://mamba.readthedocs.io/en/latest/) (recommended) or [**conda**](https://docs.conda.io/projects/conda/en/stable/)

Additional dependencies are automatically installed by **Mamba** or **conda**. Environments are defined in yaml files under `workflow/envs/`.

- [**BCFtools**](http://samtools.github.io/bcftools/)
- [**GATK**](https://gatk.broadinstitute.org/hc/en-us)
- [**Salmon**](https://combine-lab.github.io/salmon/)
- [**SnpEff**](https://pcingola.github.io/)
- [**SnpSift**](https://pcingola.github.io/)
- [**STAR**](https://github.com/alexdobin/STAR)
- [**vcf2maf**](https://github.com/mskcc/vcf2maf)
- [**VEP**](https://www.ensembl.org/info/docs/tools/vep/index.html)

## Quick Start

```shell
# ---------------------------------------------------------------------------- #
# Install Mamba and SAMtools manually. Since conda-packaged SAMtools           #
# occasionally encounters issues, this workflow presumes that samtools is      #
# executable within your system's PATH.                                        #
# ---------------------------------------------------------------------------- #

# Install Snakemake and eido using pipx (https://pipx.pypa.io/stable/)
pipx install snakemake
pipx inject snakemake eido

# Clone the repository
git clone https://github.com/mhjiang97/smk_rnaseq.git
cd smk_rnaseq/

# Initialize configuration
cp config/.config.yaml config/config.yaml
cp config/pep/.config.yaml config/pep/config.yaml
```

## Configuration

### Main Configuration

Edit `config/config.yaml`:

```yaml
dir_run: /home/user/projects/project_a/analysis/rnaseq
dir_data: /home/user/projects/project_a/data/rnaseq

mapper: star
quantifier: salmon
annotators:
  - vep
  - snpeff

species: homo_sapiens
genome: GRCh38

index_salmon: /home/user/doc/reference/salmon
index_star: /home/user/doc/reference/star_2.7.11b

gtf: /home/user/doc/reference/gtf/gencode.v44.annotation.gtf
fasta: /home/user/doc/reference/fasta/GRCh38.primary_assembly.genome.fa
fasta_transcriptome: /home/user/doc/reference/fasta/gencode.v44.transcripts.fa

polymorphism_known:
  - /home/user/doc/reference/igenomes/gatk/GRCh38/Annotation/GATKBundle/dbsnp_146.hg38.vcf.gz
  - /home/user/doc/reference/igenomes/gatk/GRCh38/Annotation/GATKBundle/beta/Homo_sapiens_assembly38.known_indels.vcf.gz
  - /home/user/doc/reference/igenomes/gatk/GRCh38/Annotation/GATKBundle/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
  - /home/user/doc/reference/igenomes/gatk/GRCh38/Annotation/GATKBundle/1000G_omni2.5.hg38.vcf.gz

dbsnp: /home/user/doc/reference/igenomes/gatk/GRCh38/Annotation/GATKBundle/dbsnp_146.hg38.vcf.gz

check_annotations: false
cache_vep: /home/user/.vep
cache_snpeff: /home/user/doc/snpeff
version_vep: 114
version_snpeff: "105"

min_reads: 3
min_coverage: 10

suffixes_fastq:
  paired-end:
    - "_R1.fq.gz"
    - "_R2.fq.gz"
  single-end: ".fq.gz"

clean_fq: true

run_multiqc: true
```

All default values are defined in the validation schema (`workflow/schemas/config.schema.yaml`).

### Execution Profile

Edit `workflow/profiles/default/config.yaml` that configures execution parameters including threads and resource allocation:

```yaml
software-deployment-method:
  - conda
printshellcmds: True
keep-incomplete: True
cores: 80
resources:
  mem_mb: 500000  # 500GB
set-threads:
  salmon: 4
  salmon_index: 10
  star: 10
  star_index: 10
  haplotypecaller: 10
  vep: 10
  fastp_paired_end: 4
  fastp_single_end: 4
  fastqc: 4
set-resources:
  star:
    mem_mb: 100000  # 100GB
  mark_duplicates:
    mem_mb: 50000  # 50GB
  split_n_cigar_reads:
    mem_mb: 100000  # 100GB
  base_recalibrator:
    mem_mb: 50000  # 50GB
  apply_bqsr:
    mem_mb: 50000  # 50GB
  haplotypecaller:
    mem_mb: 100000  # 50GB
  snpeff:
    mem_mb: 50000  # 50GB
```

### Sample Metadata

This workflow uses [**Portable Encapsulated Projects (PEP)**](https://pep.databio.org/) for sample management.

Edit `config/pep/config.yaml` that specifies the path to your sample table and other attributes.

The sample table must include these mandatory columns:

| **sample_name**                   | **library_layout**                                     |
| --------------------------------- | ------------------------------------------------------ |
| Unique identifier for each sample | Sequencing strategy (`"paired-end"` or `"single-end"`) |

Another validation schema (`workflow/schemas/pep.schema.yaml`) ensures that the sample table meets the required format.

## Execution

```shell
# Create environments
snakemake --conda-create-envs-only

# Run the workflow
snakemake
```

## License

The code in this repository is licensed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).

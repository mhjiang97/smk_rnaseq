<!-- markdownlint-configure-file {"no-inline-html": {"allowed_elements": ["code", "details", "h2", "summary"]}} -->

# SMK_RNASEQ

![License GPLv3](https://img.shields.io/badge/License-GPLv3-blue.svg)

A Snakemake workflow for RNA-seq analysis

<details>

<summary><h2>Recommended Project Structure</h2></summary>

```text
project/
├── analysis/
|   └── rnaseq/
|       └── ...                # Outputs of this workflow
├── code/
│   └── rnaseq/
│       └── smk_rnaseq/        # This workflow
├── data/
│   └── rnaseq/
│       ├── *.fq.gz            # Single-end reads
│       ├── *_R1.fq.gz         # Paired-end forward reads
│       └── *_R2.fq.gz         # Paired-end reverse reads
└── doc/
```

</details>

**Note:** The workflow expects all FASTQ files to be located in `dir_data` specified in `config/config.yaml`, with no sample-specific subfolders (See [Main Configuration](#main-configuration)).

**Hints:** You can create symbolic links (`ln -s source_file target_file`) pointing to original FASTQ files.

*This adapted structure enables an organized layout for each project.*

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
if ! command -v mamba &> /dev/null; then
    "${SHELL}" <(curl -L micro.mamba.pm/install.sh)
    source ~/.bashrc
fi

if ! command -v samtools &> /dev/null; then
    [ -d ${HOME}/.local/opt ] || mkdir -p ${HOME}/.local/opt
    wget 'https://github.com/samtools/samtools/releases/download/1.22.1/samtools-1.22.1.tar.bz2'
    tar -xvf samtools-1.22.1.tar.bz2
    cd samtools-1.22.1
    ./configure --prefix=${HOME}/.local/opt/samtools
    make
    make install
    echo "export PATH=\${HOME}/.local/opt/samtools/bin:\${PATH}" >> ~/.bashrc
    source ~/.bashrc
    rm -rf samtools-1.22.1 samtools-1.22.1.tar.bz2
fi

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

<details>

<summary>Edit <code>config/config.yaml</code></summary>

```yaml
dir_run: /home/user/projects/project_a/analysis/rnaseq           # Output directory (Optional)
dir_data: /home/user/projects/project_a/data/rnaseq              # Directory for raw FASTQ files (Required)

mapper: star                                                     # Alignment tool (Default: "star")
quantifier: salmon                                               # Quantification tool (Default: "salmon")
annotators:                                                      # Variant annotation tools (Defaults: ["vep", "snpeff"])
  - vep
  - snpeff

species: homo_sapiens                                            # Species (Default: "homo_sapiens")
genome: GRCh38                                                   # Genome assembly (Default: "GRCh38")

index_salmon: /reference/salmon                                  # Salmon index (Required. If doesn't exist, it will be generated)
index_star: /reference/star_2.7.11b                              # STAR index (Required. If doesn't exist, it will be generated)

gtf: /reference/gtf/gencode.v44.annotation.gtf                   # GTF file (Required)
fasta: /reference/fasta/GRCh38.primary_assembly.genome.fa        # Genome FASTA file (Required)
fasta_transcriptome: /reference/fasta/gencode.v44.transcripts.fa # Transcriptome FASTA file (Required)

polymorphism_known:                                              # Known polymorphism VCF files used by GATK BaseRecalibrator (Required)
  - /reference/GATKBundle/dbsnp_146.hg38.vcf.gz
  - /reference/GATKBundle/beta/Homo_sapiens_assembly38.known_indels.vcf.gz
  - /reference/GATKBundle/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
  - /reference/GATKBundle/1000G_omni2.5.hg38.vcf.gz

dbsnp: /reference/GATKBundle/dbsnp_146.hg38.vcf.gz               # dbSNP VCF file used by HaplotypeCaller (Required)

check_annotations: false                                         # Whether to check VCF files annotated by VEP and SnpEff by counting lines (Default: false)
cache_vep: /home/user/.vep                                       # Cache directory for VEP
cache_snpeff: /doc/snpeff                                        # Cache directory for SnpEff
version_vep: 114                                                 # VEP cache version (Default: 114)
version_snpeff: "105"                                            # SnpEff cache version (Default: "105")

min_reads: 3                                                     # Minimum number of supporting reads (Default: 3)
min_coverage: 10                                                 # Minimum coverage required for a mutation site to be considered (Default: 10)

suffixes_fastq:                                                  # Suffixes for FASTQ files (Defaults: {paired-end: ["_R1.fq.gz", "_R2.fq.gz"], single-end: ".fq.gz"})
  paired-end:
    - "_R1.fq.gz"
    - "_R2.fq.gz"
  single-end: ".fq.gz"

clean_fq: true                                                   # Whether to run Fastp to trim raw FASTQ files (Default: true)
run_fastqc: true                                                 # Whether to run FastQC to generate quality control reports (Default: true)
run_multiqc: true                                                # Whether to run MultiQC to aggregate QC reports (Default: true)
```

</details>

All default values are defined in the validation schema (`workflow/schemas/config.schema.yaml`).

### Execution Profile

<details>

<summary>Edit <code>workflow/profiles/default/config.yaml</code></summary>

```yaml
software-deployment-method:
  - conda
printshellcmds: True
keep-incomplete: True
cores: 80
resources:
  mem_mb: 500000      # 500GB
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
    mem_mb: 100000    # 100GB
  mark_duplicates:
    mem_mb: 50000     # 50GB
  split_n_cigar_reads:
    mem_mb: 100000    # 100GB
  base_recalibrator:
    mem_mb: 50000     # 50GB
  apply_bqsr:
    mem_mb: 50000     # 50GB
  haplotypecaller:
    mem_mb: 100000    # 100GB
  snpeff:
    mem_mb: 50000     # 50GB
```

</details>

### Sample Metadata

This workflow uses [**Portable Encapsulated Projects (PEP)**](https://pep.databio.org/) for sample management.

<details>

<summary>Edit <code>config/pep/config.yaml</code></summary>

```yaml
pep_version: 2.1.0
sample_table: samples.csv    # Path to the sample table (Required)
```

</details>

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

## Output

By default, all results are written to the directory you specify as `dir_run` (or to `workflow/` if `dir_run` is unset).

<details>

<summary>Main results</summary>

- **fastp/**
  - Trimmed reads: `{sample}/{sample}[_R1/_R2].fq.gz`

- **fastqc/**
  - Raw reads: `{sample}/{sample}[_1/_2]_fastqc.html`
  - Trimmed reads: `fastp/{sample}/{sample}[_1/_2]_fastqc.html`

- **multiqc/**
  - Pre-trimming summary: `multiqc_report.html`
  - Post-trimming summary: `fastp/multiqc_report.html`

- **salmon/**
  - Transcript-level abundance estimates: `{sample}/quant.sf`

- **star/**
  - Initial sorted alignment: `{sample}/{sample}.sorted.bam`
  - Final processed BAM: `{sample}/{sample}.sorted.md.splitn.recal.bam`

- **haplotypecaller/**
  - Raw calls: `{sample}/{sample}.vcf`
  - Hard-filtered variants:
    - SNVs: `{sample}/{sample}.snvs.vcf`
    - Indels: `{sample}/{sample}.indels.vcf`
  - Annotated variants:
    - SnpEff: `{sample}/{sample}.[snvs/indels].snpeff.[vcf/tsv]`
    - VEP: `{sample}/{sample}.[snvs/indels].vep.[vcf/maf]`

</details>

## License

The code in this repository is licensed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).

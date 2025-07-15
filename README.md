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

- `dir_data`: Directory containing raw FASTQ files (required)
- `index_salmon`: Path to Salmon transcriptome index (required)
- `dir_run`: Output directory (optional)
- `suffixes_fastq`: Read file naming patterns
  - `paired-end`: (Default: `["_R1.fq.gz", "_R2.fq.gz"]`)
  - `single-end`: (Default: `".fq.gz"`)
- `clean_fq`: Enable fastp read cleaning (default: `true`)
- `run_multiqc`: Generate MultiQC report (default: `true`)

All default values are defined in the validation schema (`workflow/schemas/config.schema.yaml`).

### Execution Profile

Edit `workflow/profiles/default/config.yaml` that configures execution parameters including threads and resource allocation:

- `printshellcmds`:  True
- `keep-incomplete`: True
- `cores`: 20
- `set-threads`:
  - `salmon`: 4
  - `fastp_paired_end`: 4
  - `fastp_single_end`: 4
  - `fastqc`: 4

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

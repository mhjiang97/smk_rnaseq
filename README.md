# SMK_RNASEQ

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

## Dependencies

- Python
- Snakemake (tested on 9.8.0)
- eido

Other dependencies are managed by `mamba` or `conda`.

## Setup

Install `Snakemake` and `eido` using `pipx`:

```shell
pipx install snakemake
pipx inject snakemake eido
```

Clone the repository and copy the example configuration files:

```shell
git clone https://github.com/mhjiang97/smk_rnaseq.git
cd smk_rnaseq/
cp config/.config.yaml config/config.yaml
cp config/pep/.config.yaml config/pep/config.yaml
```

## Configuration

### Config File

The main configuration file (`config/config.yaml`) contains:

- `dir_data`: Directory containing raw FASTQ files (required)
- `index_salmon`: Path to Salmon transcriptome index (required)
- `dir_run`: Output directory (optional)
- `suffixes_fastq`: Read file naming patterns
  - `paired-end`: (Default: `["_R1.fq.gz", "_R2.fq.gz"]`)
  - `single-end`: (Default: `".fq.gz"`)
- `clean_fq`: Enable fastp read cleaning (default: `true`)
- `run_multiqc`: Generate MultiQC report (default: `true`)

All default values are defined in the validation schema (`workflow/schemas/config.schema.yaml`).

### Profile

The default profile (`workflow/profiles/default/config.yaml`) configures execution parameters:

- `printshellcmds`:  True
- `keep-incomplete`: True
- `cores`: 20
- `set-threads`:
  - `salmon`: 4
  - `fastp_paired_end`: 4
  - `fastp_single_end`: 4
  - `fastqc`: 4

### Sample Metadata

This workflow uses [Portable Encapsulated Projects (PEP)](https://pep.databio.org/) to manage sample metadata.

Sample configuration (`config/pep/config.yaml`) specifies the path to your sample table and other attributes.

The sample table must include these mandatory columns:

- `sample_name`: Unique identifier for each sample (required by PEP)
- `library_layout`: Sequencing strategy, must be either `"paired-end"` or `"single-end"`

Another validation schema (`workflow/schemas/pep.schema.yaml`) ensures that the sample table meets the required format.

## Execution

After the configuration, you can create environments first:

```shell
snakemake --conda-create-envs-only
```

Then run the workflow:

```shell
snakemake
```

## License

The code in this repository is licensed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).

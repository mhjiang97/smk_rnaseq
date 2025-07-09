# SMK_RNASEQ

*A Snakemake workflow for RNA-seq analysis*

## Recommended Project Structure

```
project/
├── data/                  # Raw input data
│   └── rnaseq/
│       ├── *_R1.fq.gz             # Paired-end forward reads
│       ├── *_R2.fq.gz             # Paired-end reverse reads
│       └── *.fq.gz                # Single-end reads
├── code/
│   └── rnaseq/
│       └── smk_rnaseq/            # This workflow
└── analysis/              # Output directory
    └── rnaseq/
        ├── fastp/                 # Trimmed reads
        ├── salmon/                # Transcript quantification
        ├── fastqc/
        |   └── fastp/                 # QC reports after trimming
        └── multiqc/
            └── fastp/                 # Aggregated QC reports
```

## Setup

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

All default values are defined in the validation schema (`config/schemas/config.yaml`).

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

Another validation schema (`config/schemas/pep.yaml`) ensures that the sample table meets the required format.

## Execution

After the configuration, you can run it using Snakemake:

```shell
snakemake
```

## License

The code in this repository is licensed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).

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

mv config/.config.yaml config/config.yaml
mv config/pep/.config.yaml config/pep/config.yaml
```

## Configuration

### Config File

The main configuration file (`config/config.yaml`) contains:

- `dir_data`: Directory containing raw FASTQ files (required)
- `index_salmon`: Path to Salmon transcriptome index (required)
- `dir_run`: Output directory (optional)
- `suffix_fastq`: Read file naming patterns
  - `paired-end`: (Default: `["_R1.fq.gz", "_R2.fq.gz"]`)
  - `single-end`: (Default: `".fq.gz"`)
- `clean_fq`: Enable fastp read cleaning (default: `true`)
- `run_multiqc`: Generate MultiQC report (default: `true`)

All default values are defined in the validation schema (`config/schemas/config.yaml`).

### Execution Profile

The default profile (`workflow/profiles/default/`) configures execution parameters:
- `printshellcmds`:  True # Print out the shell commands that will be executed.
- `keep-incomplete`: True # Do not remove incomplete output files by failed jobs.
- `cores`: 20 # Use at most N CPU cores/jobs in parallel. If N is omitted or all, the limit is set to the number of available CPU cores.
- `set-threads`: # Overwrite thread usage of rules.
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

## Run the Workflow

After the configuration, you can run it using Snakemake:

```shell
snakemake
```

## License

The code in this repository is licensed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).

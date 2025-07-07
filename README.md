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
        ├── fastqc/                # QC reports
        └── multiqc/               # Aggregated QC reports
```

## Sample Table

This workflow uses [Portable Encapsulated Projects (PEP)](https://pep.databio.org/) to manage sample metadata.

### Configuration

Sample configuration is located in the `config/pep/` directory:

- `config.yaml`: Specifies the path to your sample table and any PEP project attributes

The sample table must include these mandatory columns:

- `sample_name`: Unique identifier for each sample (required by PEP)
- `library_layout`: Sequencing strategy, must be either "paired-end" or "single-end"

## License

The code in this repository is licensed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).

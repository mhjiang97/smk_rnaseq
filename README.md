# SMK_RNASEQ

*A Snakemake workflow for RNA-seq analysis*

## Recommended Project Structure

```
project/
├── data/                          # Raw sequencing data
│   └── rnaseq/
│       ├── *_R1.fq.gz             # Paired-end forward reads
│       ├── *_R2.fq.gz             # Paired-end reverse reads
│       └── *.fq.gz                # Single-end reads
├── code/
│   └── rnaseq/
│       └── smk_rnaseq/            # This workflow
└── analysis/                      # Output directory
    └── rnaseq/
        ├── fastp/                 # Trimmed reads
        ├── salmon/                # Transcript quantification
        ├── fastqc/                # Quality control reports
        └── multiqc/               # Aggregated QC reports
```

## License

The code in this repository is licensed under the [GNU General Public License v3](http://www.gnu.org/licenses/gpl-3.0.html).

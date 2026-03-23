rule filter_bam_readcount:
    conda:
        "../../envs/python.yaml"
    input:
        tsv="bam-readcount/{sample_dna}-dna/{sample}-{caller}-rna_snvs.tsv",
    output:
        bed="{caller}/{sample}/{sample}-{sample_dna}-rna_editing.bed",
    params:
        min_coverage=config["min_coverage_dna"],
        max_mutants=config["max_mutants"],
    log:
        "logs/{sample}/filter_bam_readcount.{sample_dna}.{caller}.log",
    script:
        "../../scripts/filter_bam_readcount.py"

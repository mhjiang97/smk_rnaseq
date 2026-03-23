rule bam_readcount:
    container:
        "docker://mgibio/bam-readcount:1.0.1"
    input:
        fasta=config["fasta"],
        bam=get_dna_control_bam,
        tsv="{caller}/{sample}/{sample}.snvs.tsv",
    output:
        tsv="bam-readcount/{sample_dna}-dna/{sample}-{caller}-rna_snvs.tsv",
    params:
        min_qual_mapping=config["min_qual_mapping_dna"],
        min_qual_base=config["min_qual_base_dna"],
        max_count=10000000,
    log:
        "logs/{sample}/bam_readcount.{sample_dna}.{caller}.log",
    shell:
        """
        bam-readcount \\
            -f {input.fasta} \\
            -q {params.min_qual_mapping} \\
            -b {params.min_qual_base} \\
            -d {params.max_count} \\
            -w 1 \\
            -l {input.tsv} \\
            {input.bam} \\
            1> {output.tsv} 2> {log}
        """

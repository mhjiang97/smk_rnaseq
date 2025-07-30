rule samtools_faidx:
    input:
        fasta=config["fasta"],
    output:
        fai=fai_fasta,
    log:
        "logs/samtools_faidx.log",
    shell:
        """
        samtools faidx {input.fasta} 1> {log} 2>&1
        """

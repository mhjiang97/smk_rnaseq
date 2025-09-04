rule faidx:
    input:
        fasta=config["fasta"],
    output:
        fai=fai_fasta,
    log:
        "logs/faidx.log",
    shell:
        """
        samtools faidx {input.fasta} 1> {log} 2>&1
        """

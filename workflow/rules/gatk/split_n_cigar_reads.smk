rule split_n_cigar_reads:
    conda:
        "../../envs/gatk.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.bam",
        fasta=config["fasta"],
        dict=dict_fasta,
    output:
        bam=protected(f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.bam"),
        bai=temp(f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.bai"),
        bai_renamed=protected(
            f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.bam.bai"
        ),
    resources:
        mem_mb=1,
        tmpdir=lambda wildcards: f"{MAPPER}/{wildcards.sample}",
    log:
        "logs/{sample}/split_n_cigar_reads.log",
    shell:
        """
        {{ gatk SplitNCigarReads \\
            --java-options \"-Xmx{resources.mem_mb}M -XX:-UsePerfData\" \\
            -R {input.fasta} -I {input.bam} -O {output.bam} \\
            --create-output-bam-index true --tmp-dir {resources.tmpdir}

        cp {output.bai} {output.bai_renamed}
        touch {output.bai_renamed}; }} \\
        1> {log} 2>&1
        """

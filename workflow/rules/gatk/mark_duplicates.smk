rule mark_duplicates:
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.bam",
        fasta=config["fasta"],
    output:
        bam=protected(f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.bam"),
        bai=temp(f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.bai"),
        bai_renamed=protected(f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.bam.bai"),
        metrics=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.metrics.txt",
    log:
        "logs/{sample}/mark_duplicates.log",
    conda:
        "../../envs/gatk.yaml"
    resources:
        tmpdir=lambda wildcards: f"{MAPPER}/{wildcards.sample}",
    shell:
        """
        {{ gatk MarkDuplicates \\
            --java-options \"-Xmx{resources.mem_mb}M -XX:-UsePerfData\" \\
            --INPUT {input.bam} \\
            --OUTPUT {output.bam} \\
            --METRICS_FILE {output.metrics} \\
            --REMOVE_DUPLICATES false \\
            --CREATE_INDEX true \\
            --ASSUME_SORT_ORDER coordinate \\
            --REFERENCE_SEQUENCE {input.fasta} \\
            --TMP_DIR {resources.tmpdir}

        cp {output.bai} {output.bai_renamed}
        touch {output.bai_renamed}; }} \\
        1> {log} 2>&1
        """

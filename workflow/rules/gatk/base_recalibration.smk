rule base_recalibrator:
    input:
        config["polymorphism_known"],
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.bam",
        fasta=config["fasta"],
    output:
        table=protected(f"{MAPPER}/{{sample}}/{{sample}}.recal.table"),
    log:
        "logs/{sample}/base_recalibrator.log",
    conda:
        "../../envs/gatk.yaml"
    resources:
        tmpdir=lambda wildcards: f"{MAPPER}/{wildcards.sample}",
    params:
        arg_known_sites=" ".join(
            [f"--known-sites {site}" for site in config["polymorphism_known"]]
        ),
    shell:
        """
        gatk BaseRecalibrator \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --input {input.bam} \\
            --output {output.table} \\
            --reference {input.fasta} \\
            {params.arg_known_sites} \\
            --tmp-dir {resources.tmpdir} \\
            1> {log} 2>&1
        """


rule apply_bqsr:
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.bam",
        table=f"{MAPPER}/{{sample}}/{{sample}}.recal.table",
        fasta=config["fasta"],
    output:
        bam=protected(f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.recal.bam"),
        bai=temp(f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.recal.bai"),
        bai_renamed=protected(
            f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.recal.bam.bai"
        ),
    log:
        "logs/{sample}/apply_bqsr.log",
    conda:
        "../../envs/gatk.yaml"
    resources:
        tmpdir=lambda wildcards: f"{MAPPER}/{wildcards.sample}",
    shell:
        """
        {{ gatk ApplyBQSR \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --input {input.bam} \\
            --output {output.bam} \\
            --reference {input.fasta} \\
            --bqsr-recal-file {input.table} \\
            --tmp-dir {resources.tmpdir}

        cp {output.bai} {output.bai_renamed}
        touch {output.bai_renamed}; }} \\
        1> {log} 2>&1
        """

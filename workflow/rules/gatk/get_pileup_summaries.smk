rule get_pileup_summaries:
    conda:
        "../../envs/gatk.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.recal.bam",
        bed="ref/interval/{scatteritem}.bed",
        fasta=config["fasta"],
        resource_germline=config["resource_germline"],
    output:
        table="mutect2/{sample}/scatters/{scatteritem}.pileups.table",
    params:
        args=get_extra_arguments("get_pileup_summaries"),
    log:
        "logs/{sample}/get_pileup_summaries.{scatteritem}.log",
    resources:
        mem_mb=lambda wildcards, input, attempt: get_pileup_summaries_mem_mb(
            input.bam, attempt
        ),
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
    shell:
        """
        gatk GetPileupSummaries \\
            {params.args} \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --input {input.bam} \\
            --variant {input.resource_germline} \\
            --reference {input.fasta} \\
            --intervals {input.bed} \\
            --output {output.table} \\
            --tmp-dir {resources.tmpdir} \\
            > {log} 2>&1
        """


rule get_pileup_summaries_dna:
    conda:
        "../../envs/gatk.yaml"
    input:
        bam=get_dna_control_bam,
        bed="ref/interval/{scatteritem}.bed",
        fasta=config["fasta"],
        resource_germline=config["resource_germline"],
    output:
        table="mutect2/{sample_dna}-dna/scatters/{scatteritem}.pileups.table",
    params:
        args=get_extra_arguments("get_pileup_summaries_dna"),
    log:
        "logs/{sample_dna}-dna/get_pileup_summaries_dna.{scatteritem}.log",
    resources:
        mem_mb=lambda wildcards, input, attempt: get_pileup_summaries_mem_mb(
            input.bam, attempt
        ),
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample_dna}-dna",
    shell:
        """
        gatk GetPileupSummaries \\
            {params.args} \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --input {input.bam} \\
            --variant {input.resource_germline} \\
            --reference {input.fasta} \\
            --intervals {input.bed} \\
            --output {output.table} \\
            --tmp-dir {resources.tmpdir} \\
            > {log} 2>&1
        """

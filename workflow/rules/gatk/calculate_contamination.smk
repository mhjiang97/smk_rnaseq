rule get_pileup_summaries:
    conda:
        "../../envs/gatk.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.recal.bam",
        bed=get_interval_bed(),
        fasta=config["fasta"],
        resource_germline=config["resource_germline"],
    output:
        table="mutect2/{sample}/{sample}.pileups.table",
    params:
        args=get_extra_arguments("get_pileup_summaries"),
    log:
        "logs/{sample}/get_pileup_summaries.log",
    threads: 1
    resources:
        mem_mb=1,
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
        bed=get_interval_bed(),
        fasta=config["fasta"],
        resource_germline=config["resource_germline"],
    output:
        table="mutect2/{sample_dna}-dna/{sample_dna}.pileups.table",
    params:
        args=get_extra_arguments("get_pileup_summaries_dna"),
    log:
        "logs/{sample_dna}-dna/get_pileup_summaries_dna.log",
    threads: 1
    resources:
        mem_mb=8000,
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


rule calculate_contamination:
    conda:
        "../../envs/gatk.yaml"
    input:
        unpack(get_calculate_contamination_inputs),
    output:
        table="mutect2/{sample}/{sample}.contamination.table",
        segmentation="mutect2/{sample}/{sample}.segmentation.table",
    params:
        args_dna=get_calculate_contamination_arguments,
        args=get_extra_arguments("calculate_contamination"),
    log:
        "logs/{sample}/calculate_contamination.log",
    threads: 1
    resources:
        mem_mb=1,
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
    shell:
        """
        gatk CalculateContamination \\
            {params.args} \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --input {input.table} \\
            {params.args_dna} \\
            --output {output.table} \\
            --tumor-segmentation {output.segmentation} \\
            --tmp-dir {resources.tmpdir} \\
            > {log} 2>&1
        """

rule gather_pileup_summaries:
    input:
        tables=gather.split_bed(
            "mutect2/{{sample}}/scatters/{scatteritem}.pileups.table"
        ),
        _dict=dict_fasta,
    output:
        table="mutect2/{sample}/{sample}.pileups.table",
    log:
        "logs/{sample}/gather_pileup_summaries.log",
    conda:
        "../../envs/gatk.yaml"
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}/scatters",
    params:
        inputs=lambda wildcards, input: " ".join(
            f"--I {table}" for table in input.tables
        ),
    shell:
        """
        gatk GatherPileupSummaries \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            {params.inputs} \\
            --O {output.table} \\
            --sequence-dictionary {input._dict} \\
            --tmp-dir {resources.tmpdir} \\
            1> {log} 2>&1
        """


rule gather_pileup_summaries_dna:
    input:
        tables=gather.split_bed(
            "mutect2/{{sample_dna}}-dna/scatters/{scatteritem}.pileups.table"
        ),
        _dict=dict_fasta,
    output:
        table="mutect2/{sample_dna}-dna/{sample_dna}.pileups.table",
    log:
        "logs/{sample_dna}-dna/gather_pileup_summaries_dna.log",
    conda:
        "../../envs/gatk.yaml"
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample_dna}-dna/scatters",
    params:
        inputs=lambda wildcards, input: " ".join(
            f"--I {table}" for table in input.tables
        ),
    shell:
        """
        gatk GatherPileupSummaries \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            {params.inputs} \\
            --O {output.table} \\
            --sequence-dictionary {input._dict} \\
            --tmp-dir {resources.tmpdir} \\
            1> {log} 2>&1
        """

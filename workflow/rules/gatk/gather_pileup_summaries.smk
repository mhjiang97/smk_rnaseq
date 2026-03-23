rule gather_pileup_summaries:
    conda:
        "../../envs/gatk.yaml"
    input:
        tables=gather.split_bed(
            "mutect2/{{sample}}/scatters/{scatteritem}.pileups.table"
        ),
        _dict=dict_fasta,
    output:
        table="mutect2/{sample}/{sample}.pileups.table",
    params:
        inputs=lambda wildcards, input: " ".join(
            f"--I {table}" for table in input.tables
        ),
    log:
        "logs/{sample}/gather_pileup_summaries.log",
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}/scatters",
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
    conda:
        "../../envs/gatk.yaml"
    input:
        tables=gather.split_bed(
            "mutect2/{{sample_dna}}-dna/scatters/{scatteritem}.pileups.table"
        ),
        _dict=dict_fasta,
    output:
        table="mutect2/{sample_dna}-dna/{sample_dna}.pileups.table",
    params:
        inputs=lambda wildcards, input: " ".join(
            f"--I {table}" for table in input.tables
        ),
    log:
        "logs/{sample_dna}-dna/gather_pileup_summaries_dna.log",
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample_dna}-dna/scatters",
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

rule mutect2:
    conda:
        "../../envs/gatk.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.recal.bam",
        bed=(
            bed_transcript_slopped if config["slop_transcript"] > 0 else bed_transcript
        ),
        fasta=config["fasta"],
        resource_germline=config["resource_germline"],
        pon=config["pon"],
    output:
        vcf="mutect2/{sample}/{sample}.raw.vcf",
        f1r2="mutect2/{sample}/{sample}.f1r2.tar.gz",
    params:
        min_coverage=config["min_coverage"],
        min_qual_mapping=config["min_qual_mapping"],
        args=get_extra_arguments("mutect2"),
    log:
        "logs/{sample}/mutect2.log",
    threads: 1
    resources:
        mem_mb=1,
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
    shell:
        """
        gatk Mutect2 \\
            {params.args} \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData
            --native-pair-hmm-threads {threads} \\
            -R {input.fasta} -I {input.bam} -O {output.vcf} \\
            -L {input.bed} \\
            --f1r2-tar-gz {output.f1r2} \\
            --callable-depth {params.min_coverage} \\
            --f1r2-min-bq {params.min_qual_mapping} \\
            --germline-resource {input.resource_germline} \\
            --panel-of-normals {input.pon} \\
            --dont-use-soft-clipped-bases true \\
            --tmp-dir {resources.tmpdir} \\
            > {log} 2>&1
        """


rule filter_mutect_calls:
    conda:
        "../../envs/gatk.yaml"
    input:
        vcf="mutect2/{sample}/{sample}.raw.vcf",
        bed=(
            bed_transcript_slopped if config["slop_transcript"] > 0 else bed_transcript
        ),
        fasta=config["fasta"],
    output:
        vcf=protected("mutect2/{sample}/{sample}.vcf"),
        table_contamination="mutect2/{sample}/{sample}.contamination.table",
        table_segmentation="mutect2/{sample}/{sample}.segmentation.table",
    params:
        args=get_extra_arguments("filter_mutect_calls"),
    resources:
        mem_mb=1,
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
    log:
        "logs/{sample}/filter_mutect_calls.log",
    shell:
        """
        gatk FilterMutectCalls \\
            {params.args} \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData
            -R {input.fasta} -V {input.vcf} -O {output.vcf} \\
            -L {input.bed} \\
            --contamination-table {output.table_contamination} \\
            --tumor-segmentation {output.table_segmentation} \\
            --tmp-dir {resources.tmpdir} \\
            > {log} 2>&1
        """

rule mutect2:
    conda:
        "../../envs/gatk.yaml"
    input:
        unpack(get_mutect2_inputs),
    output:
        vcf="mutect2/{sample}/{sample}.raw.vcf",
        f1r2="mutect2/{sample}/{sample}.f1r2.tar.gz",
    params:
        min_coverage=config["min_coverage"],
        min_qual_mapping=config["min_qual_mapping"],
        arg_dna=get_mutect2_arguments,
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
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --native-pair-hmm-threads {threads} \\
            -R {input.fasta} \\
            -I {input.bam} \\
            {params.arg_dna} \\
            -O {output.vcf} \\
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
        unpack(get_filter_mutect_calls_inputs),
    output:
        vcf=protected("mutect2/{sample}/{sample}.vcf"),
    params:
        arg_orientation=get_filter_mutect_calls_arguments,
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
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --reference {input.fasta} \\
            --variant {input.vcf} \\
            --output {output.vcf} \\
            --intervals {input.bed} \\
            {params.arg_orientation} \\
            --contamination-table {input.table_contamination} \\
            --tumor-segmentation {input.table_segmentation} \\
            --tmp-dir {resources.tmpdir} \\
            > {log} 2>&1
        """

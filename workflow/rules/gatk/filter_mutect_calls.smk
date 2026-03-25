rule filter_mutect_calls:
    input:
        unpack(get_filter_mutect_calls_inputs),
    output:
        vcf=temp("mutect2/{sample}/{sample}.filtered.vcf"),
    log:
        "logs/{sample}/filter_mutect_calls.log",
    conda:
        "../../envs/gatk.yaml"
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
    params:
        arg_orientation=get_filter_mutect_calls_arguments,
        args=get_extra_arguments("filter_mutect_calls"),
    shell:
        """
        gatk FilterMutectCalls \\
            {params.args} \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --reference {input.fasta} \\
            --variant {input.vcf} \\
            --stats {input.stats} \\
            --output {output.vcf} \\
            --intervals {input.bed} \\
            {params.arg_orientation} \\
            --contamination-table {input.table_contamination} \\
            --tumor-segmentation {input.table_segmentation} \\
            --tmp-dir {resources.tmpdir} \\
            1> {log} 2>&1
        """


rule format_mutect2:
    input:
        vcf="mutect2/{sample}/{sample}.filtered.vcf",
    output:
        vcf=protected("mutect2/{sample}/{sample}.vcf"),
    log:
        "logs/{sample}/format_mutect2.log",
    conda:
        "../../envs/bcftools.yaml"
    shell:
        """
        bcftools annotate \\
            --set-id +'%CHROM\\_%POS\\_%REF\\_%FIRST_ALT' \\
            {input.vcf} \\
            1> {output.vcf} 2> {log}
        """

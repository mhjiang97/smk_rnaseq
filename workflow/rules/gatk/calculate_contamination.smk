rule calculate_contamination:
    input:
        unpack(get_calculate_contamination_inputs),
    output:
        table="mutect2/{sample}/{sample}.contamination.table",
        segmentation="mutect2/{sample}/{sample}.segmentation.table",
    log:
        "logs/{sample}/calculate_contamination.log",
    conda:
        "../../envs/gatk.yaml"
    threads: 1
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
    params:
        args_dna=get_calculate_contamination_arguments,
        args=get_extra_arguments("calculate_contamination"),
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

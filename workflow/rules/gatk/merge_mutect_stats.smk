rule merge_mutect_stats:
    conda:
        "../../envs/gatk.yaml"
    input:
        gather.split_bed("mutect2/{{sample}}/scatters/{scatteritem}.raw.vcf.stats"),
    output:
        stats="mutect2/{sample}/{sample}.raw.vcf.stats",
    params:
        inputs=lambda wildcards, input: " ".join(
            f"--stats {stats}" for stats in input
        ),
    log:
        "logs/{sample}/merge_mutect_stats.log",
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
    shell:
        """
        gatk MergeMutectStats \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            {params.inputs} \\
            --output {output.stats} \\
            --tmp-dir {resources.tmpdir} \\
            1> {log} 2>&1
        """

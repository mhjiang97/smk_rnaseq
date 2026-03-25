rule gather_vcfs:
    input:
        vcfs=gather.split_bed("mutect2/{{sample}}/scatters/{scatteritem}.raw.vcf"),
        fasta=config["fasta"],
    output:
        vcf="mutect2/{sample}/{sample}.raw.vcf",
    log:
        "logs/{sample}/gather_vcfs.log",
    conda:
        "../../envs/gatk.yaml"
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
    params:
        inputs=lambda wildcards, input: " ".join(f"--INPUT {vcf}" for vcf in input.vcfs),
    shell:
        """
        gatk GatherVcfs \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            {params.inputs} \\
            --REFERENCE_SEQUENCE {input.fasta} \\
            --OUTPUT {output.vcf} \\
            --TMP_DIR {resources.tmpdir} \\
            1> {log} 2>&1
        """

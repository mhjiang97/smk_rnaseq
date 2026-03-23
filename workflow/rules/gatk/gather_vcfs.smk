rule gather_vcfs:
    conda:
        "../../envs/gatk.yaml"
    input:
        vcfs=gather.split_bed("mutect2/{{sample}}/scatters/{scatteritem}.raw.vcf"),
        fasta=config["fasta"],
    output:
        vcf="mutect2/{sample}/{sample}.raw.vcf",
    params:
        inputs=lambda wildcards, input: " ".join(
            f"--INPUT {vcf}" for vcf in input.vcfs
        ),
    log:
        "logs/{sample}/gather_vcfs.log",
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
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

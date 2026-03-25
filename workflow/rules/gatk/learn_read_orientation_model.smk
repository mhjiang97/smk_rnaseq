rule learn_read_orientation_model:
    input:
        gather.split_bed("mutect2/{{sample}}/scatters/{scatteritem}.f1r2.tar.gz"),
    output:
        table="mutect2/{sample}/{sample}.artifactprior.tar.gz",
    log:
        "logs/{sample}/learn_read_orientation_model.log",
    conda:
        "../../envs/gatk.yaml"
    threads: 1
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}",
    params:
        inputs=lambda wildcards, input: " ".join(f"--input {f1r2}" for f1r2 in input),
        args=get_extra_arguments("learn_read_orientation_model"),
    shell:
        """
        gatk LearnReadOrientationModel \\
            {params.args} \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            {params.inputs} \\
            --output {output.table} \\
            --tmp-dir {resources.tmpdir} \\
            > {log} 2>&1
        """

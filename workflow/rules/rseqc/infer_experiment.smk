checkpoint infer_experiment:
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.bam",
        bed=f"ref/bed/{Path(config['gtf']).stem}.bed",
    output:
        txt="rseqc/{sample}/infer_experiment.txt",
    log:
        "logs/{sample}/infer_experiment.log",
    conda:
        "../../envs/rseqc.yaml"
    params:
        size_sample=200000,
        min_qual_mapping=30,
    shell:
        """
        infer_experiment.py \\
            -i {input.bam} \\
            -r {input.bed} \\
            -s {params.size_sample} \\
            -q {params.min_qual_mapping} \\
            1> {output.txt} 2> {log}
        """

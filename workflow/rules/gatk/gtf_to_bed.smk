rule gtf_to_bed_transcript:
    conda:
        "../../envs/gatk.yaml"
    input:
        gtf=config["gtf"],
        dict=dict_fasta,
    output:
        bed=f"{bed_transcript}.tmp",
    params:
        args=get_extra_arguments("gtf_to_bed_transcript"),
    log:
        "logs/gtf_to_bed_transcript.log",
    shell:
        """
        gatk GtfToBed \\
            {params.args} \\
            --java-options \"-XX:-UsePerfData\" \\
            -gtf-path {input.gtf} \\
            -sequence-dictionary {input.dict} \\
            -sort-by-transcript \\
            -output {output.bed} \\
            1> {log} 2>&1
        """

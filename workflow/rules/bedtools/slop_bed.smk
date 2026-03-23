rule slop_bed:
    conda:
        "../../envs/bedtools.yaml"
    input:
        bed=bed_transcript,
        genome=fai_fasta,
    output:
        bed=temp(f"{bed_transcript_slopped}.tmp"),
    params:
        slop_transcript=config["slop_transcript"],
        arg_pct="-pct" if config["slop_transcript"] < 1 else "",
        args=get_extra_arguments("slop_bed"),
    log:
        "logs/slop_bed.log",
    shell:
        """
        {{ bedtools slop \\
            {params.args} \\
            -i {input.bed} \\
            -g {input.genome} \\
            -b {params.slop_transcript} \\
            {params.arg_pct} \\
            | bedtools sort \\
                -i - \\
                -faidx {input.genome} \\
                > {output.bed}; }} \\
        1> {log} 2>&1
        """

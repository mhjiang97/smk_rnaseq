rule merge_bed:
    conda:
        "../../envs/bedtools.yaml"
    input:
        bed=f"{bed_transcript}.tmp",
    output:
        bed=bed_transcript,
    log:
        "logs/merge_bed.log",
    shell:
        """
        {{ bedtools merge \\
            -i {input.bed} \\
            -c 4 -o distinct \\
            -delim ";" \\
                | bedtools sort \\
                    -i -  \\
                    > {output.bed}; }} \\
        1> {log} 2>&1
        """

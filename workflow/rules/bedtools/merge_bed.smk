rule merge_bed:
    input:
        bed=f"{bed_transcript_slopped}.tmp",
        fai=fai_fasta,
    output:
        bed=bed_transcript_slopped,
    log:
        "logs/merge_bed.log",
    conda:
        "../../envs/bedtools.yaml"
    shell:
        """
        {{ bedtools merge \\
            -i {input.bed} \\
            -c 4 -o distinct \\
            -delim ";" \\
                | bedtools sort \\
                    -i -  \\
                    -faidx {input.fai} \\
                    > {output.bed}; }} \\
        1> {log} 2>&1
        """

rule featurecounts_transposable_elements:
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.bam",
        gtf=config["gtf_te"],
    output:
        counts="featurecounts/{sample}/te.tsv",
        counts_unique_overlap="featurecounts/{sample}/te.unique.overlap.tsv",
        counts_unique="featurecounts/{sample}/te.unique.tsv",
    log:
        "logs/{sample}/featurecounts_transposable_elements.log",
    conda:
        "../../envs/subread.yaml"
    threads: 1
    params:
        arg_count=get_featurecounts_arguments,
    shell:
        """
        {{ featureCounts \\
            {params.arg_count} \\
            -M --fraction -O
            -s 2 \\
            -T {threads} \\
            -t exon \\
            -g gene_id \\
            -a {input.gtf} \\
            -o {output.counts} \\
            {input.bam}

        featureCounts \\
            {params.arg_count} \\
            -O \\
            -s 2 \\
            -T {threads} \\
            -t exon \\
            -g gene_id \\
            -a {input.gtf} \\
            -o {output.counts_unique_overlap} \\
            {input.bam}

        featureCounts \\
            {params.arg_count} \\
            -s 2 \\
            -T {threads} \\
            -t exon \\
            -g gene_id \\
            -a {input.gtf} \\
            -o {output.counts_unique} \\
            {input.bam}; }} \\
        1> {log} 2>&1
        """

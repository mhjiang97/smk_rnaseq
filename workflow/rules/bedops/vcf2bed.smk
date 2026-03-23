rule vcf2bed:
    conda:
        "../../envs/bedops.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.snvs.vcf",
    output:
        bed="{caller}/{sample}/{sample}.snvs.bed",
        tsv="{caller}/{sample}/{sample}.snvs.tsv",
    params:
        _dir="{caller}/{sample}",
    log:
        "logs/{sample}/vcf2bed.{caller}.log",
    shell:
        """
        {{ vcf2bed \\
            --max-mem {resources.mem_mb}M \\
            --sort-tmpdir {params._dir} \\
            < {input.vcf} \\
            | awk -v OFS="\\t" '{{print $1, $2, $3, $4}}' \\
                > {output.bed}

        awk \\
            -v OFS="\\t" \\
            '{{print $1, $3, $3}}' \\
            {output.bed} \\
            > {output.tsv}; }} \\
        1> {log} 2>&1
        """

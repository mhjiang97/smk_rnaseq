rule hard_filter:
    conda:
        "../../envs/bcftools.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.vcf",
    output:
        snvs="{caller}/{sample}/{sample}.snvs.vcf",
        indels="{caller}/{sample}/{sample}.indels.vcf",
        ids_snv=temp("{caller}/{sample}/{sample}.snvs.ids"),
        ids_indel=temp("{caller}/{sample}/{sample}.indels.ids"),
    params:
        formula_snv=get_snv_filters,
        formula_indel=get_indel_filters,
    log:
        "logs/{sample}/hard_filter.{caller}.log",
    shell:
        """
        {{ grep -E "^#|^chr" {input.vcf} \\
            | bcftools sort -Ov - \\
            | bcftools filter -i "{params.formula_snv}" -Ov - \\
            > {output.snvs}

        grep -E "^#|^chr" {input.vcf} \\
            | bcftools sort -Ov - \\
            | bcftools filter -i "{params.formula_indel}" -Ov - \\
            > {output.indels}

        awk '!/^#/ {{print $3}}' {output.snvs} > {output.ids_snv}
        awk '!/^#/ {{print $3}}' {output.indels} > {output.ids_indel}; }} \\
        1> {log} 2>&1
        """

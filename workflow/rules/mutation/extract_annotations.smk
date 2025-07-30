rule extract_annotations:
    conda:
        "../../envs/bcftools.yaml"
    input:
        ids_snv="{caller}/{sample}/{sample}.snvs.ids",
        ids_indel="{caller}/{sample}/{sample}.indels.ids",
        vcf_anno="{caller}/{sample}/{sample}.{annotator}.vcf",
    output:
        snvs_anno="{caller}/{sample}/{sample}.snvs.{annotator}.vcf",
        indels_anno="{caller}/{sample}/{sample}.indels.{annotator}.vcf",
    params:
        min_reads=config["min_reads"],
        min_coverage=config["min_coverage"],
    log:
        "logs/{sample}/extract_annotations.{caller}.{annotator}.log",
    shell:
        """
        {{ bcftools filter -i 'ID=@{input.ids_snv}' {input.vcf_anno} > {output.snvs_anno}
        bcftools filter -i 'ID=@{input.ids_indel}' {input.vcf_anno} > {output.indels_anno}; }} \\
        1> {log} 2>&1
        """

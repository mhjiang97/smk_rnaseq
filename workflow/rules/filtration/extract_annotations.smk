rule extract_annotations:
    input:
        ids_snv="{caller}/{sample}/{sample}.snvs.ids",
        ids_indel="{caller}/{sample}/{sample}.indels.ids",
        vcf_anno="{caller}/{sample}/{sample}.{annotator}.vcf",
    output:
        snvs_anno="{caller}/{sample}/{sample}.snvs.{annotator}.vcf",
        indels_anno="{caller}/{sample}/{sample}.indels.{annotator}.vcf",
    log:
        "logs/{sample}/extract_annotations.{caller}.{annotator}.log",
    conda:
        "../../envs/bcftools.yaml"
    params:
        min_reads=config["min_reads"],
        min_coverage=config["min_coverage"],
    shell:
        """
        {{ bcftools filter -i 'ID=@{input.ids_snv}' {input.vcf_anno} > {output.snvs_anno}
        bcftools filter -i 'ID=@{input.ids_indel}' {input.vcf_anno} > {output.indels_anno}; }} \\
        1> {log} 2>&1
        """


rule extract_annovar_annotations:
    input:
        anno="{caller}/{sample}/{sample}.annovar.tsv",
        tmp="{caller}/{sample}/av.{sample}.avinput",
        vcf_snv="{caller}/{sample}/{sample}.snvs.vcf",
        vcf_indel="{caller}/{sample}/{sample}.indels.vcf",
    output:
        anno_snv="{caller}/{sample}/{sample}.snvs.annovar.tsv",
        anno_indel="{caller}/{sample}/{sample}.indels.annovar.tsv",
    log:
        "logs/{sample}/extract_annovar_annotations.{caller}.log",
    conda:
        "../../envs/python.yaml"
    script:
        "../../scripts/extract_annovar_annotations.py"

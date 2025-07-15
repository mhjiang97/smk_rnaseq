rule hard_filter_separate_vcf:
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
        min_reads=config["min_reads"],
        min_coverage=config["min_coverage"],
    log:
        "logs/{sample}/hard_filter_separate_vcf.{caller}.log",
    shell:
        """
        {{ if [ "{wildcards.caller}" == "haplotypecaller" ]; then
            filters_common="CHROM ~ '^chr' & QUAL >= 30 & INFO/QD >= 2 & FMT/DP >= {params.min_coverage} & FMT/AD[0:1] >= {params.min_reads}"
            filters_snv="TYPE = 'snp' & INFO/SOR <= 3 & INFO/FS <= 30 & INFO/MQ >= 40 & INFO/MQRankSum >= -12.5 & INFO/ReadPosRankSum >= -8"
            filters_indel="TYPE = 'indel' & INFO/SOR <= 4 & INFO/FS <= 200 & INFO/ReadPosRankSum >= -20"
        fi

        formula_snvs="${{filters_common}} & ${{filters_snv}}"
        formula_indels="${{filters_common}} & ${{filters_indel}}"

        bcftools sort -Ov {input.vcf} \\
            | bcftools filter -i "${{formula_snvs}}" -Ov - \\
            > {output.snvs}

        bcftools sort -Ov {input.vcf} \\
            | bcftools filter -i "${{formula_indels}}" -Ov - \\
            > {output.indels}

        awk '!/^#/ {{print $3}}' {output.snvs} > {output.ids_snv}
        awk '!/^#/ {{print $3}}' {output.indels} > {output.ids_indel}; }} \\
        1> {log} 2>&1
        """


rule hard_filter_separate_annotations:
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
        "logs/{sample}/hard_filter_separate_annotations.{caller}.{annotator}.log",
    shell:
        """
        {{ bcftools filter -i 'ID=@{input.ids_snv}' {input.vcf_anno} > {output.snvs_anno}
        bcftools filter -i 'ID=@{input.ids_indel}' {input.vcf_anno} > {output.indels_anno}; }} \\
        1> {log} 2>&1
        """

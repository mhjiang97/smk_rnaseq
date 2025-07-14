rule filter_separate_vcf:
    conda:
        "../../envs/bcftools.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.vcf",
        vcf_snpeff="{caller}/{sample}/{sample}.snpeff.vcf",
        vcf_vep="{caller}/{sample}/{sample}.vep.vcf",
    output:
        snvs="{caller}/{sample}/{sample}.snvs.vcf",
        indels="{caller}/{sample}/{sample}.indels.vcf",
        ids_snv=temp("{caller}/{sample}/{sample}.snvs.ids"),
        ids_indel=temp("{caller}/{sample}/{sample}.indels.ids"),
        snvs_snpeff="{caller}/{sample}/{sample}.snvs.snpeff.vcf",
        snvs_vep="{caller}/{sample}/{sample}.snvs.vep.vcf",
        indels_snpeff="{caller}/{sample}/{sample}.indels.snpeff.vcf",
        indels_vep="{caller}/{sample}/{sample}.indels.vep.vcf",
    params:
        min_reads=config["min_reads"],
        min_coverage=config["min_coverage"],
    log:
        "logs/{sample}/filter_separate_vcf.{caller}.log",
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
            | bcftools filter -i "${{formula_snvs}}" -Ov - > {output.snvs}

        bcftools sort -Ov {input.vcf} \\
            | bcftools filter -i "${{formula_indels}}" -Ov - > {output.indels}

        awk '!/^#/ {{print $3}}' {output.snvs} > {output.ids_snv}
        awk '!/^#/ {{print $3}}' {output.indels} > {output.ids_indel}

        bcftools filter -i 'ID=@{output.ids_snv}' {input.vcf_snpeff} > {output.snvs_snpeff}
        bcftools filter -i 'ID=@{output.ids_snv}' {input.vcf_vep} > {output.snvs_vep}
        bcftools filter -i 'ID=@{output.ids_indel}' {input.vcf_snpeff} > {output.indels_snpeff}
        bcftools filter -i 'ID=@{output.ids_indel}' {input.vcf_vep} > {output.indels_vep}; }} \\
        1> {log} 2>&1
        """

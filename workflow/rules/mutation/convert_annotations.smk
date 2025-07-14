rule convert_vep:
    conda:
        "../../envs/vcf2maf.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.{mutation}.vep.vcf",
        fasta=config["fasta"],
    output:
        maf="{caller}/{sample}/{sample}.{mutation}.vep.maf",
    params:
        version=config["version_vep"],
        genome=config["genome"],
        cache=config["cache_vep"],
        species=config["species"],
    log:
        "logs/{sample}/convert_vep.{caller}.{mutation}.log",
    shell:
        """
        vcf2maf.pl \\
            --input-vcf {input.vcf} --output-maf {output.maf} \\
            --ncbi-build {params.genome} --cache-version {params.version} \\
            --ref-fasta {input.fasta} --vcf-tumor-id {wildcards.sample} --tumor-id {wildcards.sample} --vep-data {params.cache} \\
            --species {params.species} --inhibit-vep \\
            1> {log} 2>&1
        """


rule convert_snpeff:
    conda:
        "../../envs/snpeff.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.{mutation}.snpeff.vcf",
    output:
        tsv="{caller}/{sample}/{sample}.{mutation}.snpeff.tsv",
    log:
        "logs/{sample}/convert_snpeff.{caller}.{mutation}.log",
    shell:
        """
        {{ fields_common="CHROM POS ID REF ALT QUAL \\
ANN[*].ALLELE ANN[*].EFFECT ANN[*].IMPACT ANN[*].GENE ANN[*].GENEID \\
ANN[*].FEATURE ANN[*].FEATUREID ANN[*].BIOTYPE ANN[*].RANK ANN[*].HGVS_C \\
ANN[*].HGVS_P ANN[*].CDNA_POS ANN[*].CDNA_LEN ANN[*].CDS_POS \\
ANN[*].CDS_LEN ANN[*].AA_POS ANN[*].AA_LEN ANN[*].DISTANCE ANN[*].ERRORS \\
LOF[*].GENE LOF[*].GENEID LOF[*].NUMTR LOF[*].PERC \\
NMD[*].GENE NMD[*].GENEID NMD[*].NUMTR NMD[*].PERC"

        if [ "{wildcards.caller}" == "haplotypecaller" ]; then
            fields_fmt="GEN[*].AD GEN[*].DP GEN[*].GQ GEN[*].GT GEN[*].PL"
        fi

        SnpSift extractFields -s "," -e "." {input.vcf} ${{fields_common}} ${{fields_fmt}} \\
            | sed '1s/GEN\\[\\*\\]\\.//g ; 1s/ANN\\[\\*\\]\\.//g ; 1s/\\[\\*\\]//g' \\
            > {output.tsv}; }} \\
        > {log} 2>&1
        """

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
        arg_normal=get_convert_vep_arguments,
    log:
        "logs/{sample}/convert_vep.{caller}.{mutation}.log",
    shell:
        """
        vcf2maf.pl \\
            --input-vcf {input.vcf} \\
            --output-maf {output.maf} \\
            --ref-fasta {input.fasta} \\
            --vcf-tumor-id {wildcards.sample} \\
            --tumor-id {wildcards.sample} \\
            --ncbi-build {params.genome} \\
            --cache-version {params.version} \\
            --vep-data {params.cache} \\
            --species {params.species} \\
            --inhibit-vep \\
            {params.arg_normal} \\
            1> {log} 2>&1
        """


rule convert_snpeff:
    conda:
        "../../envs/snpeff.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.{mutation}.snpeff.vcf",
    output:
        tsv="{caller}/{sample}/{sample}.{mutation}.snpeff.tsv",
    params:
        fields_common=FIELDS_COMMON,
        fields_fmt=get_convert_snpeff_arguments,
    log:
        "logs/{sample}/convert_snpeff.{caller}.{mutation}.log",
    shell:
        """
        {{ SnpSift extractFields \\
            -s ";" -e "." \\
            {input.vcf} {params.fields_common} {params.fields_fmt} \\
            | sed '1s/GEN\\[\\*\\]\\.//g ; 1s/ANN\\[\\*\\]\\.//g ; 1s/\\[\\*\\]//g' \\
            > {output.tsv}; }} \\
        > {log} 2>&1
        """

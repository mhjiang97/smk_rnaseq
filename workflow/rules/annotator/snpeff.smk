rule snpeff:
    input:
        vcf="{caller}/{sample}/{sample}.vcf",
        fasta=config["fasta"],
        dir_cache=path_cache_snpeff,
    output:
        vcf=protected("{caller}/{sample}/{sample}.snpeff.vcf"),
        html="{caller}/{sample}/{sample}.snpeff.html",
    log:
        "logs/{sample}/{caller}.snpeff.log",
    conda:
        "../../envs/snpeff.yaml"
    params:
        cache=config["cache_snpeff"],
        version=config["version_snpeff"],
        genome=config["genome"],
    shell:
        """
        snpEff -Xmx{resources.mem_mb}M \\
            -nodownload -v -lof -canon \\
            -dataDir {params.cache} -s {output.html} \\
            {params.genome}.{params.version} {input.vcf} \\
            1> {output.vcf} \\
            2> {log}
        """

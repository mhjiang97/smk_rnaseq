rule snpeff:
    conda:
        "../../envs/snpeff.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.vcf",
        fasta=config["fasta"],
    output:
        vcf=protected("{caller}/{sample}/{sample}.snpeff.vcf"),
        html="{caller}/{sample}/{sample}.snpeff.html",
    params:
        cache=config["cache_snpeff"],
        version=config["version_snpeff"],
        genome=config["genome"],
    resources:
        mem_mb=1,
    log:
        "logs/{sample}/{caller}.snpeff.log",
    shell:
        """
        snpEff -Xmx{resources.mem_mb}M \\
            -nodownload -v -lof \\
            -dataDir {params.cache} -s {output.html} \\
            {params.genome}.{params.version} {input.vcf} \\
            1> {output.vcf} 2> {log}
        """

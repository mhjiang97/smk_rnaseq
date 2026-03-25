rule vep:
    input:
        vcf="{caller}/{sample}/{sample}.vcf",
        fasta=config["fasta"],
        dir_cache=path_cache_vep,
    output:
        vcf=protected("{caller}/{sample}/{sample}.vep.vcf"),
        html="{caller}/{sample}/{sample}.vep.html",
    log:
        "logs/{sample}/{caller}.vep.log",
    container:
        "docker://ensemblorg/ensembl-vep:release_115.2"
    threads: 1
    params:
        cache=config["cache_vep"],
        version=config["version_vep"],
        genome=config["genome"],
        species=config["species"],
    shell:
        """
        vep \\
            -i {input.vcf} -o {output.vcf} --stats_file {output.html} \\
            --species {params.species} --assembly {params.genome} \\
            --cache_version {params.version} --fasta {input.fasta} \\
            --dir_cache {params.cache} --fork {threads} \\
            --force_overwrite --cache --vcf --everything --filter_common \\
            --per_gene --total_length --offline --format vcf \\
            1> {log} 2>&1
        """

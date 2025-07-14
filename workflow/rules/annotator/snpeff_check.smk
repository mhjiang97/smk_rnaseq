rule snpeff_check:
    conda:
        "../../envs/snpeff.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.vcf",
        fasta=config["fasta"],
    output:
        vcf=update("{caller}/{sample}/{sample}.snpeff.vcf"),
    params:
        cache=config["cache_snpeff"],
        version=config["version_snpeff"],
        genome=config["genome"],
    resources:
        mem_mb=1,
    log:
        "logs/{sample}/{caller}.snpeff_update.log",
    shell:
        """
        {{ l_input=$(wc -l {input.vcf} | awk '{{print $1}}')
        l_output=0
        [ -f {output.vcf} ] && l_output=$(wc -l {output.vcf} | awk '{{print $1}}')

        if [ ${{l_input}} -eq $((l_output - 5)) ]; then
            echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] [WARN] Skipping SneEff for {wildcards.sample} as it has already been fully processed."
            exit 0
        fi

        vcf={output.vcf}
        html=${{vcf%.vcf}}.html
        snpEff -Xmx{resources.mem_mb}M \\
            -nodownload -v -lof \\
            -dataDir {params.cache} -s ${{html}} \\
            {params.genome}.{params.version} {input.vcf} > {output.vcf}; }} \\
        1> {log} 2>&1
        """

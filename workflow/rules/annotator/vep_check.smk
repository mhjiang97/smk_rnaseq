rule vep_check:
    conda:
        "../../envs/vep.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.vcf",
        fasta=config["fasta"],
    output:
        vcf=update("{caller}/{sample}/{sample}.vep.vcf"),
    params:
        cache=config["cache_vep"],
        version=config["version_vep"],
        genome=config["genome"],
        species=config["species"],
    threads: 1
    log:
        "logs/{sample}/{caller}.vep_update.log",
    shell:
        """
        {{ l_input=$(wc -l {input.vcf} | awk '{{print $1}}')
        l_output=0
        [ -f {output.vcf} ] && l_output=$(wc -l {output.vcf} | awk '{{print $1}}')
        l_skipped=0
        [ -f {output.vcf}_warnings.txt ] && l_skipped=$(grep -E "line [0-9]+ skipped" {output.vcf}_warnings.txt | wc -l)

        if [ ${{l_input}} -eq $((l_output + l_skipped - 3)) ]; then
            echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] [WARN] Skipping VEP for {wildcards.sample} as it has already been fully processed."
            exit 0
        fi

        vcf={output.vcf}
        html=${{vcf%.vcf}}.html
        vep \\
            -i {input.vcf} -o {output.vcf} --stats_file ${{html}} \\
            --species {params.species} --assembly {params.genome} \\
            --cache_version {params.version} --fasta {input.fasta} \\
            --dir_cache {params.cache} --fork {threads} \\
            --force_overwrite --cache --vcf --everything --filter_common \\
            --per_gene --total_length --offline --format vcf; }} \\
        1> {log} 2>&1
        """

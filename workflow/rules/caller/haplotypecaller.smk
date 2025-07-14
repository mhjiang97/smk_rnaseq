rule haplotypecaller:
    conda:
        "../../envs/gatk.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.recal.bam",
        fasta=config["fasta"],
        dbsnp=config["dbsnp"],
    output:
        vcf=temp("haplotypecaller/{sample}/tmp.vcf"),
        vcf_reided=protected("haplotypecaller/{sample}/{sample}.vcf"),
    log:
        "logs/{sample}/haplotypecaller.log",
    threads: 1
    resources:
        mem_mb=1,
    shell:
        """
        {{ gatk HaplotypeCaller \\
            --java-options \"-Xmx{resources.mem_mb}M -XX:-UsePerfData\" \\
            --native-pair-hmm-threads {threads} \\
            --standard-min-confidence-threshold-for-calling 20 \\
            -R {input.fasta} -I {input.bam} -O {output.vcf} \\
            --dbsnp {input.dbsnp} --sample-ploidy 2 \\
            --dont-use-soft-clipped-bases true \\
            --create-output-variant-index false

        awk '
            BEGIN {{OFS="\\t"; FS="\\t"; count=0}}
            /^#/ {{print; next}}
            {{
                count++
                if ($3 ~ /^rs/) {{
                    print $0
                }} else {{
                    $3="HC_"count
                    print $0
                }}
            }}' {output.vcf} > {output.vcf_reided}; }} \\
        > {log} 2>&1
        """

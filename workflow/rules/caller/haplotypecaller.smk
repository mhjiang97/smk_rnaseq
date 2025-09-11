rule haplotypecaller:
    conda:
        "../../envs/gatk4.1.yaml"
    input:
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.md.splitn.recal.bam",
        bed=get_interval_bed(),
        fasta=config["fasta"],
        dbsnp=config["dbsnp"],
    output:
        vcf=temp("haplotypecaller/{sample}/tmp.vcf"),
        index=temp("haplotypecaller/{sample}/tmp.vcf.idx"),
    params:
        args=get_extra_arguments("haplotypecaller"),
    log:
        "logs/{sample}/haplotypecaller.log",
    threads: 1
    resources:
        mem_mb=1,
        tmpdir=lambda wildcards: f"haplotypecaller/{wildcards.sample}",
    shell:
        """
        gatk HaplotypeCaller \\
            {params.args} \\
            --java-options \"-Xmx{resources.mem_mb}M -XX:-UsePerfData\" \\
            --native-pair-hmm-threads {threads} \\
            --standard-min-confidence-threshold-for-calling 20 \\
            -R {input.fasta} \\
            -I {input.bam} \\
            -O {output.vcf} \\
            -L {input.bed} \\
            --dbsnp {input.dbsnp} \\
            --sample-ploidy 2 \\
            --dont-use-soft-clipped-bases true \\
            --tmp-dir {resources.tmpdir} \\
            > {log} 2>&1
        """


rule format_haplotypecaller:
    conda:
        "../../envs/bcftools.yaml"
    input:
        vcf="haplotypecaller/{sample}/tmp.vcf",
    output:
        vcf=protected("haplotypecaller/{sample}/{sample}.vcf"),
    log:
        "logs/{sample}/format_haplotypecaller.log",
    shell:
        """
        bcftools annotate \\
            --set-id +'%CHROM\\_%POS\\_%REF\\_%FIRST_ALT' \\
            {input.vcf} \\
            1> {output.vcf} 2> {log}
        """

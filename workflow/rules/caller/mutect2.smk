rule split_bed:
    input:
        bed=get_interval_bed(),
    output:
        scatter.split_bed("ref/beds/{scatteritem}.bed"),
    run:
        with open(input.bed) as f:
            lines = [line for line in f if not line.startswith("#")]

        chunk_size = (len(lines) + len(output) - 1) // len(output)

        for i, out in enumerate(output):
            with open(out, "w") as f:
                f.writelines(lines[i * chunk_size : (i + 1) * chunk_size])


rule mutect2:
    conda:
        "../../envs/gatk.yaml"
    input:
        unpack(get_mutect2_inputs),
        bed="ref/beds/{scatteritem}.bed",
    output:
        vcf=temp("mutect2/{sample}/scatters/{scatteritem}.raw.vcf"),
        f1r2=temp("mutect2/{sample}/scatters/{scatteritem}.f1r2.tar.gz"),
        stats=temp("mutect2/{sample}/scatters/{scatteritem}.raw.vcf.stats"),
    params:
        min_coverage=config["min_coverage"],
        min_qual_base=config["min_qual_base"],
        arg_dna=get_mutect2_arguments,
        args=get_extra_arguments("mutect2"),
    log:
        "logs/{sample}/mutect2.{scatteritem}.log",
    threads: 1
    resources:
        tmpdir=lambda wildcards: f"mutect2/{wildcards.sample}/scatters",
    shell:
        """
        gatk Mutect2 \\
            {params.args} \\
            --java-options "-Xmx{resources.mem_mb}M -XX:-UsePerfData" \\
            --native-pair-hmm-threads {threads} \\
            -R {input.fasta} \\
            -I {input.bam} \\
            {params.arg_dna} \\
            -O {output.vcf} \\
            -L {input.bed} \\
            --f1r2-tar-gz {output.f1r2} \\
            --callable-depth {params.min_coverage} \\
            --min-base-quality-score {params.min_qual_base} \\
            --f1r2-min-bq {params.min_qual_base} \\
            --germline-resource {input.resource_germline} \\
            --panel-of-normals {input.pon} \\
            --dont-use-soft-clipped-bases true \\
            --tmp-dir {resources.tmpdir} \\
            1> {log} 2>&1
        """

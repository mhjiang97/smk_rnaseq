rule star_index:
    input:
        gtf=config["gtf"],
        fasta=config["fasta"],
    output:
        index=protected(directory(config["index_star"])),
    log:
        "logs/star_index.log",
    conda:
        "../../envs/star.yaml"
    threads: 1
    params:
        args=get_extra_arguments("star_index"),
    shell:
        """
        STAR \\
            {params.args} \\
            --runMode genomeGenerate \\
            --runThreadN {threads} \\
            --genomeDir {output.index} \\
            --genomeFastaFiles {input.fasta} \\
            --sjdbGTFfile {input.gtf} \\
            1> {log} 2>&1
        """


rule star:
    input:
        unpack(get_fastq_files),
        gtf=config["gtf"],
        index=ancient(config["index_star"]),
    output:
        bam=temp("star/{sample}/Aligned.out.bam"),
        sj=protected("star/{sample}/SJ.out.tab"),
    log:
        "logs/{sample}/star.log",
    conda:
        "../../envs/star.yaml"
    threads: 1
    resources:
        mem_mb=get_star_mem_mb,
        tmpdir=lambda wildcards: f"star/{wildcards.sample}",
    params:
        layout=get_library_layout,
        dir_tmp="star/{sample}/tmp",
        args=get_extra_arguments("star"),
    script:
        "../../scripts/star.sh"


rule star_sort:
    input:
        bam="star/{sample}/Aligned.out.bam",
    output:
        bam=protected("star/{sample}/{sample}.sorted.bam"),
        csi=protected("star/{sample}/{sample}.sorted.bam.csi"),
    log:
        "logs/{sample}/star_sort.log",
    threads: 1
    resources:
        mem_mb=get_star_sort_mem_mb,
        tmpdir=lambda wildcards: f"star/{wildcards.sample}",
    params:
        prefix="star/{sample}/tmp",
    shell:
        """
        samtools sort \\
            -@ {threads} \\
            -m $(({resources.mem_mb} / ({threads} + 2)))M \\
            -T {params.prefix} \\
            -o {output.bam} \\
            --write-index \\
            {input.bam} \\
            1> {log} 2>&1
        """

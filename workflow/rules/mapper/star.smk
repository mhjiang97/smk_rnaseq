rule star_index:
    conda:
        "../../envs/star.yaml"
    input:
        gtf=config["gtf"],
        fasta=config["fasta"],
    output:
        dir=protected(directory(config["index_star"])),
        index_sa=f"{config['index_star']}/SA",
    threads: 1
    log:
        "logs/star_index.log",
    shell:
        """
        STAR --runMode genomeGenerate \\
            --runThreadN {threads} \\
            --genomeDir {output.dir} \\
            --genomeFastaFiles {input.fasta} \\
            --sjdbGTFfile {input.gtf} \\
            1> {log} 2>&1
        """


rule star:
    conda:
        "../../envs/star.yaml"
    input:
        unpack(get_fastq_files),
        gtf=config["gtf"],
        index_sa=ancient(f"{config['index_star']}/SA"),
    output:
        bam=protected("star/{sample}/Aligned.sortedByCoord.out.bam"),
        bai=protected("star/{sample}/Aligned.sortedByCoord.out.bam.bai"),
        sj=protected("star/{sample}/SJ.out.tab"),
        bam_renamed="star/{sample}/{sample}.sorted.bam",
        bai_renamed="star/{sample}/{sample}.sorted.bam.bai",
    params:
        index=config["index_star"],
    threads: 1
    resources:
        mem_mb=1,
    log:
        "logs/{sample}/star.log",
    script:
        "../../scripts/star.sh"

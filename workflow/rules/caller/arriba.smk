rule arriba:
    input:
        unpack(get_fastq_files),
        fasta=config["fasta"],
        gtf=config["gtf"],
        index=ancient(config["index_star"]),
    output:
        fusion="arriba/{sample}/fusions.tsv",
        fusion_discarded="arriba/{sample}/fusions.discarded.tsv",
        bam="arriba/{sample}/{sample}.unsorted.bam",
        log="arriba/{sample}/Log.out",
        log_final="arriba/{sample}/Log.final.out",
        log_progress="arriba/{sample}/Log.progress.out",
        log_std="arriba/{sample}/Log.std.out",
        sj="arriba/{sample}/SJ.out.tab",
    log:
        "logs/{sample}/arriba.log",
    shadow:
        "minimal"
    container:
        "docker://uhrigs/arriba:2.5.1"
    threads: 1
    resources:
        mem_mb=lambda wildcards, input, attempt: get_star_mem_mb(
            wildcards, input, attempt
        ),
    params:
        layout=get_library_layout,
        genome=config["genome"],
        dir_tmp="arriba/{sample}/tmp",
    script:
        "../../scripts/arriba.sh"

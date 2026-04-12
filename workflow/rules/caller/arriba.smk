rule arriba:
    input:
        unpack(get_fastq_files),
        fasta=config["fasta"],
        gtf=config["gtf"],
        index_sa=ancient(f"{config['index_star']}/SA"),
    output:
        fusion="arriba/{sample}/fusions.tsv",
        fusion_discarded="arriba/{sample}/fusions.discarded.tsv",
        bam="arriba/{sample}/{sample}.unsorted.bam",
    log:
        "logs/{sample}/arriba.log",
    container:
        "docker://uhrigs/arriba:2.5.1"
    threads: 1
    resources:
        mem_mb=lambda wildcards, attempt: get_star_mem_mb(wildcards, attempt),
    params:
        layout=get_library_layout,
        genome=config["genome"],
        index=config["index_star"],
        dir_tmp="arriba/{sample}/tmp",
    script:
        "../../scripts/arriba.sh"

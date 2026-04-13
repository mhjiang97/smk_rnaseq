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
    log:
        "logs/{sample}/arriba.log",
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
        _dir="arriba/{sample}",
    script:
        "../../scripts/arriba.sh"

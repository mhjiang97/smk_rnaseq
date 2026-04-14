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
        blacklist=get_arriba_database("blacklist"),
        known_fusions=get_arriba_database("known_fusions"),
        protein_domains=get_arriba_database("protein_domains"),
        version=get_arriba_version(),
        layout=get_library_layout,
        dir_tmp="arriba/{sample}/tmp",
    script:
        "../../scripts/arriba.sh"


rule draw_fusions:
    input:
        fusion="arriba/{sample}/fusions.tsv",
        bam=f"{MAPPER}/{{sample}}/{{sample}}.sorted.bam",
        gtf=config["gtf"],
    output:
        pdf="arriba/{sample}/fusions.pdf",
    log:
        "logs/{sample}/arriba_draw_fusions.log",
    container:
        "docker://uhrigs/arriba:2.5.1"
    threads: 1
    params:
        cytobands=get_arriba_database("cytobands"),
        protein_domains=get_arriba_database("protein_domains"),
        version=get_arriba_version(),
    shell:
        """
        /arriba_v{params.version}/draw_fusions.R \\
            --fusions={input.fusion} \\
            --alignments={input.bam} \\
            --annotation={input.gtf} \\
            --cytobands={params.cytobands} \\
            --proteinDomains={params.protein_domains} \\
            --output={output.pdf} \\
            1> {log} 2>&1
        """

rule gtf2bed:
    conda:
        "../../envs/bedops.yaml"
    input:
        gtf=config["gtf"],
    output:
        bed=f"ref/bed/{Path(config['gtf']).stem}.bed",
    params:
        _dir="ref/bed",
    log:
        "logs/gtf2bed.log",
    shell:
        """
        gtf2bed \\
            --max-mem {resources.mem_mb}M \\
            --sort-tmpdir {params._dir} \\
            < {input.gtf} \\
            1> {output.bed} 2> {log}
        """

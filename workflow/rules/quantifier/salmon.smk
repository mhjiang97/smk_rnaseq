rule salmon_index:
    input:
        fasta_transcriptome=config["fasta_transcriptome"],
        fasta=config["fasta"],
    output:
        _dir=directory(config["index_salmon"]),
        index_pos=f"{config['index_salmon']}/pos.bin",
    log:
        "logs/salmon_index.log",
    shadow:
        "minimal"
    conda:
        "../../envs/salmon.yaml"
    threads: 1
    shell:
        """
        {{ grep "^>" {input.fasta} | cut -d " " -f 1 > decoys.txt
        sed -i.bak -e 's/>//g' decoys.txt

        cat {input.fasta_transcriptome} {input.fasta} > gentrome.fa

        salmon index \\
            -t gentrome.fa \\
            -d decoys.txt \\
            -p {threads} \\
            -i {output._dir} \\
            --gencode \\
            --keepDuplicates; }} \\
        1> {log} 2>&1
        """


checkpoint salmon:
    input:
        unpack(get_fastq_files),
        index_pos=ancient(f"{config['index_salmon']}/pos.bin"),
    output:
        log="salmon/{sample}/logs/salmon_quant.log",
        _dir=directory("salmon/{sample}"),
        quant="salmon/{sample}/quant.sf",
    log:
        "logs/{sample}/salmon.log",
    conda:
        "../../envs/salmon.yaml"
    threads: 1
    params:
        index=config["index_salmon"],
        layout=get_library_layout,
    script:
        "../../scripts/salmon.sh"

rule salmon_index:
    conda:
        "../../envs/salmon.yaml"
    input:
        fasta_transcriptome=config["fasta_transcriptome"],
        fasta=config["fasta"],
    output:
        dir=directory(config["index_salmon"]),
        index_pos=f"{config['index_salmon']}/pos.bin",
    threads: 1
    shadow:
        "minimal"
    log:
        "logs/salmon_index.log",
    shell:
        """
        {{ grep "^>" {input.fasta} | cut -d " " -f 1 > decoys.txt
        sed -i.bak -e 's/>//g' decoys.txt

        cat {input.fasta_transcriptome} {input.fasta} > gentrome.fa

        salmon index -t gentrome.fa -d decoys.txt -p {threads} -i {output.dir} --gencode --keepDuplicates; }} \\
        1> {log} 2>&1
        """


rule salmon:
    conda:
        "../../envs/salmon.yaml"
    priority: 10
    input:
        unpack(get_fastq_files),
        index_pos=ancient(f"{config['index_salmon']}/pos.bin"),
    output:
        dir=directory("salmon/{sample}"),
        quant="salmon/{sample}/quant.sf",
    params:
        index=config["index_salmon"],
        layout=get_library_layout,
    threads: 1
    log:
        "logs/{sample}/salmon.log",
    script:
        "../../scripts/salmon.sh"

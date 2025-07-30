rule create_sequence_dictionary:
    conda:
        "../../envs/gatk.yaml"
    input:
        fasta=config["fasta"],
    output:
        dict=dict_fasta,
    params:
        args=get_extra_arguments("create_sequence_dictionary"),
    log:
        "logs/create_fasta_dict.log",
    shell:
        """
        gatk CreateSequenceDictionary \\
            {params.args} \\
            --java-options \"-XX:-UsePerfData\" \\
            --REFERENCE {input.fasta} \\
            1> {log} 2>&1
        """

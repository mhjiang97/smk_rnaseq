rule create_sequence_dictionary:
    input:
        fasta=config["fasta"],
    output:
        dict=dict_fasta,
    log:
        "logs/create_fasta_dict.log",
    conda:
        "../../envs/gatk.yaml"
    params:
        args=get_extra_arguments("create_sequence_dictionary"),
    shell:
        """
        gatk CreateSequenceDictionary \\
            {params.args} \\
            --java-options \"-XX:-UsePerfData\" \\
            --REFERENCE {input.fasta} \\
            1> {log} 2>&1
        """

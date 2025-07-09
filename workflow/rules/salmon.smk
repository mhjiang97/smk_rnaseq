def get_salmon_inputs(wildcards):
    sample = wildcards.sample
    dir_base = "fastp/{sample}" if TO_CLEAN_FQ else DIR_DATA

    if sample in SAMPLES_PE:
        return {
            "fq_1": f"{dir_base}/{{sample}}{SUFFIX_READ_1}",
            "fq_2": f"{dir_base}/{{sample}}{SUFFIX_READ_2}",
        }
    elif sample in SAMPLES_SE:
        return {"fq": f"{dir_base}/{{sample}}{SUFFIX_READ_SE}"}
    else:
        raise ValueError(f"Sample {sample} not found in SAMPLES_PE or SAMPLES_SE.")


rule salmon:
    priority: 10
    input:
        unpack(get_salmon_inputs),
    output:
        dir=directory("salmon/{sample}"),
        quant="salmon/{sample}/quant.sf",
    params:
        index_salmon=config["index_salmon"],
    threads: 1
    log:
        "logs/{sample}/salmon.log",
    script:
        "../scripts/salmon.sh"

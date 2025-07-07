def get_fastqc_inputs(wildcards):
    sample = wildcards.sample

    if sample in SAMPLES_PE:
        return {
            "fq_1": "fastp/{sample}/{sample}%s" % SUFFIX_READ_1,
            "fq_2": "fastp/{sample}/{sample}%s" % SUFFIX_READ_2,
        }
    elif sample in SAMPLES_SE:
        return {"fq": "fastp/{sample}/{sample}%s" % SUFFIX_READ_SE}
    else:
        raise ValueError(f"Sample {sample} not found in SAMPLES_PE or SAMPLES_SE.")


rule fastqc:
    input:
        unpack(get_fastqc_inputs),
    output:
        dir=directory("fastqc/fastp/{sample}"),
    threads: 1
    log:
        "logs/{sample}/fastqc.log",
    script:
        "../scripts/fastqc.sh"


rule multiqc:
    input:
        fastqcs=expand("fastqc/fastp/{sample}", sample=SAMPLES),
    output:
        dir=directory("multiqc/fastp"),
        html="multiqc/fastp/multiqc_report.html",
    log:
        "logs/multiqc.log",
    shell:
        """
        multiqc -o {output.dir} --force {input.fastqcs} 1> {log} 2>&1
        """

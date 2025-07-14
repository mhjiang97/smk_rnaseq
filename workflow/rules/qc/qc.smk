rule fastqc:
    input:
        unpack(get_fastqc_inputs),
    output:
        dir=directory("fastqc/fastp/{sample}"),
    threads: 1
    log:
        "logs/{sample}/fastqc.log",
    script:
        "../../scripts/fastqc.sh"


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

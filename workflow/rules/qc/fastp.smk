rule fastp_paired_end:
    input:
        fq_1=f"{DIR_DATA}/{{sample}}{SUFFIX_READ_1}",
        fq_2=f"{DIR_DATA}/{{sample}}{SUFFIX_READ_2}",
    output:
        fq_1=f"fastp/{{sample}}/{{sample}}{SUFFIX_READ_1}",
        fq_2=f"fastp/{{sample}}/{{sample}}{SUFFIX_READ_2}",
        fq_1_unpaired="fastp/{sample}/{sample}_R1.unpaired.fq.gz",
        fq_2_unpaired="fastp/{sample}/{sample}_R2.unpaired.fq.gz",
        fq_failed="fastp/{sample}/{sample}.failed.fq.gz",
        json="fastp/{sample}/{sample}.json",
        html="fastp/{sample}/{sample}.html",
    log:
        "logs/{sample}/fastp_paired_end.log",
    threads: 1
    params:
        layout=get_library_layout,
    script:
        "../../scripts/fastp.sh"


rule fastp_single_end:
    input:
        fq=f"{DIR_DATA}/{{sample}}{SUFFIX_READ_SE}",
    output:
        fq=f"fastp/{{sample}}/{{sample}}{SUFFIX_READ_SE}",
        fq_failed="fastp/{sample}/{sample}.failed.fq.gz",
        json="fastp/{sample}/{sample}.json",
        html="fastp/{sample}/{sample}.html",
    log:
        "logs/{sample}/fastp_single_end.log",
    threads: 1
    params:
        layout=get_library_layout,
    script:
        "../../scripts/fastp.sh"

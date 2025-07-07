rule fastp_paired_end:
    input:
        fq_1="{sample}/{sample}_1.fastq.gz",
        fq_2="{sample}/{sample}_2.fastq.gz",
    output:
        fq_1="fastp/{sample}/{sample}%s" % SUFFIX_READ_1,
        fq_2="fastp/{sample}/{sample}%s" % SUFFIX_READ_2,
        fq_1_unpaired="fastp/{sample}/{sample}_R1.unpaired.fq.gz",
        fq_2_unpaired="fastp/{sample}/{sample}_R2.unpaired.fq.gz",
        fq_failed="fastp/{sample}/{sample}.failed.fq.gz",
        json="fastp/{sample}/{sample}.json",
        html="fastp/{sample}/{sample}.html",
    threads: 1
    log:
        "logs/{sample}/fastp_paired_end.log",
    script:
        "../scripts/fastp.sh"


rule fastp_single_end:
    input:
        fq="{sample}/{sample}.fastq.gz",
    output:
        fq="fastp/{sample}/{sample}%s" % SUFFIX_READ_SE,
        fq_failed="fastp/{sample}/{sample}.failed.fq.gz",
        json="fastp/{sample}/{sample}.json",
        html="fastp/{sample}/{sample}.html",
    threads: 1
    log:
        "logs/{sample}/fastp_single_end.log",
    script:
        "../scripts/fastp.sh"

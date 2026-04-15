#!/usr/bin/env bash

# shellcheck disable=SC2154

set -x


{ sample=${snakemake_wildcards[sample]}
gtf=${snakemake_input[gtf]}
index=${snakemake_input[index]}
bam_tmp=${snakemake_output[bam_tmp]}
bam=${snakemake_output[bam]}
csi=${snakemake_output[csi]}
threads=${snakemake[threads]}
layout=${snakemake_params[layout]}
args=${snakemake_params[args]}

out_dir=$(dirname "${bam}")

if [ "${layout}" == "paired-end" ]; then
    files_in=("${snakemake_input[fq_1]}" "${snakemake_input[fq_2]}")
elif [ "${layout}" == "single-end" ]; then
    files_in=("${snakemake_input[fq]}")
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] Unexpected layout: ${layout}"
    exit 1
fi

[[ "${files_in[0]}" == *".gz" ]] && cmd_read="zcat" || cmd_read="cat"

STAR \
    "${args}" \
    --runThreadN "${threads}" \
    --genomeDir "${index}" \
    --twopassMode Basic \
    --readFilesIn "${files_in[@]}" \
    --readFilesCommand "${cmd_read}" \
    --outFileNamePrefix "${out_dir}"/ \
    --outSAMattrRGline ID:"${sample}" SM:"${sample}" LB:RNA PL:ILLUMINA \
    --sjdbGTFfile "${gtf}" \
    --outSAMattrIHstart 0 \
    --outSAMtype BAM Unsorted \
    --outSAMattributes NH XS HI AS nM NM MD jM jI MC ch \
    --outSAMstrandField intronMotif

samtools sort -@ "${threads}" -o "${bam}" --write-index "${bam_tmp}"; } \
1> "${snakemake_log[0]}" 2>&1

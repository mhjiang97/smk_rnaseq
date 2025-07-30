#!/usr/bin/env bash

# shellcheck disable=SC2154

set -x


{ sample=${snakemake_wildcards[sample]}
gtf=${snakemake_input[gtf]}
bam=${snakemake_output[bam]}
bai=${snakemake_output[bai]}
bam_renamed=${snakemake_output[bam_renamed]}
bai_renamed=${snakemake_output[bai_renamed]}
threads=${snakemake[threads]}
index=${snakemake_params[index]}
layout=${snakemake_params[layout]}
args=${snakemake_params[args]}
mem_mb=${snakemake_resources[mem_mb]}

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
    --limitBAMsortRAM $((mem_mb * 1024 * 1024)) \
    --outBAMsortingThreadN "${threads}" \
    --outSAMattrIHstart 0 \
    --outSAMtype BAM SortedByCoordinate \
    --outSAMattributes NH XS HI AS nM NM MD jM jI MC ch \
    --outSAMstrandField intronMotif

samtools index -@ "${threads}" "${bam}"

cd "${out_dir}" || exit 1
ln -s "$(basename "${bam}")" "$(basename "${bam_renamed}")"
ln -s "$(basename "${bai}")" "$(basename "${bai_renamed}")"; } \
1> "${snakemake_log[0]}" 2>&1

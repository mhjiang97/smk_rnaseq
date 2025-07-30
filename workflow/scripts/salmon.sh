#!/usr/bin/env bash

# shellcheck disable=SC2154

set -x

{ dir=${snakemake_output[dir]}
index=${snakemake_params[index]}
layout=${snakemake_params[layout]}
threads=${snakemake[threads]}

if [ "${layout}" == "paired-end" ]; then
    fq_1=${snakemake_input[fq_1]}
    fq_2=${snakemake_input[fq_2]}
elif [ "${layout}" == "single-end" ]; then
    fq=${snakemake_input[fq]}
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] Unexpected layout: ${layout}"
    exit 1
fi

if [ "${layout}" == "paired-end" ]; then
    salmon quant --gcBias --seqBias -l A --threads "${threads}" -i "${index}" -1 "${fq_1}" -2 "${fq_2}" -o "${dir}"
else
    salmon quant --seqBias -l A --threads "${threads}" -i "${index}" -r "${fq}" -o "${dir}"
fi; } \
1> "${snakemake_log[0]}" 2>&1

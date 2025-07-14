#!/usr/bin/env bash

# shellcheck disable=SC2154

set -x

{ n_input=${#snakemake_input[@]}
dir=${snakemake_output[dir]}
threads=${snakemake[threads]}
index=${snakemake_params[index]}

if [ "${n_input}" -eq 6 ]; then
    pe=true
    fq_1=${snakemake_input[fq_1]}
    fq_2=${snakemake_input[fq_2]}
elif [ "${n_input}" -eq 4 ]; then
    pe=false
    fq=${snakemake_input[fq]}
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] Unexpected number of inputs: ${snakemake_input[*]}"
    exit 1
fi

if [ ${pe} == true ]; then
    salmon quant --gcBias --seqBias -l A --threads "${threads}" -i "${index}" -1 "${fq_1}" -2 "${fq_2}" -o "${dir}"
else
    salmon quant --seqBias -l A --threads "${threads}" -i "${index}" -r "${fq}" -o "${dir}"
fi; } \
1> "${snakemake_log[0]}" 2>&1

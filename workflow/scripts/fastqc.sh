#!/usr/bin/env bash
# shellcheck disable=SC2154

set -x


{ sample=${snakemake_wildcards[sample]}
dir=${snakemake_output[dir]}
threads=${snakemake[threads]}
n_input=${#snakemake_input[@]}

if [ "${n_input}" -eq 4 ]; then
    pe=true
    fq_1=${snakemake_input[fq_1]}
    fq_2=${snakemake_input[fq_2]}
elif [ "${n_input}" -eq 2 ]; then
    pe=false
    fq=${snakemake_input[fq]}
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] Unexpected number of inputs: ${snakemake_input[*]}"
    exit 1
fi

[ -d "${dir}" ] || mkdir -p "${dir}"

if [ ${pe} == true ]; then
    fastqc -o "${dir}" -t "${threads}" "${fq_1}" "${fq_2}"
else
    fastqc -o "${dir}" -t "${threads}" "${fq}"
fi; } \
1> "${snakemake_log[0]}" 2>&1

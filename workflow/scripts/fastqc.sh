#!/usr/bin/env bash
# shellcheck disable=SC2154

set -x


{ dir=${snakemake_output[dir]}
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

[ -d "${dir}" ] || mkdir -p "${dir}"

if [ "${layout}" == "paired-end" ]; then
    fastqc -o "${dir}" -t "${threads}" "${fq_1}" "${fq_2}"
else
    fastqc -o "${dir}" -t "${threads}" "${fq}"
fi; } \
1> "${snakemake_log[0]}" 2>&1

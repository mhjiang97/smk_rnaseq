#!/usr/bin/env bash
# shellcheck disable=SC2154

set -x


{ sample=${snakemake_wildcards[sample]}
json=${snakemake_output[json]}
html=${snakemake_output[html]}
layout=${snakemake_params[layout]}
threads=${snakemake[threads]}

if [ "${layout}" == "paired-end" ]; then
    fq_1=${snakemake_input[fq_1]}
    fq_2=${snakemake_input[fq_2]}
    fq_1_clean=${snakemake_output[fq_1]}
    fq_2_clean=${snakemake_output[fq_2]}
    fq_1_up=${snakemake_output[fq_1_unpaired]}
    fq_2_up=${snakemake_output[fq_2_unpaired]}
    fq_failed=${snakemake_output[fq_failed]}
elif [ "${layout}" == "single-end" ]; then
    fq=${snakemake_input[fq]}
    fq_clean=${snakemake_output[fq]}
    fq_failed=${snakemake_output[fq_failed]}
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] Unexpected layout: ${layout}"
    exit 1
fi

if [ "${layout}" == "paired-end" ]; then
    fastp \
        --thread "${threads}" --detect_adapter_for_pe \
        --in1 "${fq_1}" --in2 "${fq_2}" \
        --out1 "${fq_1_clean}" --out2 "${fq_2_clean}" \
        --unpaired1 "${fq_1_up}" --unpaired2 "${fq_2_up}" \
        --failed_out "${fq_failed}" \
        --json "${json}" --html "${html}"
else
    fastp \
        --thread "${threads}" --detect_adapter_for_pe \
        -i "${fq}" -o "${fq_clean}" --failed_out "${fq_failed}" \
        --json "${json}" --html "${html}"
fi; } \
1> "${snakemake_log[0]}" 2>&1

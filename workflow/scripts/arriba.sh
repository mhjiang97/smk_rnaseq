#!/usr/bin/env bash

# shellcheck disable=SC2154

set -x


{ sample=${snakemake_wildcards[sample]}
fasta=${snakemake_input[fasta]}
gtf=${snakemake_input[gtf]}
index=${snakemake_input[index]}
fusion=${snakemake_output[fusion]}
fusion_discarded=${snakemake_output[fusion_discarded]}
bam=${snakemake_output[bam]}
log=${snakemake_output[log]}
log_final=${snakemake_output[log_final]}
log_progress=${snakemake_output[log_progress]}
log_std=${snakemake_output[log_std]}
sj=${snakemake_output[sj]}
layout=${snakemake_params[layout]}
genome=${snakemake_params[genome]}
dir_tmp=${snakemake_params[dir_tmp]}
threads=${snakemake[threads]}
mem_mb=${snakemake_resources[mem_mb]}


if [ "${layout}" == "paired-end" ]; then
    files_in=("${snakemake_input[fq_1]}" "${snakemake_input[fq_2]}")
elif [ "${layout}" == "single-end" ]; then
    files_in=("${snakemake_input[fq]}")
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] Unexpected layout: ${layout}"
    exit 1
fi

if [ "${genome}" == "hg38" ] || [ "${genome}" == "GRCh38" ]; then
    blacklist=/arriba_v2.5.1/database/blacklist_hg38_GRCh38_v2.5.1.tsv.gz
    known_fusions=/arriba_v2.5.1/database/known_fusions_hg38_GRCh38_v2.5.1.tsv.gz
    protein_domains=/arriba_v2.5.1/database/protein_domains_hg38_GRCh38_v2.5.1.gff3
elif [ "${genome}" == "hg19" ] || [ "${genome}" == "GRCh37" ]; then
    blacklist=/arriba_v2.5.1/database/blacklist_hg19_GRCh37_v2.5.1.tsv.gz
    known_fusions=/arriba_v2.5.1/database/known_fusions_hg19_GRCh37_v2.5.1.tsv.gz
    protein_domains=/arriba_v2.5.1/database/protein_domains_hg19_GRCh37_v2.5.1.gff3
elif [ "${genome}" == "mm39" ] || [ "${genome}" == "GRCm39" ]; then
    blacklist=/arriba_v2.5.1/database/blacklist_mm39_GRCm39_v2.5.1.tsv.gz
    known_fusions=/arriba_v2.5.1/database/known_fusions_mm39_GRCm39_v2.5.1.tsv.gz
    protein_domains=/arriba_v2.5.1/database/protein_domains_mm39_GRCm39_v2.5.1.gff3
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] Unexpected genome: ${genome}"
    exit 1
fi

[[ "${files_in[0]}" == *".gz" ]] && cmd_read="zcat" || cmd_read="cat"

STAR \
    --outTmpDir "${dir_tmp}" \
    --runThreadN "${threads}" \
    --genomeDir "${index}" \
    --genomeLoad NoSharedMemory \
    --readFilesIn "${files_in[@]}" \
    --readFilesCommand "${cmd_read}" \
    --outStd BAM_Unsorted \
    --outSAMtype BAM Unsorted \
    --outSAMunmapped Within \
    --outBAMcompression 0 \
    --outFilterMultimapNmax 50 \
    --peOverlapNbasesMin 10 \
    --alignSplicedMateMapLminOverLmate 0.5 \
    --alignSJstitchMismatchNmax 5 -1 5 5 \
    --chimSegmentMin 10 \
    --chimOutType WithinBAM HardClip \
    --chimJunctionOverhangMin 10 \
    --chimScoreDropMax 30 \
    --chimScoreJunctionNonGTAG 0 \
    --chimScoreSeparation 1 \
    --chimSegmentReadGapMax 3 \
    --chimMultimapNmax 50 \
    | tee "${bam}" \
    | /arriba_v2.5.1/arriba \
        -x /dev/stdin \
        -o "${fusion}" \
        -O "${fusion_discarded}" \
        -a "${fasta}" \
        -g "${gtf}" \
        -b "${blacklist}" \
        -k "${known_fusions}" \
        -t "${known_fusions}" \
        -p "${protein_domains}"

mv Log.final.out "${log_final}"
mv Log.out "${log}"
mv Log.progress.out "${log_progress}"
mv Log.std.out "${log_std}"
mv SJ.out.tab "${sj}"; } \
1> "${snakemake_log[0]}" 2>&1

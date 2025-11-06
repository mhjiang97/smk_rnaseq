TO_LEARN_READ_ORIENTATION = False

PARAMETERS_CHECK = [
    "gtf",
    "fasta",
    "fasta_transcriptome",
    "polymorphism_known",
    "dbsnp",
    "pon",
    "resource_germline",
]

COLS_CHECK = {"dna_control_bam", "dna_sample_name"}

FIELDS_COMMON = (
    "CHROM POS ID REF ALT QUAL "
    "ANN[*].ALLELE ANN[*].EFFECT ANN[*].IMPACT ANN[*].GENE ANN[*].GENEID "
    "ANN[*].FEATURE ANN[*].FEATUREID ANN[*].BIOTYPE ANN[*].RANK ANN[*].HGVS_C "
    "ANN[*].HGVS_P ANN[*].CDNA_POS ANN[*].CDNA_LEN ANN[*].CDS_POS "
    "ANN[*].CDS_LEN ANN[*].AA_POS ANN[*].AA_LEN ANN[*].DISTANCE ANN[*].ERRORS "
    "LOF[*].GENE LOF[*].GENEID LOF[*].NUMTR LOF[*].PERC "
    "NMD[*].GENE NMD[*].GENEID NMD[*].NUMTR NMD[*].PERC"
)

CALLER2FMTS = {
    "haplotypecaller": ["GT", "AD", "DP", "F1R2", "F2R1", "GQ", "PL"],
    "mutect2": ["GT", "AD", "AF", "DP", "F1R2", "F2R1", "FAD", "SB"],
}

ANNOTATOR2SUFFIX = {
    "vep": ".vep.maf",
    "snpeff": ".snpeff.tsv",
    "annovar": ".annovar.tsv",
}

PROTOCOLS_UCSC = ["cytoBand"]

RULES = [
    "apply_bqsr",
    "base_recalibrator",
    "calculate_contamination",
    "convert_snpeff",
    "convert_vep",
    "create_sequence_dictionary",
    "download_snpeff_cache",
    "download_vep_cache",
    "extract_annotations",
    "fastp_paired_end",
    "fastp_single_end",
    "fastqc",
    "filter_mutect_calls",
    "format_haplotypecaller",
    "get_pileup_summaries",
    "get_pileup_summaries_dna",
    "gtf_to_bed_transcript",
    "haplotypecaller",
    "hard_filter",
    "learn_read_orientation_model",
    "mark_duplicates",
    "multiqc",
    "mutect2",
    "salmon",
    "salmon_index",
    "samtools_faidx",
    "slop_bed",
    "snpeff",
    "snpeff_check",
    "split_n_cigar_reads",
    "star",
    "star_index",
    "vep",
    "vep_check",
]

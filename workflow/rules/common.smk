# *--------------------------------------------------------------------------* #
# * Configuration                                                            * #
# *--------------------------------------------------------------------------* #
from pathlib import Path

from snakemake.utils import validate


include: "utils.smk"


configfile: "config/config.yaml"


validate(config, "../schemas/config.schema.yaml")


pepfile: "config/pep/config.yaml"


pepschema: "../schemas/pep.schema.yaml"


if config["dir_run"] and config["dir_run"] is not None:

    workdir: config["dir_run"]


# *--------------------------------------------------------------------------* #
# * Constants                                                                * #
# *--------------------------------------------------------------------------* #
MAPPER = config["mapper"]
QUANTIFIER = config["quantifier"]
CALLERS = ["haplotypecaller"]
ANNOTATORS = config["annotators"]

MUTATIONS = ["snvs", "indels"]

SUFFIXES = config["suffixes_fastq"]
SUFFIX_READ_1, SUFFIX_READ_2 = SUFFIXES["paired-end"]
SUFFIX_READ_SE = SUFFIXES["single-end"]

DF_SAMPLE = pep.sample_table
SAMPLES = DF_SAMPLE["sample_name"]
SAMPLES_PE = SAMPLES[DF_SAMPLE["library_layout"] == "paired-end"]
SAMPLES_SE = SAMPLES[DF_SAMPLE["library_layout"] == "single-end"]

DIR_DATA = config["dir_data"]

SLOP = config["slop_transcript"]

TO_QUANTIFY = config["quantification"]
TO_CALL_MUTATIONS = config["mutation"]
TO_CLEAN_FQ = config["clean_fq"]
TO_RUN_FASTQC = config["run_fastqc"]
TO_RUN_MULTIQC = config["run_multiqc"]
TO_CHECK_ANNOTATIONS = config["check_annotations"]

RULES = [
    "apply_bqsr",
    "base_recalibrator",
    "convert_snpeff",
    "convert_vep",
    "create_sequence_dictionary",
    "download_snpeff_cache",
    "download_vep_cache",
    "fastp_paired_end",
    "fastp_single_end",
    "fastqc",
    "filter_mutect_calls",
    "format_haplotypecaller",
    "gtf_to_bed_transcript",
    "haplotypecaller",
    "hard_filter",
    "extract_annotations",
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


# *--------------------------------------------------------------------------* #
# * Wildcard constraints                                                     * #
# *--------------------------------------------------------------------------* #
wildcard_constraints:
    sample=r"|".join(SAMPLES),
    caller=r"|".join(CALLERS),
    mutation=r"|".join(MUTATIONS),
    annotator=r"|".join(ANNOTATORS),


# *--------------------------------------------------------------------------* #
# * Files and directories required by a few rules                            * #
# *--------------------------------------------------------------------------* #
dict_fasta = Path(config["fasta"]).with_suffix(".dict").as_posix()
fai_fasta = f"{config['fasta']}.fai"
bed_transcript = Path(config["gtf"]).with_suffix(".transcript.bed").as_posix()
bed_transcript_slopped = (
    Path(bed_transcript).with_suffix(f".slopped_{config['slop_transcript']}.bed").as_posix()
)

path_cache_snpeff = (
    f"{config['cache_snpeff']}/{config['genome']}.{config['version_snpeff']}"
)
path_cache_vep = (
    f"{config['cache_vep']}/{config['species']}/{config['version_vep']}_{config['genome']}"
)


# *--------------------------------------------------------------------------* #
# * Additional validation for config parameters                              * #
# *--------------------------------------------------------------------------* #
perform_validations_with_rich(
    config,
    workflow.source_path("../envs/vep.yaml"),
    [
        "gtf",
        "fasta",
        "fasta_transcriptome",
        "polymorphism_known",
        "dbsnp",
        "pon",
        "resource_germline",
    ],
)

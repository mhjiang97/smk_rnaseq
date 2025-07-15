# *--------------------------------------------------------------------------* #
# * Configuration                                                            * #
# *--------------------------------------------------------------------------* #
from pathlib import Path
from snakemake.utils import validate


configfile: "config/config.yaml"


pepfile: "config/pep/config.yaml"


pepschema: "../schemas/pep.schema.yaml"


wildcard_constraints:
    sample=r"[\w-]+",
    caller=r"[\w]+",
    mutation=r"(snvs|indels)",
    annotator=r"(snpeff|vep)",


if config["dir_run"] and config["dir_run"] is not None:

    workdir: config["dir_run"]


validate(config, "../schemas/config.schema.yaml")


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

TO_CLEAN_FQ = config["clean_fq"]
TO_CHECK_ANNOTATIONS = config["check_annotations"]


# *--------------------------------------------------------------------------* #
# * Final targets to be retrieved                                            * #
# *--------------------------------------------------------------------------* #
targets = []

if QUANTIFIER == "salmon":
    targets += [f"{QUANTIFIER}/{sample}/quant.sf" for sample in SAMPLES]

targets += [
    f"{caller}/{sample}/{sample}.{mutation}{suffix}"
    for sample in SAMPLES
    for caller in CALLERS
    for mutation in MUTATIONS
    for suffix in [".vep.maf", ".snpeff.tsv"]
]

if TO_CLEAN_FQ:
    targets += [f"fastp/{sample}/{sample}.json" for sample in SAMPLES] + [
        f"fastqc/fastp/{sample}" for sample in SAMPLES
    ]

    if config["run_multiqc"]:
        targets += ["multiqc/fastp/multiqc_report.html"]


# *--------------------------------------------------------------------------* #
# * Files required by a few rules                                            * #
# *--------------------------------------------------------------------------* #
dict_fasta = Path(config["fasta"]).with_suffix(".dict").__str__()


# *--------------------------------------------------------------------------* #
# * Functions to get input files for rules                                   * #
# *--------------------------------------------------------------------------* #
def get_fastq_files(wildcards):
    sample = wildcards.sample
    dir_base = "fastp/{sample}" if TO_CLEAN_FQ else DIR_DATA

    if sample in SAMPLES_PE:
        return {
            "fq_1": f"{dir_base}/{{sample}}{SUFFIX_READ_1}",
            "fq_2": f"{dir_base}/{{sample}}{SUFFIX_READ_2}",
        }
    elif sample in SAMPLES_SE:
        return {"fq": f"{dir_base}/{{sample}}{SUFFIX_READ_SE}"}
    else:
        raise ValueError(f"Sample {sample} not found in SAMPLES_PE or SAMPLES_SE.")


def get_fastqc_inputs(wildcards):
    sample = wildcards.sample

    if sample in SAMPLES_PE:
        return {
            "fq_1": f"fastp/{{sample}}/{{sample}}{SUFFIX_READ_1}",
            "fq_2": f"fastp/{{sample}}/{{sample}}{SUFFIX_READ_2}",
        }
    elif sample in SAMPLES_SE:
        return {"fq": f"fastp/{{sample}}/{{sample}}{SUFFIX_READ_SE}"}
    else:
        raise ValueError(f"Sample {sample} not found in SAMPLES_PE or SAMPLES_SE.")

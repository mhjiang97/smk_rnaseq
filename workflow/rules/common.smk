# *--------------------------------------------------------------------------* #
# * Configuration                                                            * #
# *--------------------------------------------------------------------------* #
import logging
from math import floor
from pathlib import Path

import yaml
from rich.console import Console
from rich.logging import RichHandler
from snakemake.utils import validate


include: "utils.smk"


configfile: "config/config.yaml"


validate(config, "../schemas/config.schema.yaml")


pepfile: "config/pep/config.yaml"


pepschema: "../schemas/pep.schema.yaml"


path_env_vep = Path("workflow/envs/vep.yaml").resolve()


if config["dir_run"] and config["dir_run"] is not None:

    workdir: config["dir_run"]


# *--------------------------------------------------------------------------* #
# * Additional validation for config parameters                              * #
# *--------------------------------------------------------------------------* #
perform_validations_with_rich(
    config,
    path_env_vep,
    ["gtf", "fasta", "fasta_transcriptome", "polymorphism_known", "dbsnp"],
)


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
TO_RUN_MULTIQC = config["run_multiqc"]
TO_CHECK_ANNOTATIONS = config["check_annotations"]


# *--------------------------------------------------------------------------* #
# * Wildcard constraints                                                     * #
# *--------------------------------------------------------------------------* #
wildcard_constraints:
    sample=r"|".join(SAMPLES),
    caller=r"|".join(CALLERS),
    mutation=r"|".join(MUTATIONS),
    annotator=r"|".join(ANNOTATORS),


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

    if TO_RUN_MULTIQC:
        targets += ["multiqc/fastp/multiqc_report.html"]


# *--------------------------------------------------------------------------* #
# * Files required by a few rules                                            * #
# *--------------------------------------------------------------------------* #
dict_fasta = Path(config["fasta"]).with_suffix(".dict").__str__()

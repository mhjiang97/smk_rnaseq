import logging
from math import floor
from pathlib import Path

import yaml
from rich.console import Console
from rich.logging import RichHandler


def get_targets():
    targets = []

    if TO_QUANTIFY:
        if QUANTIFIER == "salmon":
            targets += [f"{QUANTIFIER}/{sample}/quant.sf" for sample in SAMPLES]

    if TO_QUANTIFY_TE:
        if QUANTIFIER_TE == "featurecounts":
            targets += [
                f"featurecounts/{sample}/te{suffix}"
                for sample in SAMPLES
                for suffix in [".tsv", ".unique.tsv", ".unique.overlap.tsv"]
            ]

    if TO_CALL_MUTATIONS:
        targets += [
            f"{caller}/{sample}/{sample}.{mutation}{suffix}"
            for sample in SAMPLES
            for caller in CALLERS
            for mutation in MUTATIONS
            for suffix in [".vep.maf", ".snpeff.tsv"]
        ]

    if TO_CLEAN_FQ:
        targets += [f"fastp/{sample}/{sample}.json" for sample in SAMPLES]
        if TO_RUN_FASTQC:
            targets += [f"fastqc/fastp/{sample}" for sample in SAMPLES]
            if TO_RUN_MULTIQC:
                targets += ["multiqc/fastp/multiqc_report.html"]
    else:
        if TO_RUN_FASTQC:
            targets += [f"fastqc/{sample}" for sample in SAMPLES]
            if TO_RUN_MULTIQC:
                targets += ["multiqc/multiqc_report.html"]

    return targets


# *--------------------------------------------------------------------------* #
# * Functions to validate files in the config file and VEP cache version     * #
# *--------------------------------------------------------------------------* #
def validate_vep_version(config, env_file):
    with open(env_file, "r") as f:
        config_vep = yaml.safe_load(f)

    dependencies = config_vep.get("dependencies", [])
    dependency_vep = next(
        (
            dep
            for dep in dependencies
            if isinstance(dep, str) and dep.startswith("ensembl-vep")
        ),
        None,
    )

    version_vep = dependency_vep.split("=")[1]
    version_env_major = floor(float(version_vep))
    version_config = config["version_vep"]

    if version_env_major != version_config:
        logger.warning(
            f"[bold yellow]⚠ VEP version mismatch detected[/]: "
            f"config = [cyan]{version_config}[/], env = [magenta]{version_env_major}[/]."
        )
        logger.info(
            f"[bold green]Recommendation:[/] Align the VEP version in 'config/config.yaml' with 'workflow/envs/vep.yaml'."
        )


def validate_files(config, parameters):
    for param in parameters:
        paths = config[param]
        paths = [paths] if isinstance(paths, str) else paths

        missing = [p for p in paths if not Path(p).exists()]
        if missing:
            files = ", ".join(f"[dim]'{f}'[/]" for f in missing)
            logger.error(
                f"[bold red]✖ Missing file(s)[/]: {files} not found for parameter '{param}'."
            )
            logger.info(
                f"[bold cyan]Hint:[/] Please verify the paths in 'config/config.yaml'."
            )
            raise ValueError()


def validate_extra_arguments(config):
    if "args_extra" in config:
        for r in config["args_extra"].keys():
            if r not in RULES:
                logger.error(
                    f"[bold red]✖ Invalid rule name[/]: '{r}' in 'args_extra'."
                )
                logger.info(
                    f"[bold cyan]Hint:[/] Available rules are: {', '.join(RULES)}."
                )
                raise ValueError()


def perform_validations_with_rich(config, vep_env_path, file_params):
    root = logging.getLogger()
    old_level = root.level
    old_handlers = root.handlers.copy()

    console = Console()
    logging.basicConfig(
        level=logging.INFO,
        format="%(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[RichHandler(console=console, rich_tracebacks=True, markup=True)],
    )
    logger = logging.getLogger()

    validate_vep_version(config, vep_env_path)
    validate_files(config, file_params)
    validate_extra_arguments(config)

    root.setLevel(old_level)
    root.handlers = old_handlers


# *--------------------------------------------------------------------------* #
# * Functions to get input files and parameters                              * #
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


def get_library_layout(wildcards):
    sample = wildcards.sample
    layout = DF_SAMPLE["library_layout"][sample]

    if layout not in ["paired-end", "single-end"]:
        raise ValueError(f"Unexpected library layout '{layout}' for sample '{sample}'.")

    return layout


def get_featurecounts_arguments(wildcards):
    sample = wildcards.sample
    layout = DF_SAMPLE["library_layout"][sample]

    arg = "-p --countReadPairs" if layout == "paired-end" else ""

    return arg


def get_extra_arguments(rule_name):
    if "args_extra" in config and rule_name in config["args_extra"]:
        return config["args_extra"][rule_name]

    return ""


def get_interval_bed():
    if SLOP > 0:
        return bed_transcript_slopped
    else:
        return bed_transcript


def get_mutect2_inputs(wildcards):
    sample = wildcards.sample

    inputs = {
        "bam": f"{MAPPER}/{sample}/{sample}.sorted.md.splitn.recal.bam",
        "bed": get_interval_bed(),
        "fasta": config["fasta"],
        "resource_germline": config["resource_germline"],
        "pon": config["pon"],
    }

    if COLS_CHECK.issubset(DF_SAMPLE.columns):
        bam_dna = DF_SAMPLE["dna_control_bam"][sample]
        name_dna = DF_SAMPLE["dna_sample_name"][sample]
        if bam_dna and Path(bam_dna).exists() and name_dna:
            inputs["bam_dna"] = bam_dna

    return inputs


def get_mutect2_arguments(wildcards):
    sample = wildcards.sample

    args = ""

    if COLS_CHECK.issubset(DF_SAMPLE.columns):
        bam_dna = DF_SAMPLE["dna_control_bam"][sample]
        name_dna = DF_SAMPLE["dna_sample_name"][sample]
        if bam_dna and Path(bam_dna).exists() and name_dna:
            args += f"-I {bam_dna} -normal {name_dna}"

    return args


def get_dna_control_bam(wildcards):
    sample_dna = wildcards.sample_dna

    bam_dna = DF_SAMPLE["dna_control_bam"][DF_SAMPLE["dna_sample_name"] == sample_dna]

    return bam_dna


def get_calculate_contamination_inputs(wildcards):
    sample = wildcards.sample

    inputs = {
        "table": f"mutect2/{sample}/{sample}.pileups.table",
    }

    if COLS_CHECK.issubset(DF_SAMPLE.columns):
        bam_dna = DF_SAMPLE["dna_control_bam"][sample]
        name_dna = DF_SAMPLE["dna_sample_name"][sample]
        if bam_dna and Path(bam_dna).exists() and name_dna:
            inputs["table_dna"] = f"mutect2/{name_dna}-dna/{name_dna}.pileups.table"

    return inputs


def get_calculate_contamination_arguments(wildcards):
    sample = wildcards.sample

    args = ""

    if COLS_CHECK.issubset(DF_SAMPLE.columns):
        bam_dna = DF_SAMPLE["dna_control_bam"][sample]
        name_dna = DF_SAMPLE["dna_sample_name"][sample]
        if bam_dna and Path(bam_dna).exists() and name_dna:
            args += f"--matched-normal mutect2/{name_dna}-dna/{name_dna}.pileups.table"

    return args


def get_filter_mutect_calls_inputs(wildcards):
    sample = wildcards.sample

    inputs = {
        "vcf": f"mutect2/{sample}/{sample}.raw.vcf",
        "bed": get_interval_bed(),
        "fasta": config["fasta"],
        "table_contamination": f"mutect2/{sample}/{sample}.contamination.table",
        "table_segmentation": f"mutect2/{sample}/{sample}.segmentation.table",
    }

    if TO_LEARN_READ_ORIENTATION:
        inputs["table_artifact"] = f"mutect2/{sample}/{sample}.artifactprior.tar.gz"

    return inputs


def get_filter_mutect_calls_arguments(wildcards):
    sample = wildcards.sample

    args = ""

    if TO_LEARN_READ_ORIENTATION:
        args += f"--orientation-bias-artifact-priors mutect2/{sample}/{sample}.artifactprior.tar.gz"

    return args

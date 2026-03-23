import logging
import re
from functools import lru_cache
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
            for suffix in SUFFIXES_FINAL
        ]
        targets += [
            f"{caller}/{sample}/{sample}.snv_strandedness.tsv"
            for sample in SAMPLES
            for caller in CALLERS
        ]

        if "strandedness" not in DF_SAMPLE or DF_SAMPLE["strandedness"].isna().any():
            targets += [PATH_OUTPUT_SAMPLE_TABLE]

        if SAMPLES_DNA.size > 0:
            targets += [
                f"{caller}/{sample}/{sample}-{sample_dna}-rna_editing.bed"
                for sample, sample_dna in DF_SAMPLE.loc[
                    SAMPLES_HAVE_DNA, "dna_sample_name"
                ].items()
                for caller in CALLERS
            ]

    if TO_CALL_FUSION:
        if "arriba" in CALLERS_FUSION:
            targets += [f"arriba/{sample}/fusions.tsv" for sample in SAMPLES]

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


def validate_vep_container_version(config, rule_file):
    with open(rule_file, "r") as f:
        text = f.read()

    pattern = re.compile(r"docker://ensemblorg/ensembl-vep:release_(\d+(?:\.\d+)?)")
    match = pattern.search(text)
    if match is None:
        logger.warning(
            f"[bold yellow]⚠ Unable to validate VEP container version[/]: "
            f"no 'docker://ensemblorg/ensembl-vep:release_<version>' found in '{rule_file}'."
        )
        return

    version_container = match.group(1)
    version_container_major = floor(float(version_container))
    version_config = config["version_vep"]

    if version_container_major != version_config:
        logger.warning(
            f"[bold yellow]⚠ VEP version mismatch detected[/]: "
            f"config = [cyan]{version_config}[/], container = [magenta]{version_container_major}[/]."
        )
        logger.info(
            f"[bold green]Recommendation:[/] Align the VEP version in 'config/config.yaml' with 'workflow/rules/annotator/vep.smk'."
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


def perform_validations_with_rich(
    config, vep_env_path, file_params, vep_rule_path=None
):
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
    if vep_rule_path is not None:
        validate_vep_container_version(config, vep_rule_path)
    validate_files(config, file_params)
    validate_extra_arguments(config)

    root.setLevel(old_level)
    root.handlers = old_handlers


# *--------------------------------------------------------------------------* #
# * Functions to validate the sample table                                   * #
# *--------------------------------------------------------------------------* #
def _bam_sm_tags(bam_file):
    import pysam

    sm_tags = set()
    with pysam.AlignmentFile(bam_file, "rb") as bam:
        for read_group in bam.header.get("RG", []):
            sm = read_group.get("SM")
            if sm:
                sm_tags.add(sm)

    return sm_tags


def validate_dna_controls_distinct(df_sample):
    if not COLS_CHECK.issubset(df_sample.columns):
        return None

    for _, row in df_sample.iterrows():
        bam = row.get("dna_control_bam")
        rna_sample = row.get("sample_name")
        dna_name = row.get("dna_sample_name")
        if not bam or not Path(bam).exists():
            continue

        sm_tags = _bam_sm_tags(bam)
        if rna_sample in sm_tags:
            logger.error(
                f"[bold red]✖ DNA control sample conflict[/]: "
                f"dna_control_bam '{bam}' contains RNA sample_name '{rna_sample}' in its @RG SM tags {sorted(sm_tags)}."
            )
            raise ValueError()

        if dna_name and sm_tags and dna_name not in sm_tags:
            logger.error(
                f"[bold red]✖ DNA control sample name mismatch[/]: "
                f"dna_sample_name '{dna_name}' not found in @RG SM tags {sorted(sm_tags)} of dna_control_bam '{bam}'."
            )
            raise ValueError()


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
        raise ValueError(
            f"Unexpected library layout '{layout}' for sample '{sample}'."
        )

    return layout


def get_featurecounts_arguments(wildcards):
    sample = wildcards.sample
    layout = DF_SAMPLE["library_layout"][sample]

    arg = "-p --countReadPairs" if layout == "paired-end" else ""

    return arg


def determine_strandedness(wildcards):
    """Determine library strandedness for a sample.

    First checks for a 'strandedness' column in the sample table. If absent or
    empty, parses the Salmon quantification log to auto-detect the library type
    from a line like:
        [2026-03-08 23:27:57.219] [jointLog] [info] Automatically detected most likely library type as IU

    Returns:
        str: One of "fr-firststrand", "fr-secondstrand", or "unstranded".
    """
    sample = wildcards.sample

    if "strandedness" in DF_SAMPLE.columns:
        val = DF_SAMPLE["strandedness"][sample]
        if val and str(val).strip():
            return str(val).strip()

    # salmon_log = f"logs/{sample}/salmon.log"
    salmon_log = checkpoints.salmon.get(sample=sample).output[0]
    if not Path(salmon_log).exists():
        raise FileNotFoundError(
            f"Cannot determine strandedness for sample '{sample}': "
            f"no 'strandedness' column in sample table and salmon log '{salmon_log}' not found."
        )

    pattern = re.compile(r"Automatically detected most likely library type as (\S+)")
    with open(salmon_log) as f:
        for line in f:
            m = pattern.search(line)
            if m:
                libtype = m.group(1)
                result = SALMON_LIBTYPE_TO_STRANDEDNESS.get(libtype)
                if result is None:
                    raise ValueError(
                        f"Unknown Salmon library type '{libtype}' for sample '{sample}'. "
                        f"Expected one of: {', '.join(SALMON_LIBTYPE_TO_STRANDEDNESS)}."
                    )

                DF_SAMPLE_COPY.at[sample, "strandedness"] = result

                return result

    raise ValueError(
        f"Cannot determine strandedness for sample '{sample}': "
        f"no library type detected in salmon log '{salmon_log}'."
    )


def get_extra_arguments(rule_name):
    if "args_extra" in config and rule_name in config["args_extra"]:
        return config["args_extra"][rule_name]

    return ""


def get_interval_bed():
    if SLOP > 0:
        return bed_transcript_slopped
    else:
        return bed_transcript


def check_dna_control(sample):
    if COLS_CHECK.issubset(DF_SAMPLE.columns):
        bam_dna = DF_SAMPLE["dna_control_bam"][sample]
        name_dna = DF_SAMPLE["dna_sample_name"][sample]
        if bam_dna and Path(bam_dna).exists() and name_dna:
            return True

    return False


def get_mutect2_inputs(wildcards):
    sample = wildcards.sample

    inputs = {
        "bam": f"{MAPPER}/{sample}/{sample}.sorted.md.splitn.recal.bam",
        "fasta": config["fasta"],
        "resource_germline": config["resource_germline"],
        "pon": config["pon"],
    }

    if check_dna_control(sample):
        bam_dna = DF_SAMPLE["dna_control_bam"][sample]
        inputs["bam_dna"] = bam_dna

    return inputs


def get_mutect2_arguments(wildcards):
    sample = wildcards.sample

    args = ""

    if check_dna_control(sample):
        bam_dna = DF_SAMPLE["dna_control_bam"][sample]
        name_dna = DF_SAMPLE["dna_sample_name"][sample]
        args += f"-I {bam_dna} -normal {name_dna}"

    return args


def get_dna_control_bam(wildcards):
    sample_dna = wildcards.sample_dna

    bam_dna = DF_SAMPLE["dna_control_bam"][
        DF_SAMPLE["dna_sample_name"] == sample_dna
    ].unique()

    return bam_dna


def get_calculate_contamination_inputs(wildcards):
    sample = wildcards.sample

    inputs = {
        "table": f"mutect2/{sample}/{sample}.pileups.table",
    }

    if check_dna_control(sample):
        name_dna = DF_SAMPLE["dna_sample_name"][sample]
        inputs["table_dna"] = f"mutect2/{name_dna}-dna/{name_dna}.pileups.table"

    return inputs


def get_calculate_contamination_arguments(wildcards):
    sample = wildcards.sample

    args = ""

    if check_dna_control(sample):
        name_dna = DF_SAMPLE["dna_sample_name"][sample]
        args += f"--matched-normal mutect2/{name_dna}-dna/{name_dna}.pileups.table"

    return args


def get_filter_mutect_calls_inputs(wildcards):
    sample = wildcards.sample

    inputs = {
        "vcf": f"mutect2/{sample}/{sample}.raw.vcf",
        "stats": f"mutect2/{sample}/{sample}.raw.vcf.stats",
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


def has_dna_control(wildcards):
    sample = wildcards.sample

    if check_dna_control(sample):
        return True

    return False


def get_convert_vep_arguments(wildcards):
    sample = wildcards.sample

    arg = ""

    if check_dna_control(sample):
        name_dna = DF_SAMPLE["dna_sample_name"][sample]
        arg += f"--normal-id {name_dna} --vcf-normal-id {name_dna}"

    return arg


def get_convert_snpeff_arguments(wildcards):
    caller = wildcards.caller

    fields = CALLER2FMTS.get(caller)
    if fields is None:
        raise ValueError("Unsupported caller")

    arg = " ".join(f"GEN[*].{field}" for field in fields)

    return arg


def get_snv_filters(wildcards):
    caller = wildcards.caller
    sample = wildcards.sample

    min_reads = config["min_reads"]
    min_coverage = config["min_coverage"]

    if caller == "haplotypecaller":
        filters = (
            f"QUAL >= 30 & "
            f"INFO/QD >= 2 & "
            f"FMT/DP[0] >= {min_coverage} & "
            f"FMT/AD[0:1] >= {min_reads} & "
            f"TYPE = 'snp' & "
            f"INFO/SOR <= 3 & "
            f"INFO/FS <= 30 & "
            f"INFO/MQ >= 40 & "
            f"INFO/MQRankSum >= -12.5 & "
            f"INFO/ReadPosRankSum >= -8"
        )
    elif caller == "mutect2":
        filters = f"FILTER = 'PASS' & " f"INFO/TLOD >= 6.3 & " f"TYPE = 'snp'"
        if check_dna_control(sample):
            sample_dna = DF_SAMPLE["dna_sample_name"][sample]
            index_sample = 0 if sample < sample_dna else 1
            filters += f" & FMT/AD[{index_sample}:1] >= {min_reads}"
            filters += f" & FMT/DP[{index_sample}] >= {min_coverage}"
        else:
            filters += f" & FMT/AD[0:1] >= {min_reads}"
            filters += f" & FMT/DP[0] >= {min_coverage}"
    else:
        raise ValueError("Unsupported caller")

    return filters


def get_indel_filters(wildcards):
    caller = wildcards.caller
    sample = wildcards.sample

    min_reads = config["min_reads"]
    min_coverage = config["min_coverage"]

    if caller == "haplotypecaller":
        filters = (
            f"QUAL >= 30 & "
            f"INFO/QD >= 2 & "
            f"FMT/DP[0] >= {min_coverage} & "
            f"FMT/AD[0:1] >= {min_reads} & "
            f"TYPE = 'indel' & "
            f"INFO/SOR <= 4 & "
            f"INFO/FS <= 200 & "
            f"INFO/ReadPosRankSum >= -20"
        )
    elif caller == "mutect2":
        filters = f"FILTER = 'PASS' & " f"INFO/TLOD >= 6.3 & " f"TYPE = 'indel'"
        if check_dna_control(sample):
            sample_dna = DF_SAMPLE["dna_sample_name"][sample]
            index_sample = 0 if sample < sample_dna else 1
            filters += f" & FMT/AD[{index_sample}:1] >= {min_reads}"
            filters += f" & FMT/DP[{index_sample}] >= {min_coverage}"
        else:
            filters += f" & FMT/AD[0:1] >= {min_reads}"
            filters += f" & FMT/DP[0] >= {min_coverage}"
    else:
        raise ValueError("Unsupported caller")

    return filters


def convert_genome(genome):
    map_g = {
        "GRCh38": "hg38",
        "GRCh37": "hg19",
        "hg19": "hg19",
        "hg38": "hg38",
        "GRCm39": "mm39",
        "mm39": "mm39",
    }

    g_new = map_g.get(genome)

    if g_new is None:
        raise ValueError(f"Unsupported genome '{genome}'")

    return g_new


def get_annovar_inputs(wildcards):
    sample = wildcards.sample
    caller = wildcards.caller

    inputs = {
        "annovar": f"{caller}/{sample}/av.{sample}.avinput",
    }

    for o in ["gene", "region", "filter"]:
        values = config["protocols"][o]
        for v in values:
            inputs[v] = ancient(f"{config['cache_annovar']}/{GENOME2}_{v}.txt")

    return inputs


def get_annovar_arguments():
    protocols = []
    operations = []
    for o in ["gene", "region", "filter"]:
        values = config["protocols"][o]
        for v in values:
            protocols.append(v)
            if o == "filter":
                operations.append("f")
            elif o == "region":
                operations.append("r")
            elif o == "gene":
                operations.append("g")

    return {
        "protocol": ",".join(protocols),
        "operation": ",".join(operations),
    }


# *--------------------------------------------------------------------------* #
# * Functions to estimate memory requirements                                * #
# *--------------------------------------------------------------------------* #
def get_star_mem_mb(wildcards, attempt=1):
    return get_star_genome_mem_mb() + get_star_sort_mem_mb(wildcards, attempt)


def get_star_genome_mem_mb():
    species = config["species"]
    genome = config["genome"]

    if species in {"homo_sapiens", "mus_musculus"} or genome.startswith(
        ("GRCh", "GRCm")
    ):
        mem_mb = 32000
    else:
        mem_mb = 16000

    return max(mem_mb, get_star_index_size_mb())


def get_star_sort_mem_mb(wildcards, attempt=1):
    fastq_mb = 0

    for fastq in get_fastq_paths(wildcards):
        fastq_mb += estimate_fastq_input_mb(fastq)

    # Keep BAM sorting memory tied to input volume, but bounded so STAR
    # jobs remain schedulable. Retries can request more only when needed.
    mem_mb = max(4000, fastq_mb // 4)

    return min(32000, mem_mb * attempt)


@lru_cache(maxsize=1)
def get_star_index_size_mb():
    dir_index = Path(config["index_star"])
    mib = 1024 * 1024

    if not dir_index.exists():
        raise FileNotFoundError(
            f"Cannot determine STAR index size: '{dir_index}' not found."
        )

    bytes_total = sum(
        path.stat().st_size for path in dir_index.iterdir() if path.is_file()
    )

    return (bytes_total + mib - 1) // mib


def get_fastq_paths(wildcards):
    sample = wildcards.sample
    fastqs = get_fastq_files(wildcards=wildcards)
    paths = []

    for path in fastqs.values():
        fastq = Path(path.format(sample=sample))
        if not fastq.exists():
            raise FileNotFoundError(f"FASTQ '{fastq}' not found.")

        paths.append(fastq)

    return paths


def estimate_fastq_input_mb(fastq):
    mib = 1024 * 1024
    size_mb = (fastq.stat().st_size + mib - 1) // mib

    if fastq.suffix == ".gz":
        return size_mb * 4

    return size_mb


def estimate_bam_input_mb(bam):
    mib = 1024 * 1024

    return (bam.stat().st_size + mib - 1) // mib


def resolve_single_input_path(path_or_paths):
    if isinstance(path_or_paths, (str, Path)):
        return Path(path_or_paths)
    if len(path_or_paths) != 1:
        raise ValueError(
            "Expected exactly one input when estimating memory, "
            f"got {len(path_or_paths)}: {path_or_paths}"
        )
    return Path(path_or_paths[0])


def get_pileup_summaries_mem_mb(bam, attempt=1):
    bam_mb = estimate_bam_input_mb(resolve_single_input_path(bam))

    # Start small, still scale with BAM size, and keep it bounded.
    mem_mb = max(2000, bam_mb // 10)

    # Retry with more memory only if a job actually fails.
    return min(8000, mem_mb * attempt)

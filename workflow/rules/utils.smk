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

    root.setLevel(old_level)
    root.handlers = old_handlers


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

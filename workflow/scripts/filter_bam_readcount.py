"""Remove SNVs present in the matched DNA sample to get RNA modifications."""

# /// script
# dependencies = [
#   "polars",
# ]
# ///

# %%
import logging

import polars as pl


# %%
BASES = ["A", "C", "G", "T"]
FIELDS_BASE = {
    "base": str,
    "count": int,
    "avg_mapping_quality": float,
    "avg_basequality": float,
    "avg_se_mapping_quality": float,
    "num_plus_strand": int,
    "num_minus_strand": int,
    "avg_pos_as_fraction": float,
    "avg_num_mismatches_as_fraction": float,
    "avg_sum_mismatch_qualities": float,
    "num_q2_containing_reads": int,
    "avg_distance_to_q2_start_in_q2_reads": float,
    "avg_clipped_length": float,
    "avg_distance_to_effective_3p_end": float,
}


# %%
def configure_logger(console_output=None, log_file=None, log_level="INFO"):
    logger = logging.getLogger()

    log_levels = {
        "CRITICAL": logging.CRITICAL,
        "ERROR": logging.ERROR,
        "WARNING": logging.WARNING,
        "INFO": logging.INFO,
        "DEBUG": logging.DEBUG,
        "NOTSET": logging.NOTSET,
    }

    log_level_constant = log_levels.get(log_level.upper(), logging.INFO)
    logger.setLevel(log_level_constant)

    formatter = logging.Formatter(
        "%(levelname)s [%(asctime)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
    )

    if logger.hasHandlers():
        logger.handlers.clear()

    if console_output:
        ch = logging.StreamHandler()
        ch.setLevel(log_level_constant)
        ch.setFormatter(formatter)
        logger.addHandler(ch)

    if log_file:
        fh = logging.FileHandler(log_file)
        fh.setLevel(log_level_constant)
        fh.setFormatter(formatter)
        logger.addHandler(fh)


# %%
def read_bam_readcount(tsv_path: str, min_coverage: int) -> pl.DataFrame:
    """Read bam-readcount output TSV into a Polars DataFrame.

    Each base/indel field in bam-readcount output contains 14 colon-separated values:
    - base: The base (A, C, G, T, indel, or = for reference skip)
    - count: Number of reads
    - avg_mapping_quality: Mean mapping quality
    - avg_basequality: Mean base quality
    - avg_se_mapping_quality: Mean single ended mapping quality
    - num_plus_strand: Number of reads on the plus/forward strand
    - num_minus_strand: Number of reads on the minus/reverse strand
    - avg_pos_as_fraction: Average position on the read as a fraction
    - avg_num_mismatches_as_fraction: Average number of mismatches per base
    - avg_sum_mismatch_qualities: Average sum of base qualities of mismatches
    - num_q2_containing_reads: Number of reads with q2 runs at 3' end
    - avg_distance_to_q2_start_in_q2_reads: Average distance to q2 run start
    - avg_clipped_length: Average clipped read length
    - avg_distance_to_effective_3p_end: Average distance to 3' end
    """
    dat = []
    with open(tsv_path) as f:
        for line in f:
            fields = line.strip().split("\t")

            chrom = fields[0]
            pos = int(fields[1])
            ref = fields[2]
            depth = int(fields[3])

            if depth < min_coverage:
                continue

            for string in fields[4:]:
                values = string.split(":")
                base_data = {}
                for i, (field_name, field_type) in enumerate(FIELDS_BASE.items()):
                    base_data[field_name] = field_type(values[i])

                vaf = base_data["count"] / depth

                row = [chrom, pos, ref, depth] + list(base_data.values()) + [vaf]
                dat.append(row)

    df = pl.DataFrame(
        dat,
        schema=["chrom", "pos", "ref", "depth"] + list(FIELDS_BASE.keys()) + ["vaf"],
        orient="row",
    ).filter(pl.col("base").is_in(BASES), pl.col("ref") != pl.col("base"))

    return df


# %%
def main():
    configure_logger(console_output=False, log_file=path_log, log_level="INFO")

    df = read_bam_readcount(path_tsv, min_coverage)

    n_positions = df.select("chrom", "pos").n_unique()
    logging.info(
        f"Read {n_positions} positions with coverage >= {min_coverage} from {path_tsv}"
    )

    df_final = (
        df.group_by(["chrom", "pos"])
        .agg(pl.col("count").sum().alias("total_count"))
        .filter(pl.col("total_count") <= max_mutants)
        .with_columns(
            [
                (pl.col("pos") - 1).alias("start"),
                pl.col("pos").alias("end"),
            ]
        )
        .select(["chrom", "start", "end"])
        .sort(["chrom", "start"])
    )

    logging.info(
        f"{len(df_final)} positions passed the max mutants filter (max {max_mutants})"
    )
    logging.info(f"Writing filtered positions to {out_bed}")
    df_final.write_csv(out_bed, separator="\t", include_header=False)


# %%
path_tsv = snakemake.input[0]  # type: ignore # noqa: F821
out_bed = snakemake.output[0]  # type: ignore # noqa: F821
path_log = snakemake.log[0]  # type: ignore # noqa: F821

min_coverage = snakemake.params[0]  # type: ignore # noqa: F821
max_mutants = snakemake.params[1]  # type: ignore # noqa: F821


# %%
if __name__ == "__main__":
    main()


# %%

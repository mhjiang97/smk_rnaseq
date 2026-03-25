rule generate_gtf_pickle:
    input:
        gtf=config["gtf"],
    output:
        pickle=f"{config['gtf']}.pkl",
    log:
        "logs/generate_gtf_pickle.log",
    conda:
        "../../envs/python.yaml"
    run:
        import pickle

        import pyranges as pr

        prs = pr.read_gtf(input.gtf)

        with open(output.pickle, "wb") as f:
            pickle.dump(prs, f)


rule assign_strand:
    input:
        vcf="{caller}/{sample}/{sample}.snvs.vcf",
        pickle=f"{config['gtf']}.pkl",
        log="salmon/{sample}/logs/salmon_quant.log",
        txt="rseqc/{sample}/infer_experiment.txt",
    output:
        tsv="{caller}/{sample}/{sample}.snv_strandedness.tsv",
    log:
        "logs/{sample}/assign_strand.{caller}.log",
    conda:
        "../../envs/python.yaml"
    params:
        rate_bias=config["rate_bias"],
        rate_conflict=config["rate_conflict"],
        extend_transcript=config["extend_transcript"],
        strandedness=determine_strandedness,
    script:
        "../../scripts/assign_strand.py"


rule write_strandedness_table:
    input:
        tsv=expand(
            "{caller}/{sample}/{sample}.snv_strandedness.tsv",
            caller=CALLERS,
            sample=SAMPLES,
        ),
    output:
        csv=PATH_OUTPUT_SAMPLE_TABLE,
    run:
        DF_SAMPLE_COPY.to_csv(output.csv, index=False)

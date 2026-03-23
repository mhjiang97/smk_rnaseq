rule generate_gtf_pickle:
    conda:
        "../../envs/python.yaml"
    input:
        gtf=config["gtf"],
    output:
        pickle=f"{config['gtf']}.pkl",
    log:
        "logs/generate_gtf_pickle.log",
    run:
        import pickle

        import pyranges as pr

        prs = pr.read_gtf(input.gtf)

        with open(output.pickle, "wb") as f:
            pickle.dump(prs, f)


rule assign_strand:
    conda:
        "../../envs/python.yaml"
    input:
        vcf="{caller}/{sample}/{sample}.snvs.vcf",
        pickle=f"{config['gtf']}.pkl",
        log="salmon/{sample}/logs/salmon_quant.log",
        txt="rseqc/{sample}/infer_experiment.txt",
    output:
        tsv="{caller}/{sample}/{sample}.snv_strandedness.tsv",
    params:
        rate_bias=config["rate_bias"],
        rate_conflict=config["rate_conflict"],
        extend_transcript=config["extend_transcript"],
        strandedness=determine_strandedness,
    log:
        "logs/{sample}/assign_strand.{caller}.log",
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

rule bamCoverage_unique_mappings:
    input:
        bam = "filtered_bam/{sample}.filtered.bam",
        bai = "filtered_bam/{sample}.filtered.bam.bai"
    output:
        bw_fwd = "bamCoverage/{sample}.uniqueMappings.fwd.bw",
        bw_rev = "bamCoverage/{sample}.uniqueMappings.rev.bw",
    conda:
        CONDA_SHARED_ENV
    params:
        bwBinSize = bwBinSize
    log:
        out="bamCoverage/logs/bamCoverage_uniqueMappings.{sample}.out",
        err="bamCoverage/logs/bamCoverage_uniqueMappings.{sample}.err"
    benchmark:
        "bamCoverage/.benchmark/bamCoverage_uniqueMappings.{sample}.benchmark"
    threads: 8
    shell: bamcov_unique_cmd


rule bamCoverage_RPKM:
    input:
        bam = "filtered_bam/{sample}.filtered.bam",
        bai = "filtered_bam/{sample}.filtered.bam.bai"
    output:
        "bamCoverage/{sample}.RPKM.bw"
    conda:
        CONDA_SHARED_ENV
    params:
        bwBinSize = bwBinSize
    log:
        out="bamCoverage/logs/bamCoverage_RPKM.{sample}.out",
        err="bamCoverage/logs/bamCoverage_RPKM.{sample}.err"
    benchmark:
        "bamCoverage/.benchmark/bamCoverage_RPKM.{sample}.benchmark"
    threads: 8
    shell: bamcov_RPKM_cmd


rule bamCoverage_raw:
    input:
        bam = "filtered_bam/{sample}.filtered.bam",
        bai = "filtered_bam/{sample}.filtered.bam.bai"
    output:
        "bamCoverage/{sample}.coverage.bw"
    conda:
        CONDA_SHARED_ENV
    params:
        bwBinSize = bwBinSize
    log:
        out="bamCoverage/logs/bamCoverage_coverage.{sample}.out",
        err="bamCoverage/logs/bamCoverage_coverage.{sample}.err"
    benchmark:
        "bamCoverage/.benchmark/bamCoverage_coverage.{sample}.benchmark"
    threads: 8
    shell: bamcov_raw_cmd


rule plotEnrichment:
    input:
        bam = expand("filtered_bam/{sample}.filtered.bam", sample=samples),
        bai = expand("filtered_bam/{sample}.filtered.bam.bai", sample=samples),
        gtf = "Annotation/genes.filtered.gtf"
    output:
        "deepTools_qc/plotEnrichment/plotEnrichment.tsv",
    conda:
        CONDA_SHARED_ENV
    params:
        labels = " ".join(samples),
        plotcmd = "" if plotFormat == 'None' else
            "--plotFile " + "deepTools_qc/plotEnrichment/plotEnrichment." + plotFormat
    log:
        out="deepTools_qc/logs/plotEnrichment.out",
        err="deepTools_qc/logs/plotEnrichment.err"
    benchmark:
        "deepTools_qc/.benchmark/plotEnrichment.benchmark"
    threads: 24
    shell: plotEnrich_cmd


rule multiBigwigSummary_bed:
    input:
        bw = expand("bamCoverage/{sample}.RPKM.bw", sample=samples),
        bed = "Annotation/genes.filtered.bed",
    output:
        "deepTools_qc/multiBigwigSummary/coverage.bed.npz"
    conda:
        CONDA_SHARED_ENV
    params:
        labels = " ".join(samples)
    log:
        out="deepTools_qc/logs/multiBigwigSummary.out",
        err="deepTools_qc/logs/multiBigwigSummary.err"
    benchmark:
        "deepTools_qc/.benchmark/multiBigwigSummary.bed.benchmark"
    threads: 8
    shell: multiBWsum_bed_cmd


# Pearson: heatmap, scatterplot and correlation matrix
rule plotCorr_bed_pearson:
    input:
        "deepTools_qc/multiBigwigSummary/coverage.bed.npz"
    output:
        "deepTools_qc/plotCorrelation/correlation.pearson.bed_coverage.tsv"
    conda:
        CONDA_SHARED_ENV
    log:
        out="deepTools_qc/logs/plotCorrelation_pearson.out",
        err="deepTools_qc/logs/plotCorrelation_pearson.err"
    benchmark:
        "deepTools_qc/.benchmark/plotCorrelation_pearson.benchmark"
    params: 
        plotcmd = "" if plotFormat == 'None' else
            "--plotFile " + "deepTools_qc/plotCorrelation/correlation.pearson.bed_coverage.heatmap." + plotFormat,
        title='genes'
    shell: plotCorr_cmd


# Spearman: heatmap, scatterplot and correlation matrix
rule plotCorr_bed_spearman:
    input:
        "deepTools_qc/multiBigwigSummary/coverage.bed.npz"
    output:
        "deepTools_qc/plotCorrelation/correlation.spearman.bed_coverage.tsv"
    conda:
        CONDA_SHARED_ENV
    log:
        out="deepTools_qc/logs/plotCorrelation_spearman.out",
        err="deepTools_qc/logs/plotCorrelation_spearman.err"
    benchmark:
        "deepTools_qc/.benchmark/plotCorrelation_spearman.benchmark"
    params:        
        plotcmd = "" if plotFormat == 'None' else
            "--plotFile " + "deepTools_qc/plotCorrelation/correlation.spearman.bed_coverage.heatmap." + plotFormat,
        title='genes'
    shell: plotCorrSP_cmd


### deepTools plotPCA ##########################################################
rule plotPCA:
    input:
        "deepTools_qc/multiBigwigSummary/coverage.bed.npz"
    output:
        "deepTools_qc/plotPCA/PCA.bed_coverage.tsv"
    conda:
        CONDA_SHARED_ENV
    log:
        out="deepTools_qc/logs/plotPCA.out",
        err="deepTools_qc/logs/plotPCA.err",
    benchmark:
        "deepTools_qc/.benchmark/plotPCA.benchmark"
    params: 
        plotcmd = "" if plotFormat == 'None' else
                "--plotFile " + "deepTools_qc/plotPCA/PCA.bed_coverage." + plotFormat,
        title='genes'
    shell: plotPCA_cmd


########deepTools estimateReadFiltering#########################
rule estimateReadFiltering:
    input:
        bam = "filtered_bam/{sample}.filtered.bam",
        bai = "filtered_bam/{sample}.filtered.bam.bai",
    output:
        "deepTools_qc/estimateReadFiltering/{sample}_filtering_estimation.txt"
    log:
        out = "deepTools_qc/logs/estimateReadFiltering.{sample}.out",
        err = "deepTools_qc/logs/estimateReadFiltering.{sample}.err"
    conda:
        CONDA_SHARED_ENV
    shell: estimateReadFiltering_cmd


#######InsertSizeMetrics###############
rule bamPE_fragment_size:
    input:
        bams = expand("filtered_bam/{sample}.filtered.bam", sample=samples),
        bais = expand("filtered_bam/{sample}.filtered.bam.bai", sample=samples)
    output:
        "deepTools_qc/bamPEFragmentSize/fragmentSize.metric.tsv"
    params:
        plotcmd = "" if plotFormat == 'None' else
                "-o " + "deepTools_qc/bamPEFragmentSize/fragmentSizes." + plotFormat,
    conda:
        CONDA_SHARED_ENV
    log:
        out="deepTools_qc/logs/bamPEFragmentSize.out",
        err="deepTools_qc/logs/bamPEFragmentSize.err"
    threads: 24
    shell: bamPEFragmentSize_cmd

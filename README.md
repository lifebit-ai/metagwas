# GWAS meta-analysis pipeline

## 1 - Quick Start

```
nextflow run main.nf --studies https://lifebit-featured-datasets.s3-eu-west-1.amazonaws.com/pipelines/metagwas/list-summary-statistics.csv
```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.

## 2 - Important assumptions

This pipeline currently assumes all the studies are formatted as SAIGE output files.


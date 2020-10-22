# GWAS meta-analysis pipeline

[![GitHub Actions CI Status](https://github.com/lifebit-ai/metagwas/workflows/nf-core%20CI/badge.svg)](https://github.com/lifebit-ai/metagwas/actions)
[![GitHub Actions Linting Status](https://github.com/lifebit-ai/metagwas/workflows/nf-core%20linting/badge.svg)](https://github.com/lifebit-ai/metagwas/actions)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A519.10.0-brightgreen.svg)](https://www.nextflow.io/)

## 1 - Introduction

This pipeline performs GWAS meta-analysis using `METAL`.

The pipeline was built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker containers making installation trivial and results highly reproducible.

## 2 - Important assumptions

This pipeline currently assumes the following:
- You are analysing 2 studies only
- The studies are formatted as SAIGE output files

## 3 - Quick Start

    ```
    nextflow run main.nf \
    --study_1 testdata/saige_data/saige_results_top_n-1.csv \
    --study_2 testdata/saige_data/saige_results_top_n-2.csv
    ```

See [usage docs](docs/usage.md) for all of the available options when running the pipeline.

## 4 - Documentation

The lifebit-ai/metagwas pipeline comes with documentation about the pipeline which you can read at [https://lifebit-ai/metagwas/docs](https://lifebit-ai/metagwas/docs) or find in the [`docs/` directory](docs).



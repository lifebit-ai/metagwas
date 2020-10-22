# Usage documentation

## 1 - Introduction

This document provides a detailed guide on how to run the `lifebit-ai/metagwas` pipeline. This pipeline uses to the `METAL` package to perform meta-analysis of GWAS studies.

## 2 - Usage

This pipeline currently assumes the following:
- You are analysing 2 studies only
- The studies are formatted as SAIGE output files

## 3 - Basic example

The typical command for running the pipeline is as follows:

```
nextflow run main.nf \
--study_1 testdata/saige_input/saige_results_top_n-1.csv \
--study_2 testdata/saige_input/saige_results_top_n-2.csv
```

This will launch the pipeline with the `docker` configuration profile.

## 4 - Essential parameters

## 5 - Other parameters



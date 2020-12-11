# Usage documentation

## 1 - Introduction

This document provides a detailed guide on how to run the `lifebit-ai/metagwas` pipeline. This pipeline uses to the `METAL` package to perform meta-analysis of GWAS studies.

## 2 - Usage

This pipeline currently assumes all the studies are formatted as SAIGE output files.

## 3 - Basic example

The typical command for running the pipeline is as follows:

```
nextflow run main.nf --studies testdata/list-summary-statistics.csv
```

## 4 - Essential parameters

**--studies**

list of studies (GWAS summary statistics) to be analyzed (should be a .csv file with a header and the name of each file, one per line). An example `.csv` can be found in `testdata/list-summary-statistics.csv`.





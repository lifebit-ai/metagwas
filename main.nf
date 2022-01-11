#!/usr/bin/env nextflow
/*
========================================================================================
                         lifebit-ai/metagwas
========================================================================================
 lifebit-ai/metagwas Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/lifebit-ai/metagwas
----------------------------------------------------------------------------------------
*/



/*---------------------------------------
  Define and show help message if needed
-----------------------------------------*/

// Define help message

def helpMessage() {
    log.info"""

    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run main.nf --studies testdata/list-summary-statistics.csv

    Mandatory arguments:
    --studies           list of studies (GWAS summary statistics) to be analyzed 
                        (should be a .csv file with a header and the name of each file, one per line)
  
    """.stripIndent()
}

// Show help message

if (params.help) {
    helpMessage()
    exit 0
}



/*---------------------------------------------------
  Define and show header with all params information 
-----------------------------------------------------*/

// Header log info

def summary = [:]

summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName

summary['studies']          = params.studies

log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"



/*----------------------------------
  Setting up list of input datasets  
------------------------------------*/
if (params.metal) {
  Channel
    .fromPath(params.studies, checkIfExists: true)
    .ifEmpty { exit 1, "List of studies to analyze not found: ${params.studies}" }
    .splitCsv(header:true)
    .map{ row -> file(row.study) }
    .flatten()
    .set { all_input_studies_ch }

}


/*-----------------------------
  Setting up channels for MAMA
-------------------------------*/
if (params.mama) {
  Channel
    .fromPath(params.ancestry_sample_file, checkIfExists: true)
    .ifEmpty { exit 1, "Sample file with ancestries not found: ${params.ancestry_sample_file}" }
    .set { ch_ancestry_sample_file }

  Channel
    .fromPath(params.snp_ancestry_file, checkIfExists: true)
    .ifEmpty { exit 1, "SNP file with ancestries not found: ${params.snp_ancestry_file}" }
    .set { ch_snp_ancestry_file }

  Channel
    .fromFilePairs(params.merged_ref_panel, size:3, flat : true)
    .ifEmpty { exit 1, "Ref panel plink files not found: ${params.merged_ref_panel}" }
    .set { ch_merged_ref_panel }

    Channel
    .fromPath(params.ss_1)
    .ifEmpty { exit 1, "Ref panel plink files not found: ${params.merged_ref_panel}" }
    .set { ch_ss_1 }
    Channel
    .fromPath(params.ss_2)
    .ifEmpty { exit 1, "Ref panel plink files not found: ${params.merged_ref_panel}" }
    .set { ch_ss_2 }

}


/*-----------------------------
  Setting up extra METAL flags
-------------------------------*/

// Initialise variable to store optional parameters
extra_flags = ""

// 1 - METAL options for describing input files

if ( params.flip ) { extra_flags += "FLIP \n" }

// 2 - METAL options for filtering input files

if ( params.addfilter ) { extra_flags += "ADDFILTER ${params.addfilter}\n" }
if ( params.removefilters ) { extra_flags += "REMOVEFILTERS  \n" }

// 3 - METAL options for sample size weighted meta-analysis

if ( params.weightlabel ) { extra_flags += "WEIGHTLABEL ${params.weightlabel}\n" }
if ( params.defaultweight ) { extra_flags += "DEFAULTWEIGHT ${params.defaultweight}\n" }
if ( params.minweight ) { extra_flags += "MINWEIGHT ${params.minweight}\n" }

// 4 - METAL options for inverse variance weighted meta-analysis

if ( params.stderrlabel ) { extra_flags += "STDERRLABEL ${params.stderrlabel}\n" }
if ( params.scheme ) { extra_flags += "SCHEME ${params.scheme}\n" }

// 5 - METAL options to enable tracking of allele frequencies

if ( params.averagefreq ) { extra_flags += "AVERAGEFREQ ${params.averagefreq}\n" }
if ( params.minmaxfreq ) { extra_flags += "MINMAXFREQ ${params.minmaxfreq}\n" }
if ( params.freqlabel ) { extra_flags += "FREQLABEL ${params.freqlabel}\n" }

// 6 - METAL options to enable tracking of user defined variables

if ( params.customvariable ) { extra_flags += "CUSTOMVARIABLE ${params.customvariable}\n" }
if ( params.label ) { extra_flags += "LABEL ${params.label}\n" }

// 7 - METAL options to enable explicit strand information

if ( params.usestrand ) { extra_flags += "USESTRAND ${params.usestrand}\n" }
if ( params.strandlabel ) { extra_flags += "STRANDLABEL ${params.strandlabel}\n"  }

// 8 - METAL options for automatic genomic control correction of input statistics

if ( params.genomiccontrol ) { extra_flags += "GENOMICCONTROL ${params.genomiccontrol}\n" }

// 9 - METAL options for general analysis control  

if ( params.outfile ) { extra_flags += "OUTFILE ${params.outfile}\n"}
if ( params.maxwarnings ) { extra_flags += "MAXWARNINGS ${params.maxwarnings}\n" }
if ( params.verbose ) { extra_flags += "VERBOSE ${params.verbose}\n"}
if ( params.logpvalue ) { extra_flags += "LOGPVALUE ${params.logpvalue}\n" }

// 10 - METAL options for general run control not available (pipeline is not currently developed to handle this)



/*------------------------------
  Running METAL (meta-analysis)
--------------------------------*/

// NB: this process must be "padded to the wall" to allow for extra flags to be properly inserted

if (params.metal) {

process run_metal {
publishDir "${params.outdir}", mode: "copy"

input:
file(study) from all_input_studies_ch.collect()

output:
file("METAANALYSIS*") into results_ch

shell:
'''
# 1 - Dynamically obtain files to process
touch process_commands.txt

for csv in $(ls *.csv)
do 
echo "PROCESS $csv" >> process_commands.txt
done

process_commands=$(cat process_commands.txt)

# 2 - Make METAL script 

cat > metal_command.txt <<EOF
MARKER SNPID
ALLELE Allele1 Allele2
EFFECT BETA
PVALUE p.value 
SEPARATOR COMMA
!{extra_flags}
$process_commands


ANALYZE 
QUIT
EOF

# 3 - Run METAL

metal metal_command.txt
'''
}
}


if (params.mama) {

  process mama_calculate_ldscores {
    label 'mama'
    input:
    file(ancestry_sample_file) from ch_ancestry_sample_file
    file(snp_ancestry_file) from ch_snp_ancestry_file
    set val(plink_prefix), file(bed), file(bim), file(fam) from ch_merged_ref_panel
    output:
    file("*.l2.ldscore.gz") into ch_mama_ldscores
    script:
    """
    mama_ldscores.py  --ances-path ${ancestry_sample_file} \
                            --snp-ances ${snp_ancestry_file} \
                            --ld-wind-cm 1 \
                            --stream-stdout \
                            --bfile-merged-path ${plink_prefix} \
                            --out "ld_scores"
    """
  }
  process run_mama {
    label 'mama'
    input:
    file(ss_1) from ch_ss_1
    file(ss_2) from ch_ss_2
    file(ld_scores) from ch_mama_ldscores

    output:
    file("*res") into ch_mama_results

    script:
    """
    mama.py --sumstats "${ss_1},${params.ss_1_ancestry},${params.ss_1_trait}" "${ss_2},${params.ss_2_ancestry},${params.ss_2_trait}" \
                   --ld-scores ${ld_scores} \
                   --out "./${params.mama_output_prefix}" \
                   --add-a1-col-match "EA" \
                   --add-a2-col-match "OA" \
                   --out-harmonized
    """

  }
}
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

    nextflow run main.nf --study_1 testdata/saige_data/saige_results_top_n-1.csv --study_2 testdata/saige_data/saige_results_top_n-2.csv

    Mandatory arguments:
      --study_1                Path to input SAIGE summary statistics (must be surrounded with quotes)
      --study_2                Path to input SAIGE summary statistics (must be surrounded with quotes)

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

if (workflow.revision) summary['Pipeline Release'] = workflow.revision

summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if (workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"

summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName

summary['study_1']          = params.study_1
summary['study_2']          = params.study_2

log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"



/*---------------------------
  Setting up input datasets  
-----------------------------*/

if (!params.study_1 && !params.study_2) {
  exit 1, "You have provided not provided 2 studies to run a METAL analysis with. \
  \nPlease specify 2 studies (SAIGE summary statistics) using --study_1 and --study_2."
}

Channel
  .fromPath(params.study_1, checkIfExists: true)
  .ifEmpty { exit 1, "Study 1 file not found: ${params.study_1}" }
  .set { study1_ch }

Channel
  .fromPath(params.study_2, checkIfExists: true)
  .ifEmpty { exit 1, "Study 2 file not found: ${params.study_2}" }
  .set { study2_ch }



/*-----------------------------
  Setting up extra METAL flags
-------------------------------*/

// Initialise variable to store optional parameters
extra_flags = ""

// 1 - METAL options for describing input files

if ( params.flip ) { extra_flags += " FLIP \n" }

// 2 - METAL options for filtering input files

if ( params.addfilter ) { extra_flags += " ADDFILTER ${params.addfilter}\n" }
if ( params.removefilters ) { extra_flags += " REMOVEFILTERS  \n" }

// 3 - METAL options for sample size weighted meta-analysis

if ( params.weightlabel ) { extra_flags += " WEIGHTLABEL ${params.weightlabel}\n" }
if ( params.defaultweight ) { extra_flags += " DEFAULTWEIGHT ${params.defaultweight}\n" }
if ( params.minweight ) { extra_flags += " MINWEIGHT ${params.minweight}\n" }

// 4 - METAL options for inverse variance weighted meta-analysis

if ( params.stderrlabel ) { extra_flags += " STDERRLABEL ${params.stderrlabel}\n" }
if ( params.scheme ) { extra_flags += " SCHEME ${params.scheme}\n" }

// 5 - METAL options to enable tracking of allele frequencies

if ( params.averagefreq ) { extra_flags += " AVERAGEFREQ ${params.averagefreq}\n" }
if ( params.minmaxfreq ) { extra_flags += " MINMAXFREQ ${params.minmaxfreq}\n" }
if ( params.freqlabel ) { extra_flags += " FREQLABEL ${params.freqlabel}\n" }

// 6 - METAL options to enable tracking of user defined variables

if ( params.customvariable ) { extra_flags += " CUSTOMVARIABLE ${params.customvariable}\n" }
if ( params.label ) { extra_flags += " LABEL ${params.label}\n" }

// 7 - METAL options to enable explicit strand information

if ( params.usestrand ) { extra_flags += " USESTRAND ${params.usestrand}\n" }
if ( params.strandlabel ) { extra_flags += " STRANDLABEL ${params.strandlabel}\n"  }

// 8 - METAL options for automatic genomic control correction of input statistics

if ( params.genomiccontrol ) { extra_flags += " GENOMICCONTROL ${params.genomiccontrol}\n" }

// 9 - METAL options for general analysis control  

if ( params.outfile ) { extra_flags += "OUTFILE ${params.outfile}\n"}
if ( params.maxwarnings ) { extra_flags += " MAXWARNINGS ${params.maxwarnings}\n" }
if ( params.verbose ) { extra_flags += "VERBOSE ${params.verbose}\n"}
if ( params.logpvalue ) { extra_flags += " LOGPVALUE ${params.logpvalue}\n" }

// 10 - METAL options for general run controlnot available (pipeline is not currently developed to handle this)



/*------------------------------
  Running METAL (meta-analysis)
--------------------------------*/

// NB: this process must be "padded to the wall" to allow for extra flags to be properly inserted

process run_metal {
publishDir "${params.outdir}", mode: "copy"

input:
file study_1 from study1_ch
file study_2 from study2_ch

output:
file("METAANALYSIS*") into results_ch

shell:
'''
# 1 - Make a METAL script 

cat > metal_command.txt <<EOF
# === DESCRIBE AND PROCESS THE FIRST SAIGE INPUT FILE ===
MARKER SNPID
ALLELE Allele1 Allele2
EFFECT BETA
PVALUE p.value 
SEPARATOR COMMA
PROCESS !{study_1}
!{extra_flags}

# === THE SECOND INPUT FILE HAS THE SAME FORMAT AND CAN BE PROCESSED IMMEDIATELY ===
PROCESS !{study_2}

ANALYZE 
QUIT
EOF

# - Run METAL
metal metal_command.txt
'''

}



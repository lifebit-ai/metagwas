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

    nextflow run lifebit-ai/metagwas --study_1 '*_R{1,2}.fastq.gz' --study_2 -profile docker

    Mandatory arguments:
      --study_1 [file]                Path to input SAIGE summary statistics (must be surrounded with quotes)
      -profile [str]                  Configuration profile to use. Can use multiple (comma separated)
                                      Available: docker

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

summary['study_1']          = params.study_1
summary['study_2']          = params.study_2

summary['Max Resources']    = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if (workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"

summary['Output dir']       = params.outdir
summary['Launch dir']       = workflow.launchDir
summary['Working dir']      = workflow.workDir
summary['Script dir']       = workflow.projectDir
summary['User']             = workflow.userName

if (workflow.profile.contains('awsbatch')) {
    summary['AWS Region']   = params.awsregion
    summary['AWS Queue']    = params.awsqueue
    summary['AWS CLI']      = params.awscli
}

summary['Config Profile'] = workflow.profile
if (params.config_profile_description) summary['Config Profile Description'] = params.config_profile_description
if (params.config_profile_contact)     summary['Config Profile Contact']     = params.config_profile_contact
if (params.config_profile_url)         summary['Config Profile URL']         = params.config_profile_url
summary['Config Files'] = workflow.configFiles.join(', ')

if (params.email || params.email_on_fail) {
    summary['E-mail Address']    = params.email
    summary['E-mail on failure'] = params.email_on_fail
    summary['MultiQC maxsize']   = params.max_multiqc_email_size
}
log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"



/*------------------------------------------------
  Check the hostnames against configured profiles
--------------------------------------------------*/

// Define checkHostname function

def checkHostname() {
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}

// Check hostname

checkHostname()

Channel.from(summary.collect{ [it.key, it.value] })
    .map { k,v -> "<dt>$k</dt><dd><samp>${v ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>" }
    .reduce { a, b -> return [a, b].join("\n            ") }
    .map { x -> """
    id: 'metagwas-summary'
    description: " - this information is collected when the pipeline is started."
    section_name: 'lifebit-ai/metagwas Workflow Summary'
    section_href: 'https://github.com/lifebit-ai/metagwas'
    plot_type: 'html'
    data: |
        <dl class=\"dl-horizontal\">
            $x
        </dl>
    """.stripIndent() }
    .set { ch_workflow_summary }



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

if ( params.FLIP ) { extra_flags += " FLIP " }

// 2 - METAL options for filtering input files

if ( params.ADDFILTER ) { extra_flags += " ADDFILTER ${params.ADDFILTER}" }
if ( params.ADDFILTER ) { extra_flags += " REMOVEFILTERS " }

// 3 - METAL options for sample size weighted meta-analysis

if ( params.WEIGHTLABEL ) { extra_flags += " WEIGHTLABEL ${params.WEIGHTLABEL}" }
if ( params.DEFAULTWEIGHT ) { extra_flags += " DEFAULTWEIGHT ${params.DEFAULTWEIGHT}" }
if ( params.MINWEIGHT ) { extra_flags += " MINWEIGHT ${params.MINWEIGHT}" }

// 4 - METAL options for inverse variance weighted meta-analysis

if ( params.STDERRLABEL ) { extra_flags += " STDERRLABEL ${params.STDERRLABEL}" }
if ( params.SCHEME ) { extra_flags += " SCHEME ${params.SCHEME}" }

// 5 - METAL options to enable tracking of allele frequencies

if ( params.AVERAGEFREQ ) { extra_flags += " AVERAGEFREQ ${params.AVERAGEFREQ}" }
if ( params.MINMAXFREQ ) { extra_flags += " MINMAXFREQ ${params.MINMAXFREQ}" }
if ( params.FREQLABEL ) { extra_flags += " FREQLABEL ${params.FREQLABEL}" }

// 6 - METAL options to enable tracking of user defined variables

if ( params.CUSTOMVARIABLE ) { extra_flags += " CUSTOMVARIABLE ${params.CUSTOMVARIABLE}" }
if ( params.LABEL ) { extra_flags += " LABEL ${params.LABEL}" }

 // 7 - METAL options to enable explicit strand information

 if ( params.USESTRAND ) { extra_flags += " USESTRAND ${params.USESTRAND}" }
 if ( params.STRANDLABEL ) { extra_flags += " STRANDLABEL ${params.STRANDLABEL}"  }

 // 8 - METAL options for automatic genomic control correction of input statistics

 if ( params.GENOMICCONTROL ) { extra_flags += " GENOMICCONTROL ${params.GENOMICCONTROL}" }

 // 9 - METAL options for general analysis control  

if ( params.OUTFILE ) { extra_flags += " OUTFILE ${params.OUTFILE}\n" }
if ( params.MAXWARNINGS ) { extra_flags += " MAXWARNINGS ${params.MAXWARNINGS}" }
if ( params.VERBOSE ) { extra_flags += " VERBOSE ${params.VERBOSE}"  }
if ( params.LOGPVALUE ) { extra_flags += " LOGPVALUE ${params.LOGPVALUE}" }

 // 10 - METAL options for general run controlnot available (pipeline is not currently developed to handle this)



/*-----------------------------
  Running METAL (meta-analysis)
-------------------------------*/

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



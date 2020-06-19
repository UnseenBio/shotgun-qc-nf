#!/usr/bin/env nextflow

nextflow.preview.dsl=2

/* ############################################################################
 * Default parameter values.
 * ############################################################################
 */

params.sequences = 'sequences'
params.outdir = 'results'

/* ############################################################################
 * Define workflow processes.
 * ############################################################################
 */

process fastp {
  publishDir "${params.outdir}", mode:'link'

  input:
  tuple val(sample), path(first_fastq), path(second_fastq)

  output:
  path "${sample}_fastp.json", emit: data
  path "${sample}_fastp.html", emit: report

  """
  fastp --in1 ${first_fastq} \
    --in2 ${second_fastq} \
    --json ${sample}_fastp.json \
    --html ${sample}_fastp.html \
    --report_title '${sample} fastp Report'
  """
}

process fastqc {
  publishDir "${params.outdir}", mode:'link'

  input:
  path fastq

  output:
  path "${fastq.getSimpleName()}_fastqc.zip", emit: data
  path "${fastq.getSimpleName()}_fastqc.html", emit: report

  """
  fastqc ${fastq}
  """
}

process multiqc {
  publishDir "${params.outdir}", mode:'link'

  input:
  path '*'

  output:
  path 'multiqc_data', emit: data
  path 'multiqc_report.html', emit: report

  """
  multiqc .
  """
}

/* ############################################################################
 * Define named workflows to be included elsewhere.
 * ############################################################################
 */

 workflow qc {
  take:
  fastq_triples
  fastq_singles

  main:
  fastp(fastq_triples)
  fastqc(fastq_singles)
  multiqc(fastp.out.data.mix(fastp.out.report, fastqc.out.data, fastqc.out.report).collect())

  emit:
  multiqc.out.report
 }

/* ############################################################################
 * Define an implicit workflow that only runs when this is the main nextflow
 * pipeline called.
 * ############################################################################
 */

workflow {
  log.info """
************************************************************

Shotgun Sequencing Quality Control
==================================
FASTQ Path: ${params.sequences}
Results Path: ${params.outdir}

************************************************************

"""

  fastq_triples = Channel.fromFilePairs("${params.sequences}/*_{1,2}.fastq.gz",
    checkIfExists: true,
    flat: true
  )

  fastq_singles = Channel.fromPath("${params.sequences}/*.fastq.gz")

  qc(fastq_triples, fastq_singles)
}

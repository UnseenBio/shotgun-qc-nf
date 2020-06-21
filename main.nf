#!/usr/bin/env nextflow

nextflow.preview.dsl=2

include qc from './qc'

/* ############################################################################
 * Default parameter values.
 * ############################################################################
 */

params.sequences = 'sequences'
params.outdir = 'results'

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

  fastq_triples = Channel.fromFilePairs("${params.sequences}/**{1,2}.fastq.gz",
    checkIfExists: true,
    flat: true
  )

  fastq_singles = Channel.fromPath("${params.sequences}/**.fastq.gz")

  qc(fastq_triples, fastq_singles)
}

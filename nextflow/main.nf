#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process HELLO_WORLD {
  tag "hello-world"
  publishDir params.outdir, mode: 'copy'

  output:
  path 'output.txt'

  script:
  """
  echo "Hello World from TES, Nextflow" > output.txt
  """
}

workflow {
  HELLO_WORLD()
}

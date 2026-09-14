cwlVersion: v1.0
class: CommandLineTool
baseCommand: ["sh", "-c"]
hints:
  DockerRequirement:
    dockerPull: ubuntu:22.04
inputs:
  message:
    type: string
    inputBinding:
      position: 1
      prefix: "-c"
      separate: false
arguments:
  - valueFrom: |
      echo $(inputs.message) > /tmp/output.txt && cp /tmp/output.txt $(runtime.outdir)/output.txt
outputs:
  output:
    type: File
    outputBinding:
      glob: output.txt

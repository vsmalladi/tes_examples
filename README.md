# TES Examples

This repository contains small, practical examples showing how to run tasks on
GA4GH TES (Task Execution Service) using different workflow engines and clients.

Use these examples to:

- submit and run a basic hello-world style task
- compare TES integration patterns across tools
- copy working configs as a starting point for your own setup

## Examples

- [curl](./curl): direct TES API calls with `curl`.
- [py-tes](./py-tes): Python client example using `py-tes`.
- [nextflow](./nextflow): Nextflow pipeline execution on TES.
- [snakemake](./snakemake): Snakemake workflow execution on TES.
- [sprocket](./sprocket): Sprocket workflow execution on TES.
- [toil](./toil): Toil workflow execution on TES.
- [crankshaft](./crankshaft): Crankshaft-based TES example.

## Notes

- Most examples require a reachable TES endpoint and credentials.
- Some examples also require cloud storage credentials for staging files.
- Check each subdirectory README for setup and run commands.

## License

MIT. See [LICENSE](./LICENSE).

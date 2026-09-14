# Nextflow + TES Demonstration

Demonstration of using Nextflow with a TES backend to run a minimal hello-world workflow.

License: this example is licensed under MIT. See [../LICENSE](../LICENSE).

## Files

- `main.nf`: Minimal Nextflow pipeline that writes `output.txt`.
- `tes.config`: TES executor and Azure storage configuration.

## Requirements

- Nextflow installed (`nextflow -version`)
- Java runtime compatible with your Nextflow version
- Reachable TES endpoint
- Valid TES basic auth credentials
- Azure Blob storage account + SAS token for staging

## Configuration

Set these environment variables before running:

```bash
export TES_ENDPOINT='http://localhost:8000/ga4gh/tes'
export TES_USERNAME='<your-tes-username>'
export TES_PASSWORD='<your-tes-password>'

export AZURE_ACCOUNT_NAME='<your-storage-account-name>'
export AZURE_STORAGE_SAS_TOKEN='<your-sas-token>'
```

`tes.config` reads those variables and configures:

- `process.executor = 'tes'`
- TES endpoint and basic auth
- Azure storage account/SAS token used by Nextflow staging

## Run Hello World

```bash
nextflow run main.nf \
  -c tes.config \
  -work-dir "az://work" \
  --outdir "az://nextflow/hello-world"
```

Expected behavior:

- One TES task is submitted by Nextflow
- Task writes `output.txt`
- Output is published under `az://nextflow/hello-world`

## Troubleshooting

- Authentication failures:
  - Verify `TES_USERNAME` and `TES_PASSWORD`.
- TES connection issues:
  - Verify `TES_ENDPOINT` and server reachability.
- Azure staging issues:
  - Verify `AZURE_ACCOUNT_NAME` and `AZURE_STORAGE_SAS_TOKEN`.
  - Ensure SAS token permissions include read/write/list as needed.

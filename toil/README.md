# TES Toil CWL Hello World

License: this example is licensed under MIT. See [../LICENSE](../LICENSE).

This folder contains a minimal Toil CWL example that submits a Hello World
task to a TES endpoint, using local filesystem storage for the Toil job
store and workflow output.

## File overview

- example.cwl: Minimal CommandLineTool that writes `output.txt`.
- example-job.yaml: Job input (`message`) for example.cwl.
- run-tes.sh: Loads .env / .tes_instances, then runs `toil-cwl-runner`
  against TES using the `tes` batch system.
- .env: Stores TES credentials and the output storage path used by the script.
- .tes_instances: Stores TES base URL entries in description,url format.

## What run-tes.sh does

1. Loads environment variables from .env if present.
2. Validates TES_SERVER_USER, TES_SERVER_PASSWORD, and TES_OUTPUT_STORAGE_PATH.
3. Reads the TES base URL from the first line of .tes_instances and
   auto-detects the correct `/ga4gh/tes` mount point.
4. Derives a local output/job-store path from TES_OUTPUT_STORAGE_PATH.
5. Runs `toil-cwl-runner --batchSystem tes ...` against the TES endpoint.

## Prerequisites

- bash, curl
- Python **3.12** (Toil 7 is incompatible with Python 3.13 for CWL runs)
- Toil with the TES batch system, installed in `.venv`:
  ```bash
  python3.12 -m venv .venv
  source .venv/bin/activate
  pip install "toil[cwl]"
  ```
- Reachable TES endpoint
- Valid TES basic auth credentials

## Required configuration

Create .env in this folder:

```
TES_SERVER_USER=<username>
TES_SERVER_PASSWORD=<password>
TES_OUTPUT_STORAGE_PATH=<url path prefix, e.g. file:///path/to/output/dir>
```

Create .tes_instances in this folder (first line is used):

```
Funnel,http://localhost:8000
```

## Run

```bash
./run-tes.sh
```

Optionally pass a different CWL file / job file:

```bash
./run-tes.sh my-workflow.cwl my-job.yaml
```

## Results

After the workflow completes, `output.txt` will be written to the location
specified by `TES_OUTPUT_STORAGE_PATH` in `.env`.

## Troubleshooting

- TES_SERVER_USER / TES_SERVER_PASSWORD not set:
  Add both variables to .env.
- TES_OUTPUT_STORAGE_PATH not set:
  Add TES_OUTPUT_STORAGE_PATH to .env (e.g. file:///path/to/output/dir).
- No TES instance found in .tes_instances:
  Ensure first line exists and includes description,url.
- `toil-cwl-runner is not installed or not on PATH`:
  Install Toil (with the `cwl` extra) into `.venv` as shown above.
- `System Python 3.13 is incompatible with Toil 7 for CWL runs`:
  Create `.venv` with Python 3.12 specifically.
- Job store already exists:
  Set `RESTART_JOB=1` to resume, or leave `AUTO_CLEAN_JOB_STORE=1` (default)
  to have it cleaned automatically on each run.

## Additional Resources

- [Toil TES Batch System Documentation](https://toil.readthedocs.io/en/latest/appendices/environment_vars.html)
- [Toil CWL Runner Documentation](https://toil.readthedocs.io/en/latest/running/cwl.html)

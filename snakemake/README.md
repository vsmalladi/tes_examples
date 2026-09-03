# Snakemake Demonstration

License: this example is licensed under MIT. See [../LICENSE](../LICENSE).

This guide shows how to set up **Snakemake** to run workflows on a **Task
Execution Service (TES)**, using local filesystem storage for workflow
outputs (matching the [../curl](../curl) and [../py-tes](../py-tes) examples).

## File overview

- Snakefile.hello: Minimal TES-backed workflow that writes `output.txt`.
- setup.sh: Loads .env / .tes_instances and exports the environment variables
  Snakemake needs to talk to TES and to write local output.
- .env: Stores TES credentials and the output storage path used by the script.
- .tes_instances: Stores TES base URL entries in description,url format.
- Dockerfile.tes: Adds `rsync` (required by `snakemake-storage-plugin-fs`) on
  top of the upstream `snakemake/snakemake` image.

## Requirements

- Python **3.11+**
- [uv](https://github.com/astral-sh/uv)
- Reachable TES endpoint (e.g. [Funnel](https://github.com/calypr/funnel))
  configured as described below
- Valid TES basic auth credentials
- Docker, to build the `Dockerfile.tes` executor image

## Client setup

Create a virtual environment and install dependencies:

```bash
uv --version
uv venv --python 3.11 .venv
source .venv/bin/activate
uv pip install -r requirements.txt --override overrides.txt
```

> `overrides.txt` forces `py-tes>=1.1.4`, overriding the older
> `py-tes<0.5.0` required by `snakemake-executor-plugin-tes==0.1.3`. The
> older `py-tes` crashes (`TypeError: j must be a str or dict`) when a TES
> task response has a null `resources` field, which Funnel returns for
> `view=MINIMAL` task queries.

## Required configuration

Create .env in this folder:

```
TES_SERVER_USER=<username>
TES_SERVER_PASSWORD=<password>
TES_OUTPUT_STORAGE_PATH=<url path prefix, e.g. file:///path/to/output/dir>
```

Create .tes_instances in this folder (first line is used):

```
Funnel,http://localhost:8000/ga4gh/tes
```

## TES server (Funnel) configuration

Snakemake's TES executor plugin requires a `--default-storage-provider`
(here, the `fs` storage plugin) because it assumes no shared filesystem
between Snakemake and the TES worker. Since files handled by a storage
plugin are read/written directly from *inside* the task container rather
than declared as TES `inputs`/`outputs`, a plain TES server will not
bind-mount `STORAGE_PREFIX` into the container automatically — only
declared inputs/outputs get mounted. When running against
[Funnel](https://github.com/calypr/funnel) locally, add the following to
its `server.yml` so every task container gets `STORAGE_PREFIX` mounted,
and make sure the compute backend is `local` (the `manual` backend
requires a separately-registered node and does not apply this same
`Worker` config to the tasks it runs):

```yaml
Compute: local

LocalStorage:
  AllowedDirs:
    - /path/to/STORAGE_PREFIX

Worker:
  Container:
    DriverCommand: docker
    RunCommand: |
      run -i --read-only
      {{if .RemoveContainer}}--rm{{end}}
      {{.GetEnvArgs}}
      {{range $k, $v := .Tags}}--label {{$k}}={{$v}} {{end}}
      {{if .Name}}--name {{.Name}}{{end}}
      {{if .Workdir}}--workdir {{.Workdir}}{{end}}
      {{range .Volumes}}--volume {{.HostPath}}:{{.ContainerPath}}:{{if .Readonly}}ro{{else}}rw{{end}} {{end}}
      --volume /path/to/STORAGE_PREFIX:/path/to/STORAGE_PREFIX:rw
      {{.Image}} {{.Command}}
    PullCommand: pull {{.Image}}
    StopCommand: rm -f {{.Name}}
```

Restart Funnel after editing `server.yml` for the change to take effect.

> The exact `RunCommand` fields available depend on your Funnel version —
> check `config.DefaultConfig().Worker.Container.RunCommand` for your
> installed release (e.g. via its `config/default.go`) before customizing,
> since fields like `NeedsTmpfs` may not exist in older releases.

### Build the executor container image

The upstream `snakemake/snakemake` image lacks `rsync`, which
`snakemake-storage-plugin-fs` needs to move files in/out of storage. Build
the included `Dockerfile.tes` once and reference it with
`--container-image` in the run command below:

```bash
docker build -t snakemake-tes-rsync:v9.21.1 -f Dockerfile.tes .
```

## Configure TES

Use the provided setup script to load .env / .tes_instances and export all
required environment variables:

```bash
source setup.sh
```

This sets:
- `TES_ENDPOINT`, `TES_USERNAME`, `TES_PASSWORD` — connection to TES, read
  from .tes_instances and .env
- `STORAGE_PREFIX` — local filesystem path derived from
  `TES_OUTPUT_STORAGE_PATH` (the `file://` scheme is stripped since
  Snakemake's fs storage plugin expects a plain path)

---

## Example 1: Hello World

### Run command

```bash
snakemake \
  -s Snakefile.hello \
  --executor tes \
  --tes-url "$TES_ENDPOINT" \
  --tes-user "$TES_USERNAME" \
  --tes-password "$TES_PASSWORD" \
  --default-storage-provider fs \
  --default-storage-prefix "$STORAGE_PREFIX" \
  --container-image snakemake-tes-rsync:v9.21.1 \
  --latency-wait 60 \
  -j1 \
  --verbose
```

This will run the `hello_world` rule on TES and write `output.txt` to
`STORAGE_PREFIX`.

---

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
- Failed to submit task:
  Verify TES_ENDPOINT, credentials, and endpoint path.
- `FileNotFoundError` for a `...workflow-sources...tar.xz` under
  `STORAGE_PREFIX`, or any other error reading/writing files under
  `STORAGE_PREFIX` from inside the task container:
  Your TES server likely isn't bind-mounting `STORAGE_PREFIX` into task
  containers. See "TES server (Funnel) configuration" above.
- `FileNotFoundError: [Errno 2] No such file or directory: 'rsync'`:
  The executor container image is missing `rsync`. Build and use
  `Dockerfile.tes` as shown above (pass `--container-image
  snakemake-tes-rsync:v9.21.1`).
- `KeyError: 'GITHUB_WORKSPACE'` while polling job status:
  `snakemake-executor-plugin-tes==0.1.3`'s `check_active_jobs()` has
  leftover debug code that unconditionally reads
  `os.environ["GITHUB_WORKSPACE"] + "/funnel.log"` in its error-state
  branch, crashing outside CI
  ([snakemake/snakemake-executor-plugin-tes#18](https://github.com/snakemake/snakemake-executor-plugin-tes/issues/18)).
  No fixed release exists on PyPI yet; patch
  `.venv/lib/python3.11/site-packages/snakemake_executor_plugin_tes/__init__.py`
  to guard that block with `os.environ.get("GITHUB_WORKSPACE")` until a
  fix is released.

## Additional Resources

- [Snakemake TES Documentation](https://snakemake.github.io/snakemake-plugin-catalog/plugins/executor/tes.html)
- [Snakemake fs Storage Documentation](https://snakemake.github.io/snakemake-plugin-catalog/plugins/storage/fs.html)

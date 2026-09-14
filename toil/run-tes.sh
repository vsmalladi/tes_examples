#!/usr/bin/env bash
# Run Toil CWL hello-world against a TES endpoint (Funnel) using local storage.
# Copyright (c) Venkat Malladi - All Rights Reserved
set -euo pipefail

########################################
# Load environment variables
########################################
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [ -z "${TES_SERVER_USER:-}" ] || [ -z "${TES_SERVER_PASSWORD:-}" ]; then
  echo "❌ TES_SERVER_USER / TES_SERVER_PASSWORD not set"
  exit 1
fi

if [ -z "${TES_OUTPUT_STORAGE_PATH:-}" ]; then
  echo "❌ TES_OUTPUT_STORAGE_PATH not set in .env"
  exit 1
fi

########################################
# Read TES base URL
########################################
TES_BASE=$(head -n 1 .tes_instances | cut -d',' -f2)
TES_BASE=${TES_BASE%/}

if [ -z "$TES_BASE" ]; then
  echo "❌ No TES instance found in .tes_instances"
  exit 1
fi

http_code() {
  local url="$1"
  curl -s -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 5 "$url" 2>/dev/null || true
}

autodetect_tes_base() {
  local endpoint="$1"

  # Prefer explicitly mounted GA4GH TES path when present.
  if [[ "$(http_code "${endpoint}/ga4gh/tes/v1/service-info")" == "200" ]]; then
    echo "${endpoint}/ga4gh/tes"
    return
  fi

  # Standard TES at root (with /v1 route)
  if [[ "$(http_code "${endpoint}/v1/service-info")" == "200" ]]; then
    echo "$endpoint"
    return
  fi

  # Fall back to the configured endpoint; downstream tooling reports the
  # exact HTTP failure if it's wrong.
  echo "$endpoint"
}

TES_ENDPOINT="$(autodetect_tes_base "$TES_BASE")"

# Local filesystem path used both as the Toil output directory and, by
# default, the Toil job store location. Strip the file:// scheme since Toil
# expects a plain path.
STORAGE_PREFIX="${TES_OUTPUT_STORAGE_PATH#file://}"
# Use a "toil" subdirectory (not STORAGE_PREFIX itself) for --outdir: Toil
# also declares --outdir as a TES input/output mount itself, and Funnel's
# custom Worker.Container.RunCommand (see ../snakemake/README.md) already
# statically mounts STORAGE_PREFIX into every container — mounting the exact
# same destination twice makes `docker run` fail with "duplicate mount
# destination".
OUT_DIR="${OUT_DIR:-$STORAGE_PREFIX/toil}"
# The Toil job store must live under a path the TES server can mount (i.e. one
# of its advertised/allowed storage directories), so default it alongside the
# output directory rather than this project directory.
JOB_STORE="${JOB_STORE:-$STORAGE_PREFIX/toil-jobstore}"
CLEAN_MODE="${CLEAN_MODE:-onSuccess}"
TOIL_CWL_RUNNER="${TOIL_CWL_RUNNER:-$PWD/.venv/bin/toil-cwl-runner}"
RESTART_JOB="${RESTART_JOB:-0}"
AUTO_CLEAN_JOB_STORE="${AUTO_CLEAN_JOB_STORE:-1}"

# Allow overriding workflow files via args, default to example files in this dir.
CWL_FILE="${1:-example.cwl}"
JOB_FILE="${2:-example-job.yaml}"

########################################
# Basic checks
########################################
if [[ ! -x "$TOIL_CWL_RUNNER" ]]; then
  TOIL_CWL_RUNNER="$(command -v toil-cwl-runner || true)"
fi

if [[ -z "$TOIL_CWL_RUNNER" || ! -x "$TOIL_CWL_RUNNER" ]]; then
  echo "❌ toil-cwl-runner is not installed or not on PATH." >&2
  echo "   Install Toil and toil-batch-system-tes first, preferably in $PWD/.venv." >&2
  exit 1
fi

if [[ "$TOIL_CWL_RUNNER" != "$PWD/.venv/bin/toil-cwl-runner" ]]; then
  if python3 - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 13) else 1)
PY
  then
    echo "❌ System Python 3.13 is incompatible with Toil 7 for CWL runs." >&2
    echo "   Create a Python 3.12 virtual environment in $PWD/.venv and install Toil there." >&2
    exit 1
  fi
fi

if [[ ! -f "$CWL_FILE" ]]; then
  echo "❌ CWL file not found: $CWL_FILE" >&2
  exit 1
fi

if [[ ! -f "$JOB_FILE" ]]; then
  echo "❌ Job input file not found: $JOB_FILE" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

TOIL_BIN_DIR="$(cd "$(dirname "$TOIL_CWL_RUNNER")" && pwd)"
TOIL_CLI="${TOIL_CLI:-$TOIL_BIN_DIR/toil}"

RUN_ARGS=()
if [[ -e "$JOB_STORE" ]]; then
  if [[ "$RESTART_JOB" == "1" ]]; then
    RUN_ARGS+=(--restart)
  elif [[ "$AUTO_CLEAN_JOB_STORE" == "1" ]]; then
    echo "🧹 Cleaning existing job store: $JOB_STORE"
    if [[ -x "$TOIL_CLI" ]]; then
      "$TOIL_CLI" clean "$JOB_STORE" || true
    fi
    rm -rf "$JOB_STORE"
  else
    echo "❌ Job store already exists: $JOB_STORE" >&2
    echo "   Set RESTART_JOB=1 to resume, or AUTO_CLEAN_JOB_STORE=1 to clean it automatically." >&2
    exit 1
  fi
fi

# Export plugin-recognized variables.
export TOIL_TES_ENDPOINT="$TES_ENDPOINT"
export TOIL_TES_USER="$TES_SERVER_USER"
export TOIL_TES_PASSWORD="$TES_SERVER_PASSWORD"

# toil-batch-system-tes normally verifies the job store path is mountable by
# cross-checking it against the TES server's advertised /service-info storage
# list. Funnel's /service-info reports a hardcoded placeholder storage list
# rather than its actual configured LocalStorage.AllowedDirs, so this check
# always fails here even though STORAGE_PREFIX (and the job store beneath it)
# is genuinely mounted into every task container via Funnel's custom
# Worker.Container.RunCommand (see ../snakemake/README.md). Skip the check.
export TOIL_TES_SKIP_STORAGE_CHECK=1

echo "✅ Using TES instance: $TES_ENDPOINT"
echo "  JobStore   : $JOB_STORE"
echo "  Output dir : $OUT_DIR"
echo "  CWL        : $CWL_FILE"
echo "  Inputs     : $JOB_FILE"

########################################
# Run
########################################
"$TOIL_CWL_RUNNER" \
  --batchSystem tes \
  --jobStore "$JOB_STORE" \
  "${RUN_ARGS[@]}" \
  --tesEndpoint "$TES_ENDPOINT" \
  --tesUser "$TES_SERVER_USER" \
  --tesPassword "$TES_SERVER_PASSWORD" \
  --outdir "$OUT_DIR" \
  --clean "$CLEAN_MODE" \
  "$CWL_FILE" "$JOB_FILE"

echo "✅ Done. Output directory: $OUT_DIR"

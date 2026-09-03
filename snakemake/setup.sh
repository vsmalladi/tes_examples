#!/usr/bin/env bash
# Setup environment for Snakemake + TES examples
# Source this file before running Snakemake:
#   source setup.sh

# Do not enable strict shell options here because this script is intended to be
# sourced from interactive shells (zsh/bash), and `set -u` can break prompt vars.

########################################
# Load environment variables
########################################
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [ -z "${TES_SERVER_USER:-}" ] || [ -z "${TES_SERVER_PASSWORD:-}" ]; then
  echo "❌ TES_SERVER_USER / TES_SERVER_PASSWORD not set"
  return 1 2>/dev/null || exit 1
fi

if [ -z "${TES_OUTPUT_STORAGE_PATH:-}" ]; then
  echo "❌ TES_OUTPUT_STORAGE_PATH not set in .env"
  return 1 2>/dev/null || exit 1
fi

########################################
# Read TES base URL
########################################
TES_BASE=$(head -n 1 .tes_instances | cut -d',' -f2)
TES_BASE=${TES_BASE%/}

if [ -z "$TES_BASE" ]; then
  echo "❌ No TES instance found in .tes_instances"
  return 1 2>/dev/null || exit 1
fi

# TES Configuration
export TES_ENDPOINT="$TES_BASE"
export TES_USERNAME="$TES_SERVER_USER"
export TES_PASSWORD="$TES_SERVER_PASSWORD"

# Local filesystem storage prefix used by Snakemake's fs storage plugin.
# Strip the file:// scheme since the fs plugin expects a plain path.
export STORAGE_PREFIX="${TES_OUTPUT_STORAGE_PATH#file://}"

echo "✅ Environment configured:"
echo "  TES_ENDPOINT=$TES_ENDPOINT"
echo "  TES_USERNAME=$TES_USERNAME"
echo "  STORAGE_PREFIX=$STORAGE_PREFIX"

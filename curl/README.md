# TES curl Hello World

This folder contains a minimal TES task submission example using curl.

## File overview

- hello-world.sh: Submits a Hello World task to a TES endpoint, polls task state, and prints task logs.
- .env: Stores TES credentials used by the script.
- .tes_instances: Stores TES base URL entries in description,url format.

## What hello-world.sh does

1. Loads environment variables from .env if present.
2. Validates TES_SERVER_USER and TES_SERVER_PASSWORD.
3. Reads TES_BASE from the first line of .tes_instances.
4. Builds a TES task payload using jq.
5. Submits the task to POST /v1/tasks.
6. Polls GET /v1/tasks/{id} until a terminal state.
7. Prints TES logs from the task response.

## Prerequisites

- bash
- curl
- jq
- Reachable TES endpoint
- Valid TES basic auth credentials

## Required configuration

Create .env in this folder:

TES_SERVER_USER=<username>
TES_SERVER_PASSWORD=<password>

Create .tes_instances in this folder (first line is used):

Funnel,http://localhost:8000/ga4gh/tes

## Run

chmod +x hello-world.sh
./hello-world.sh

## Expected behavior

- Prints selected TES instance URL.
- Prints task submission response containing task id.
- Polls and prints state transitions.
- Stops on terminal state and prints .logs from task details.

## Troubleshooting

- TES_SERVER_USER / TES_SERVER_PASSWORD not set:
  Add both variables to .env.
- No TES instance found in .tes_instances:
  Ensure first line exists and includes description,url.
- Failed to submit task:
  Verify TES_BASE, credentials, and endpoint path.
- Task reaches EXECUTOR_ERROR or SYSTEM_ERROR:
  Inspect printed logs and server-side task/container logs.

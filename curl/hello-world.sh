#!/usr/bin/env bash
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

echo "✅ Using TES instance: $TES_BASE"

########################################
# Hello World TES payload
########################################
OUTPUT_URL="${TES_OUTPUT_STORAGE_PATH%/}/output.txt"

TASK_PAYLOAD=$(jq -n --arg output_url "$OUTPUT_URL" '
{
  "executors": [
    {
      "image": "alpine:3.22.4",
      "command": [
        "sh",
        "-c",
        "mkdir -p /data && echo \"Hello World from TES\" > /data/output.txt"
      ]
    }
  ],
  "resources": {
    "ram_gb": 1.0
  },
  "outputs": [
    {
      "name": "output.txt",
      "path": "/data/output.txt",
      "url": $output_url,
      "type": "FILE"

    }
  ]
}'
)

########################################
# Submit task
########################################
echo "🚀 Submitting Hello World task..."

echo "$TASK_PAYLOAD" | jq 

RESPONSE=$(curl -s -X POST "$TES_BASE/v1/tasks" \
  -H "Content-Type: application/json" \
  --user "$TES_SERVER_USER:$TES_SERVER_PASSWORD" \
  --data-raw "$TASK_PAYLOAD")

echo "📨 Response:"
echo "$RESPONSE"

TASK_ID=$(echo "$RESPONSE" | jq -r '.id')

if [[ -z "$TASK_ID" || "$TASK_ID" == "null" ]]; then
  echo "❌ Failed to submit task"
  exit 1
fi

echo "✅ Task ID: $TASK_ID"

########################################
# Poll task state
########################################
FINAL_STATES=("COMPLETE" "EXECUTOR_ERROR" "SYSTEM_ERROR" "CANCELLED")

while true; do
  sleep 3
  STATE=$(curl -s "$TES_BASE/v1/tasks/$TASK_ID" \
    --user "$TES_SERVER_USER:$TES_SERVER_PASSWORD" \
    | jq -r '.state')

  echo "⏳ Task $TASK_ID state: $STATE"

  if [[ " ${FINAL_STATES[*]} " =~ " $STATE " ]]; then
    break
  fi
done

########################################
# Show logs
########################################
echo "📜 Task logs:"
curl -s "$TES_BASE/v1/tasks/$TASK_ID" \
  --user "$TES_SERVER_USER:$TES_SERVER_PASSWORD" \
  | jq '.logs'

echo "✅ Done"
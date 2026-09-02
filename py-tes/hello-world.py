#!/usr/bin/env python3
"""
Hello World example using py-tes.
"""

import logging
import os
import sys
from time import sleep
from pathlib import Path

import tes
from dotenv import load_dotenv

# -------------------------------------------------------
# Setup
# -------------------------------------------------------

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s - %(message)s',
    datefmt='%H:%M:%S'
)

LOGGER = logging.getLogger(__name__)

FINAL_STATES = {"COMPLETE", "EXECUTOR_ERROR", "SYSTEM_ERROR", "CANCELLED"}


def main() -> None:
    # ---------------------------------------------------
    # Load environment variables
    # ---------------------------------------------------
    user = os.getenv("TES_SERVER_USER")
    password = os.getenv("TES_SERVER_PASSWORD")
    if not user or not password:
        LOGGER.critical("TES_SERVER_USER / TES_SERVER_PASSWORD not set")
        sys.exit(1)

    output_storage_path = os.getenv("TES_OUTPUT_STORAGE_PATH")
    if not output_storage_path:
        LOGGER.critical("TES_OUTPUT_STORAGE_PATH not set in .env")
        sys.exit(1)

    # ---------------------------------------------------
    # Read TES base URL
    # ---------------------------------------------------
    tes_file = Path(".tes_instances")
    if not tes_file.exists():
        LOGGER.critical("Missing .tes_instances file")
        sys.exit(1)

    with tes_file.open() as f:
        first_line = f.readline().strip()

    if not first_line:
        LOGGER.critical("No TES instance found in .tes_instances")
        sys.exit(1)

    _, tes_base = first_line.split(",", 1)
    tes_base = tes_base.rstrip("/")

    LOGGER.info(f"Using TES instance: {tes_base}")

    client = tes.HTTPClient(
        url=tes_base,
        user=user,
        password=password,
        timeout=5,
    )

    # ---------------------------------------------------
    # Hello World task
    # ---------------------------------------------------
    output_url = f"{output_storage_path.rstrip('/')}/output.txt"

    task = tes.Task(
        executors=[
            tes.Executor(
                image="alpine:3.22.4",
                command=[
                    "sh",
                    "-c",
                    "mkdir -p /data && echo \"Hello World from TES, py-tes\" > /data/output.txt"
                ]
            )
        ],
        resources=tes.Resources(
            ram_gb=1.0
        ),
        outputs=[
            tes.Output(
                name="output.txt",
                path="/data/output.txt",
                url=output_url
            )
        ]
    )

    # ---------------------------------------------------
    # Submit task
    # ---------------------------------------------------
    LOGGER.info("Submitting Hello World task...")
    try:
        task_id = client.create_task(task)
    except Exception as exc:
        response = getattr(exc, "response", None)
        if response is not None:
            LOGGER.error("Task submission failed: HTTP %s - %s", response.status_code, response.text)
        LOGGER.critical("Failed to submit task")
        sys.exit(1)

    LOGGER.info(f"Task ID: {task_id}")

    # ---------------------------------------------------
    # Poll task state
    # ---------------------------------------------------
    while True:
        sleep(3)
        state = client.get_task(task_id).state
        LOGGER.info(f"Task {task_id} state: {state}")
        if state in FINAL_STATES:
            break

    # ---------------------------------------------------
    # Show logs
    # ---------------------------------------------------
    LOGGER.info("Task logs:")
    final_task = client.get_task(task_id)
    LOGGER.info(final_task.logs)

    LOGGER.info("Done")


if __name__ == "__main__":
    main()

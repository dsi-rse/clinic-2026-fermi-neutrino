#!/bin/bash
#
# Grab an interactive GPU shell.  Use this for smoke tests, debugging and
# poking at the data -- never run compute on the login node.
#
#   ./slurm/interactive.sh                  # 2 h on the `dev` partition
#   PARTITION=general TIME=4:00:00 ./slurm/interactive.sh
#
# `dev` is the short queue meant for testing; `general` is for real work.
# Start on `dev` and only move to `general` once your command actually runs.

set -euo pipefail

exec srun \
    --partition="${PARTITION:-dev}" \
    --gres=gpu:1 \
    --cpus-per-task="${CPUS:-8}" \
    --mem-per-cpu="${MEM_PER_CPU:-8G}" \
    --time="${TIME:-2:00:00}" \
    --pty /bin/bash

#!/bin/bash
#
# Submit one config/sweeps/<name>.txt as a SLURM job array.
#
#   ./slurm/submit-sweep.sh baseline
#   ./slurm/submit-sweep.sh optical-width --array-throttle 4
#
# --array-throttle N caps how many tasks run at once (SLURM's "%N" suffix).
# Use it: the `general` partition is shared with the whole DSI, and queueing
# twenty simultaneous GPU jobs is how you become unpopular.

set -euo pipefail
cd "$(dirname "$0")/.."

SWEEP="${1:?usage: submit-sweep.sh <sweep-name> [--array-throttle N]}"
shift || true

THROTTLE=""
if [ "${1:-}" = "--array-throttle" ]; then
    THROTTLE="%${2:?--array-throttle needs a number}"
    shift 2
fi

CONFIG="config/sweeps/${SWEEP}.txt"
[ -f "$CONFIG" ] || { echo "no such sweep config: $CONFIG" >&2; exit 1; }

N=$(grep -cvE '^[[:space:]]*(#|$)' "$CONFIG" || true)
[ "${N:-0}" -gt 0 ] || { echo "$CONFIG contains no configurations" >&2; exit 1; }

mkdir -p logs

echo "submitting $N tasks from $CONFIG"
sbatch --export="ALL,SWEEP=$SWEEP" \
       --array="1-${N}${THROTTLE}" \
       "$@" \
       slurm/train-sweep.sbatch

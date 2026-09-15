#!/bin/bash
#
# Hyperparameter sweep as a SLURM job array: one array task -> one GPU job ->
# one line of config/sweeps/$SWEEP.txt.
#
# Use slurm/submit-sweep.sh rather than calling this directly -- it works out
# the --array range from the config file so you never have to keep a count in
# sync by hand.
#
#SBATCH --job-name=nugraph-sweep
#SBATCH --partition=general
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=16G
#SBATCH --time=12:00:00
#SBATCH --output=logs/slurm-%x-%A_%a.out
#SBATCH --open-mode=append
#SBATCH --signal=SIGUSR1@90
#SBATCH --requeue

set -eo pipefail
cd "${SLURM_SUBMIT_DIR:-$PWD}"

# shellcheck source=../env.sh
source ./env.sh

: "${SWEEP:?set SWEEP=<name>, matching config/sweeps/<name>.txt}"
: "${SLURM_ARRAY_TASK_ID:?this script must be submitted as a job array}"

CONFIG="config/sweeps/${SWEEP}.txt"
[ -f "$CONFIG" ] || { echo "no such sweep config: $CONFIG" >&2; exit 1; }

# Nth non-blank, non-comment line of the config file.
ARGS=$(grep -vE '^[[:space:]]*(#|$)' "$CONFIG" | sed -n "${SLURM_ARRAY_TASK_ID}p")
if [ -z "$ARGS" ]; then
    echo "$CONFIG has no entry for array task $SLURM_ARRAY_TASK_ID" >&2
    exit 1
fi

VERSION="task-$(printf '%03d' "$SLURM_ARRAY_TASK_ID")"
echo "sweep=$SWEEP version=$VERSION args=$ARGS"

# $ARGS is deliberately unquoted: it is a list of flags, not one argument.
# shellcheck disable=SC2086
srun python external/nugraph/scripts/train.py \
    --device 0 \
    --name "$SWEEP" \
    --version "$VERSION" \
    $ARGS

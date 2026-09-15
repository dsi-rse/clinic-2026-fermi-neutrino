#!/bin/bash
#
# Run inference with a trained checkpoint over the test split and dump per-hit
# predictions to an HDF5 file for offline analysis.
#
#   CKPT=$NUGRAPH_LOG/my-run/task-001/checkpoints/epoch=79-step=1234.ckpt \
#   OUT=$NUGRAPH_LOG/my-run/task-001/inference.h5 \
#   sbatch slurm/test.sbatch
#
#SBATCH --job-name=nugraph-test
#SBATCH --partition=general
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=16G
#SBATCH --time=2:00:00
#SBATCH --output=logs/slurm-%x-%j.out
#SBATCH --open-mode=append

set -eo pipefail
cd "${SLURM_SUBMIT_DIR:-$PWD}"

# shellcheck source=../env.sh
source ./env.sh

: "${CKPT:?set CKPT=/path/to/checkpoint.ckpt}"
: "${OUT:?set OUT=/path/to/output.h5}"

# scripts/test.py refuses to overwrite, so a stale OUT is a hard failure.
srun python external/nugraph/scripts/test.py \
    --device 0 --checkpoint "$CKPT" --outfile "$OUT" "$@"

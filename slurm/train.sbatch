#!/bin/bash
#
# One NuGraph training run on one GPU.
#
#   sbatch slurm/train.sbatch --optical --semantic --filter --name my-run
#
# Everything after the script name is passed straight through to
# external/nugraph/scripts/train.py, exactly like upstream's own
# scripts/train_batch.sh.  Run `python external/nugraph/scripts/train.py --help`
# to see the full flag list.
#
#SBATCH --job-name=nugraph-train
#SBATCH --partition=general
#SBATCH --gres=gpu:1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=16G
#SBATCH --time=12:00:00
#SBATCH --output=logs/slurm-%x-%j.out
#SBATCH --open-mode=append
#SBATCH --signal=SIGUSR1@90
#SBATCH --requeue

# --signal=SIGUSR1@90 plus --requeue is what lets a long training survive the
# queue's wall-clock limit: SLURM sends SIGUSR1 90 s before killing the job,
# PyTorch Lightning's SLURMEnvironment plugin (already installed by
# scripts/train.py) catches it, checkpoints, and resubmits the job.  Do not
# remove either directive.

set -eo pipefail
cd "${SLURM_SUBMIT_DIR:-$PWD}"

# shellcheck source=../env.sh
source ./env.sh

srun python external/nugraph/scripts/train.py --device 0 "$@"

#!/bin/bash

#SBATCH --job-name=quick-test
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=0:05:00
#SBATCH --output=logs/slurm-%x-%j.out
#SBATCH --open-mode=append

set -eo pipefail
cd "${SLURM_SUBMIT_DIR:-$PWD}"

export NUGRAPH_DIR=/net/projects2/fermi2526/clinic-2026-fermi-neutrino-$USER/external/nugraph
source /etc/profile.d/conda.sh
source /net/projects2/fermi2526/setup-env.sh

hostname
python - <<'PY'
import torch
import numpy
import pandas
import scipy
import matplotlib
import sklearn
import h5py
import uproot
import awkward
import lightning
import torch_geometric
import nugraph

print(torch.__version__)
PY

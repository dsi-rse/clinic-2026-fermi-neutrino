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
import importlib
import sys

libraries = [
    "torch",
    "numpy",
    "scipy",
    "pandas",
    "matplotlib",
    "h5py",
    "sklearn",
    "torch_geometric",
    "pytorch_lightning",
    "nugraph",
]

failed = []
for name in libraries:
    try:
        module = importlib.import_module(name)
        print(f"OK    {name} {getattr(module, '__version__', '(no version)')}")
    except Exception as e:
        print(f"FAIL  {name}: {type(e).__name__}: {e}")
        failed.append(name)

if failed:
    print(f"{len(failed)} librar{'y' if len(failed) == 1 else 'ies'} failed to import: {', '.join(failed)}")
    sys.exit(1)
PY

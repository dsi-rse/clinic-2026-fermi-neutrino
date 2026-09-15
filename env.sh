# shellcheck shell=bash
#
# Environment setup for the Clinic 2026 Fermi Neutrino project.
#
#   source env.sh          # <-- source it, do not execute it
#
# Every SLURM script in slurm/ sources this file, so this is the single place
# where cluster paths and the conda environment name are written down.  If you
# need a different value for one shell, export it *before* sourcing; every
# variable below honours a value you already set.

# Resolve the repository root from this file's location, so it works no matter
# where you sourced it from.
if [ -n "${BASH_SOURCE[0]:-}" ]; then
    CLINIC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    CLINIC_ROOT="$(pwd)"
fi
export CLINIC_ROOT

# ---------------------------------------------------------------------------
# Shared project allocation on the DSI cluster
# ---------------------------------------------------------------------------
# Everything big -- data, logs, checkpoints, working clones -- lives here and
# not in $HOME, which is capped at 20-50 GB.  See docs/cluster.md.
export FERMI_PROJECT_DIR="${FERMI_PROJECT_DIR:-/net/projects2/fermi2526}"

# ---------------------------------------------------------------------------
# Conda environment
# ---------------------------------------------------------------------------
# TODO(mentor): a conda environment for this project already exists somewhere
# under $FERMI_PROJECT_DIR.  Once you can see it, set NUGRAPH_ENV to its
# on-disk prefix (e.g. "$FERMI_PROJECT_DIR/envs/nugraph-gpu") so that everyone
# on the team shares one environment instead of building their own.  Until
# then this falls back to a per-user environment created by `make env`.
NUGRAPH_ENV="${NUGRAPH_ENV:-nugraph-gpu}"
export NUGRAPH_ENV

if [ -z "${CLINIC_SKIP_ACTIVATE:-}" ]; then
    if command -v micromamba >/dev/null 2>&1; then
        eval "$(micromamba shell hook --shell bash)"
        micromamba activate "$NUGRAPH_ENV"
    elif command -v conda >/dev/null 2>&1; then
        # shellcheck disable=SC1091
        eval "$(conda shell.bash hook)"
        conda activate "$NUGRAPH_ENV"
    else
        echo "env.sh: no micromamba or conda found; skipping activation." >&2
        echo "        See docs/onboarding.md to install micromamba." >&2
    fi

    # conda and micromamba only *warn* when an environment does not exist, so
    # without this check a batch job would sail on with the system Python and
    # fail much later in a far more confusing place.  Returning non-zero makes
    # the `set -e` in the slurm/ scripts stop the job here instead.
    # NUGRAPH_ENV may be a name ("nugraph-gpu") or a prefix path
    # ("/net/projects2/fermi2526/envs/nugraph-gpu"); accept either.
    if [ "${CONDA_DEFAULT_ENV:-}" != "$NUGRAPH_ENV" ] &&
       [ "${CONDA_PREFIX:-}" != "$NUGRAPH_ENV" ] &&
       [ "$(basename "${CONDA_PREFIX:-none}")" != "$(basename "$NUGRAPH_ENV")" ]; then
        echo "env.sh: could not activate \"$NUGRAPH_ENV\" (CONDA_PREFIX=${CONDA_PREFIX:-unset})." >&2
        echo "        Build it with 'make env', or point NUGRAPH_ENV at an" >&2
        echo "        existing environment name or prefix.  See docs/onboarding.md." >&2
        echo "        To skip activation entirely, set CLINIC_SKIP_ACTIVATE=1." >&2
        return 1 2>/dev/null || exit 1
    fi
fi

# ---------------------------------------------------------------------------
# NuGraph's three-variable contract
# ---------------------------------------------------------------------------
# nugraph reads exactly these three variables (see
# external/nugraph/nugraph/nugraph/util/scriptutils.py).  NUGRAPH_DIR must be a
# *directory* -- a previous cohort set it to a .py file and spent a while
# confused.
export NUGRAPH_DIR="${NUGRAPH_DIR:-$CLINIC_ROOT/external/nugraph}"
export NUGRAPH_DATA="${NUGRAPH_DATA:-$FERMI_PROJECT_DIR/data}"
export NUGRAPH_LOG="${NUGRAPH_LOG:-$FERMI_PROJECT_DIR/logs/$USER}"
mkdir -p "$NUGRAPH_LOG" 2>/dev/null || true

# Put the submodule checkout ahead of any installed copy of nugraph/pynuml, so
# that your edits inside external/nugraph take effect with no reinstall.  This
# is the whole reason nugraph is a submodule rather than a pinned dependency.
export PYTHONPATH="$NUGRAPH_DIR/nugraph:$NUGRAPH_DIR/pynuml:$CLINIC_ROOT/src${PYTHONPATH:+:$PYTHONPATH}"

# ---------------------------------------------------------------------------
# Shared-cluster hygiene
# ---------------------------------------------------------------------------
# Building a conda environment or unpacking wheels in $HOME will blow the quota.
export TMPDIR="${TMPDIR:-/net/scratch/$USER/tmp}"
mkdir -p "$TMPDIR" 2>/dev/null || true

# Project storage is group-shared; keep new files group-writable so your
# teammates can read your logs and checkpoints.
umask 0007

# Compute nodes are shared.  Without this, torch happily grabs all 64 threads.
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-4}"

if [ -z "${CLINIC_QUIET:-}" ]; then
    cat <<EOF
clinic environment configured:
  CLINIC_ROOT        $CLINIC_ROOT
  FERMI_PROJECT_DIR  $FERMI_PROJECT_DIR
  NUGRAPH_DIR        $NUGRAPH_DIR
  NUGRAPH_DATA       $NUGRAPH_DATA
  NUGRAPH_LOG        $NUGRAPH_LOG
  TMPDIR             $TMPDIR
EOF
fi

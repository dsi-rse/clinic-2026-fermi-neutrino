
# general
mkfile_path := $(abspath $(firstword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
current_abs_path := $(subst Makefile,,$(mkfile_path))

# pipeline constants
# PROJECT_NAME
project_name := "clinic-2026-fermi-neutrino"
project_dir := "$(current_abs_path)"

# environment variables
include .env

# Check required environment variables
ifeq ($(DATA_DIR),)
	$(error DATA_DIR must be set in .env file)
endif

# Name of the conda environment. Override on the command line once the shared
# environment under $(FERMI_PROJECT_DIR) is available:
#   make env NUGRAPH_ENV=/net/projects2/fermi2526/envs/nugraph-gpu
NUGRAPH_ENV ?= nugraph-gpu

# Port for the TensorBoard server. Pick your own so you don't collide with a
# teammate on the same node: make tensorboard PORT=6123
PORT ?= 6006

.PHONY: help submodules env lint test smoke tensorboard open-ssh-login-node

help:
	@echo "Setup:"
	@echo "  make submodules  - check out the nugraph submodule"
	@echo "  make env         - build the conda environment (cluster; takes a while)"
	@echo "Running:"
	@echo "  make smoke       - submit a 2-minute training job to the dev queue"
	@echo "  make tensorboard - serve metrics from \$$NUGRAPH_LOG on PORT=$(PORT)"
	@echo "Development:"
	@echo "  make lint        - run pre-commit on all files"
	@echo "  make test        - run the test suite"
	@echo ""
	@echo "Single runs and sweeps go through slurm/ directly; see slurm/README.md."

submodules:
	git submodule update --init --recursive

# Dependencies come from nugraph's own environment file, so there is one source
# of truth and nothing to keep in sync. The packages nugraph does not need but
# we do (linting, testing, notebook kernels) are added on top.
env: submodules
	micromamba create -y -n $(NUGRAPH_ENV) -f external/nugraph/nugraph-gpu.yaml
	micromamba install -y -n $(NUGRAPH_ENV) \
		ruff pre-commit pytest ipykernel jupyterlab nbstripout python-dotenv
	micromamba run -n $(NUGRAPH_ENV) pip install --no-deps -e external/nugraph/nugraph
	micromamba run -n $(NUGRAPH_ENV) pip install --no-deps -e external/nugraph/pynuml
	micromamba run -n $(NUGRAPH_ENV) pre-commit install
	@echo ""
	@echo "Done. Now run: source env.sh"

lint:
	pre-commit run --all-files

test:
	pytest

# A cheap end-to-end check: does the environment import, can it read the
# dataset, does a training step run on a GPU? Two batches, one epoch.
smoke:
	mkdir -p logs
	sbatch --partition=dev --time=0:30:00 slurm/train.sbatch \
		--name smoke --semantic --filter \
		--epochs 1 --limit_train_batches 2 --limit_val_batches 2

# Run this on the login node and forward PORT over SSH to view it locally.
# Reads NUGRAPH_LOG from your shell (set by env.sh), falling back to the
# per-user default under the shared project directory.
tensorboard:
	tensorboard --port $(PORT) --bind_all \
		--logdir "$${NUGRAPH_LOG:-$(FERMI_PROJECT_DIR)/logs/$$USER}" \
		--samples_per_plugin 'images=200'

open-ssh-login-node:
	code --remote ssh-remote+fe.ds $(FERMI_PROJECT_DIR)/$$USER/clinic-2026-fermi-neutrino

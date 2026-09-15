# Clinic 2026 Fermi Neutrino

Optimizing a Graph Neural Network (GNN) for neutrino event reconstruction —
University of Chicago Data Science Clinic, Autumn 2026, with Fermi National
Accelerator Laboratory.

## Team

| Role | Name | Email |
|---|---|---|
| Mentor | Giuseppe Cerati (Fermilab, Scientific Computing Division) | |
| Faculty mentor / TA | | |
| Student | | |
| Student | | |
| Student | | |
| Student | | |

## Project Background

Fermilab's neutrino detectors reconstruct a neutrino interaction by tracking the
particles it produces as 3D tracks in a **Liquid Argon Time Projection Chamber**
(LArTPC). But the LArTPC is not the only detector watching the interaction:
**photomultiplier tubes** (PMTs) see the prompt flash of scintillation light
from the same event, on a completely different timescale and with completely
different information content.

[NuGraph](https://github.com/nugraph/nugraph) reconstructs these events with a
graph neural network — a generalisation of 2D image recognition to detectors
whose elements have arbitrary interrelationships. It represents an event as a
heterogeneous graph of wire hits, 3D spacepoints, PMT pulses and optical
flashes, and passes messages between them.

## Project Goals

Improve the measurement by getting more out of the non-LArTPC subdetectors.
Concretely:

1. **Hyperparameter tuning** of the existing network, using the DSI cluster to
   run many GPU jobs.
2. **Evaluating network configurations that improve information flow between the
   LArTPC and the other detectors** — the cross-detector message passing in
   NuGraph's optical module.
3. **Assessing performance at local (node) and global (graph) levels**: per-hit
   predictions like particle type and background rejection, versus
   whole-interaction predictions like event class and vertex position.

Work uses a large sample of **MicroBooNE open data**. If the study succeeds the
results may be published, with contributing students as co-authors.

## Start here

1. [`docs/onboarding.md`](docs/onboarding.md) — accounts, clone, environment,
   first job. **Read this first.**
2. [`docs/nugraph-orientation.md`](docs/nugraph-orientation.md) — which file
   does what in NuGraph, and the questions to take to your mentor.
3. [`docs/cluster.md`](docs/cluster.md) — the DSI cluster: nodes, partitions,
   where data goes, and what not to commit.
4. [`slurm/README.md`](slurm/README.md) — submitting single runs and sweeps.

## Usage

```bash
git clone --recurse-submodules https://github.com/dsi-rse/clinic-2026-fermi-neutrino.git
cd clinic-2026-fermi-neutrino
make env          # build the conda environment (on the cluster; takes a while)
source env.sh     # in every new shell
make smoke        # submit a two-minute training job to the dev queue
```

`make help` lists the rest. There is no Docker in this project: the work needs
cluster GPUs and a conda-provided CUDA and MPI stack, so conda on the cluster is
the only environment.

### NuGraph is a submodule

`external/nugraph` is [dsi-rse/NuGraph](https://github.com/dsi-rse/NuGraph), our
fork of [nugraph/nugraph](https://github.com/nugraph/nugraph), on the
`clinic-2026` branch. **Your changes to the network go there**, committed and
pushed from inside that directory, and pull-requested against `clinic-2026`.
This repo records which commit of the fork you are using. See the "Working on
NuGraph itself" section of [`docs/onboarding.md`](docs/onboarding.md) — getting
this wrong is the most common way to lose a day's work.

`env.sh` puts the submodule ahead of any installed copy on `PYTHONPATH`, so
your edits take effect with no reinstall.

## Repository Structure

| Path | Contents |
|---|---|
| `env.sh` | Cluster paths and conda activation. **The one place these are written down** |
| `external/nugraph/` | The NuGraph + pynuml submodule — upstream code, our fork |
| `slurm/` | Batch scripts: single runs, job-array sweeps, inference, interactive shells |
| `config/sweeps/` | Sweep definitions — one set of `train.py` flags per line |
| `src/utils/` | Our Python glue: path settings, loading run metrics for comparison |
| `notebooks/` | Exploratory and analysis notebooks |
| `data/` | **Notes on the data, not the data.** The dataset lives on the cluster |
| `output/` | Small, shareable work product |
| `docs/` | Onboarding, cluster reference, NuGraph orientation |
| `tests/` | Tests for our glue code (the GPU stack is not exercised in CI) |
| `logs/` | SLURM job output (gitignored) |

## Style

We use [`ruff`](https://docs.astral.sh/ruff/) to enforce style standards, run
before each commit via [`pre-commit`](https://pre-commit.com/). `make env`
installs the hook; `make lint` runs it over everything.
`external/nugraph` is excluded — it is upstream code with its own conventions,
and reformatting it would turn every merge from upstream into a conflict.

## Reference

- NuGraph2 paper: [arXiv:2403.11872](https://arxiv.org/abs/2403.11872)
- [NuGraph documentation](https://nugraph.readthedocs.io/) ·
  [pynuml documentation](https://pynuml.readthedocs.io/)
- [MicroBooNE](https://microboone.fnal.gov/) ·
  [MicroBooNE open data](https://microboone.fnal.gov/documents-publications/public-datasets/)
- Clinic: [Slurm tutorial](https://github.com/dsi-clinic/the-clinic/blob/main/tutorials/slurm.md) ·
  [coding standards](https://github.com/dsi-clinic/the-clinic/blob/main/coding-standards/coding-standards.md)
- Data and code policy: [`DataPolicy.md`](DataPolicy.md)

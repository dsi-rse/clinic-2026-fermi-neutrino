# The DSI cluster, for this project

All computation for this project happens on the DSI cluster. If you have not
used it before, work through the clinic's own guides first — they cover account
setup, SSH keys and VS Code, which this document does not repeat:

- [ssh / GitHub / cluster setup](https://github.com/dsi-clinic/the-clinic/blob/main/tutorials/ssh_github_cluster.md)
- [Slurm tutorial](https://github.com/dsi-clinic/the-clinic/blob/main/tutorials/slurm.md)
- [Troubleshooting](https://github.com/dsi-clinic/the-clinic/blob/main/tutorials/troubleshooting.md)

## What you are logging into

| | |
|---|---|
| Login node | `ssh fe.ds` (`fe01`) — editing and job submission only |
| GPU nodes | `g0NN`, one **NVIDIA A40 (48 GB)** per job by default, 32 cores / 64 threads, ~512 GB RAM, CUDA 12.x |
| Partitions | `dev` for short tests, `general` for real work |
| Account / QOS | `general_group` / `normal` — the defaults, so no `--account` needed |

**Never run training, preprocessing, or a notebook kernel on the login node.**
Use `./slurm/interactive.sh` for an interactive GPU shell, or `sbatch` for
anything long. This is the single rule that gets students into trouble.

## Where things go

Home directories are capped (20–50 GB) and are private to you, which makes them
the wrong place for both data and a shared project. Put everything on `/net`:

| Path | Use |
|---|---|
| `/net/projects2/fermi2526/` | **this project's shared allocation** (`$FERMI_PROJECT_DIR`) |
| `/net/projects2/fermi2526/data/` | the graph dataset (`$NUGRAPH_DATA`) — read-only, shared |
| `/net/projects2/fermi2526/logs/$USER/` | your training logs and checkpoints (`$NUGRAPH_LOG`) |
| `/net/projects2/fermi2526/$USER/` | your working clone of this repository |
| `/net/scratch/$USER/` | scratch and `$TMPDIR`. **Ephemeral — may be deleted at any time** |
| `$HOME` | dotfiles, your micromamba install. Nothing large |

That layout is what `env.sh` assumes. If the actual layout of
`/net/projects2/fermi2526/` differs, fix `env.sh` — it is the one place these
paths are written down — rather than working around it per-script.

`env.sh` sets `umask 0007` so files you create on project storage stay
group-writable and your teammates can read your logs. If you get permission
errors on someone else's files, that is what went wrong.

If you need access to `/net/projects2/fermi2526/` and don't have it, that is a
Unix group membership that DSI techstaff have to grant — ask early, it is not
instant.

## Conda environments

The cluster has no Docker and no `module load` for this stack; conda is the unit
of reproducibility. Follow the [Slurm tutorial's micromamba
section](https://github.com/dsi-clinic/the-clinic/blob/main/tutorials/slurm.md)
to install micromamba, then `make env` builds the project environment from
NuGraph's own `nugraph-gpu.yaml`.

Two things that will bite you otherwise:

- **`TMPDIR`.** Building this environment unpacks several GB of CUDA wheels
  into `$TMPDIR`, which defaults to a location under your home quota and will
  fail. `env.sh` points it at `/net/scratch/$USER/tmp`; if you are building the
  environment *before* sourcing `env.sh`, export it yourself first.
- **The MPI build of h5py.** `nugraph-gpu.yaml` pins `h5py=*=*mpich*`
  deliberately — `pynuml` opens files with the MPI-IO driver and a plain
  `pip install h5py` cannot do that. Don't "fix" a dependency problem by
  pip-installing h5py over the top.

A shared environment for this project is supposed to exist under
`$FERMI_PROJECT_DIR`. Once you can see it, set `NUGRAPH_ENV` in `env.sh` to its
prefix so the whole team runs the same thing. Until then everyone builds their
own, which works but drifts.

## Viewing metrics

Training writes TensorBoard logs to `$NUGRAPH_LOG/<name>/<version>/`. From the
login node:

```bash
make tensorboard PORT=6123      # pick your own port so you don't collide
```

then forward it from your laptop:

```bash
ssh -N -L 6123:localhost:6123 fe.ds
```

and open `http://localhost:6123`. To compare many runs numerically instead of
by eye, use `utils.runs` (see `src/utils/runs.py`).

## Secrets: don't

NuGraph can log to Weights & Biases instead of TensorBoard (`--logger wandb`),
though that path is deprecated upstream and prints a warning. If you use it:

- Run `wandb login` **once, interactively**. It writes a token to `~/.netrc`,
  outside the repository.
- If compute nodes can't reach the network, use `--offline` and then
  `wandb sync` the run directory from the login node.
- **Never put `WANDB_API_KEY=...`, or any other token, in a script, a
  `Makefile`, `.env`, `.env.example`, or a notebook.** A previous cohort on
  this project committed a live W&B key into a tracked sbatch script; deleting
  the line does not remove it from git history, and the key had to be revoked.
  If you do leak one, say so immediately and revoke it — that is a five-minute
  problem if you speak up and a much larger one if you don't.

The same goes for data: the dataset lives on project storage, not in the repo.
See [`../data/README.md`](../data/README.md) and `../DataPolicy.md`.

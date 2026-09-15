# Getting started

Work through this in order. It ends with a real training job running on a GPU,
which is the point at which you can start doing the project rather than setting
up for it.

## Before week 2: read

1. The [NuGraph2 paper](https://arxiv.org/abs/2403.11872). This is the network
   you will be modifying. You do not need to follow every detail, but you
   should come away knowing what the graph represents and what the network
   predicts.
2. The [NuGraph docs](https://nugraph.readthedocs.io/), particularly the
   training-and-inference page.
3. [`nugraph-orientation.md`](nugraph-orientation.md) in this directory — the
   map of which file does what, and the list of questions to ask your mentor.
4. Skim [`cluster.md`](cluster.md). You will come back to it.

## 1. Accounts and access

- [ ] A DSI cluster account, and SSH set up per the
      [clinic guide](https://github.com/dsi-clinic/the-clinic/blob/main/tutorials/ssh_github_cluster.md).
      Check with `ssh fe.ds`.
- [ ] Read access to `/net/projects2/fermi2526/`. Check with
      `ls /net/projects2/fermi2526/`. If that fails, this is a Unix group
      membership DSI techstaff must grant — ask now, it is not instant.
- [ ] Write access to [dsi-rse/NuGraph](https://github.com/dsi-rse/NuGraph),
      since that is where your NuGraph changes get pushed. Check with
      `gh repo view dsi-rse/NuGraph --json viewerPermission`.
- [ ] GitHub SSH working from the cluster: `ssh -T git@github.com`.

## 2. Clone, on the cluster

Clone into the project directory, **not** your home directory — home is capped
at 20–50 GB and is private to you.

```bash
ssh fe.ds
mkdir -p /net/projects2/fermi2526/$USER
cd /net/projects2/fermi2526/$USER
git clone --recurse-submodules https://github.com/dsi-rse/clinic-2026-fermi-neutrino.git
cd clinic-2026-fermi-neutrino
```

If you already cloned without `--recurse-submodules`, `external/nugraph` will
be empty; fix it with `make submodules`.

The submodule URLs are HTTPS so that a fresh clone works with no setup. If you
prefer to push over SSH, tell git once and it applies everywhere:

```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

## 3. Build the environment

```bash
export TMPDIR=/net/scratch/$USER/tmp && mkdir -p $TMPDIR   # home quota is too small
make env
```

This takes a while — it resolves NuGraph's full GPU stack (torch, PyG, cuML,
MPI-enabled h5py) from conda. Install micromamba first if you haven't; see
[`cluster.md`](cluster.md).

Then, in every new shell, before you run anything:

```bash
source env.sh
```

That activates the environment and exports `NUGRAPH_DIR`, `NUGRAPH_DATA` and
`NUGRAPH_LOG`, which is all NuGraph needs to find itself.

## 4. Check it works

```bash
# the packages resolve to the submodule, not some installed copy
python -c "import nugraph, pynuml; print(nugraph.__file__)"

# the dataset is readable
python -c "
import h5py, os
p = os.path.expandvars('\$NUGRAPH_DATA/uboone-opendata/'
                       'uboone-opendata-19be46d89d0f22f5a78641d724c1fedd.gnn.h5')
with h5py.File(p) as f:
    print(p); print(sorted(f.keys()))
"

# our own helpers import
python -c "from utils.settings import NUGRAPH_DATA, NUGRAPH_LOG; print(NUGRAPH_DATA, NUGRAPH_LOG)"
```

If the dataset path is wrong, fix `NUGRAPH_DATA` in `env.sh` rather than
working around it in a script — it is deliberately the only place that path is
written down.

## 5. Run something

```bash
make smoke
squeue -u $USER
tail -f logs/slurm-nugraph-train-*.out
```

That submits one epoch over two batches to the short `dev` queue. When it
finishes, look at the metrics:

```bash
make tensorboard PORT=6123      # then forward the port; see cluster.md
```

Once the smoke test passes, run the control comparison and you are off:

```bash
./slurm/submit-sweep.sh baseline
```

See [`../slurm/README.md`](../slurm/README.md) for everything about submitting,
monitoring and sweeping.

## Working on NuGraph itself

`external/nugraph` is a git repository inside a git repository. Two rules keep
this from going wrong:

**1. Commit inside the submodule first.** Your NuGraph edits belong to the
`dsi-rse/NuGraph` repo, on the `clinic-2026` branch:

```bash
cd external/nugraph
git status                       # should say "On branch clinic-2026"
git add -p && git commit -m "..." && git push
```

If `git status` says `HEAD detached`, run `git checkout clinic-2026` before you
do anything else. A detached HEAD is how submodule work gets lost.

**2. Then record the new pointer in this repo.** The outer repo tracks *which
commit* of the submodule you are using:

```bash
cd ../..                         # back to the repo root
git add external/nugraph
git commit -m "bump nugraph to <short description>"
```

Reviewers of this repo see a one-line commit-hash change; the actual diff is
reviewed in a pull request on `dsi-rse/NuGraph`. Open those against
`clinic-2026`, not `main`.

To pull in upstream changes:

```bash
cd external/nugraph
git fetch upstream
git merge upstream/main          # or rebase, if your branch is tidy
```

## Conventions

- Code style is enforced by `ruff` via `pre-commit` (`make lint`). `make env`
  installs the hook. `external/nugraph` is excluded — upstream has its own
  conventions and reformatting it would make every merge a conflict.
- Notebooks: `make env` installs `nbstripout`, which strips output on commit so
  notebooks diff readably. Keep exploratory notebooks in `notebooks/`, and keep
  anything you want to reuse in `src/utils/` where it can be tested.
- Never commit data, checkpoints, logs or figures; `.gitignore` covers the
  usual suspects but it is not a substitute for looking at `git status`.
- No tokens or keys anywhere in the repository, ever. See the end of
  [`cluster.md`](cluster.md) for why this is in bold.
- The clinic's general expectations are in
  [coding-standards](https://github.com/dsi-clinic/the-clinic/blob/main/coding-standards/coding-standards.md).

## Still to be settled

- [ ] **Shared conda environment.** One is supposed to exist under
      `/net/projects2/fermi2526/`. When you find it, set `NUGRAPH_ENV` in
      `env.sh` to its prefix and delete the `TODO(mentor)` note there, so the
      team stops building individual copies.
- [ ] **Dataset location.** `env.sh` assumes
      `/net/projects2/fermi2526/data/uboone-opendata/...`. Confirm against
      what is actually there and update `NUGRAPH_DATA` plus
      [`../data/README.md`](../data/README.md).
- [ ] **Figure of merit.** See the mentor questions at the end of
      [`nugraph-orientation.md`](nugraph-orientation.md). Until that is
      answered, the sweep configs in `config/sweeps/` are placeholders.

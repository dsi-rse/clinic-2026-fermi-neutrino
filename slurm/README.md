# Running on the DSI cluster with SLURM

All real computation for this project happens in SLURM jobs on the DSI cluster.
Read [`../docs/cluster.md`](../docs/cluster.md) first if you have not used the
cluster before, and never run training on the login node.

Every script here sources [`../env.sh`](../env.sh), which activates the conda
environment and exports the three variables NuGraph needs (`NUGRAPH_DIR`,
`NUGRAPH_DATA`, `NUGRAPH_LOG`). You do not need to set anything up inside the
job scripts themselves.

## The scripts

| Script | What it does |
|---|---|
| `train.sbatch` | One training run on one GPU. Extra arguments pass straight through to `external/nugraph/scripts/train.py`. |
| `train-sweep.sbatch` | A job array: one array task per line of `../config/sweeps/<name>.txt`. Not meant to be called directly. |
| `submit-sweep.sh` | Submits a sweep, working out the `--array` range from the config file. **Use this one.** |
| `test.sbatch` | Inference with a trained checkpoint over the test split, written to an HDF5 file. |
| `interactive.sh` | An interactive GPU shell for debugging and smoke tests. |

## A first run

Start with a two-minute smoke test on the short `dev` queue, to prove the
environment and the data path work before you spend GPU-hours:

```bash
make smoke
```

which is just:

```bash
sbatch --partition=dev --time=0:30:00 slurm/train.sbatch \
    --name smoke --semantic --filter \
    --epochs 1 --limit_train_batches 2 --limit_val_batches 2
```

Then a real single run:

```bash
sbatch slurm/train.sbatch --name baseline --semantic --filter
sbatch slurm/train.sbatch --name optical --semantic --filter --optical
```

## Sweeps

A sweep is a text file with one set of `train.py` flags per line. Each line
becomes one array task, and therefore one GPU job:

```bash
./slurm/submit-sweep.sh baseline
./slurm/submit-sweep.sh optical-width --array-throttle 4
```

`--array-throttle N` caps how many tasks run at once. Use it. The `general`
partition is shared with the whole DSI, and queueing twenty GPU jobs at once is
how you become unpopular. See [`../config/sweeps/README.md`](../config/sweeps/README.md)
for the file format.

Each task logs to `$NUGRAPH_LOG/<sweep-name>/task-NNN/`, so the sweep name and
the array index are enough to find any run afterwards. `utils.runs` can load
those metrics back into a DataFrame for comparison.

## Monitoring

```bash
squeue -u "$USER"                    # your queued and running jobs
squeue -u "$USER" -t PENDING -o '%.10i %.9P %.20j %.8T %.10M %R'   # why is it pending?
scancel <jobid>                      # cancel one job
scancel <jobid>_<taskid>             # cancel one array task
scancel -u "$USER"                   # cancel everything (careful)
sacct -j <jobid> --format=JobID,JobName,State,Elapsed,MaxRSS,ExitCode
tail -f logs/slurm-nugraph-train-<jobid>.out
```

Job output lands in `logs/`, which is gitignored. `--open-mode=append` means a
requeued job appends to the same file rather than truncating it, so you keep the
history across a requeue.

## Requeueing, and why `--signal=SIGUSR1@90` matters

`train.sbatch` sets both `--signal=SIGUSR1@90` and `--requeue`. Ninety seconds
before SLURM kills the job at its wall-clock limit, it sends `SIGUSR1`;
PyTorch Lightning's `SLURMEnvironment` plugin — which
`external/nugraph/scripts/train.py` already installs — catches that, writes a
checkpoint, and resubmits the job so training picks up where it left off. This
is how an 80-epoch training survives a 12-hour queue limit. Do not remove
either directive.

## Resource choices, and what to try if things are slow

The defaults (`--cpus-per-task=16 --mem-per-cpu=16G`, i.e. 256 GB, one GPU) are
what a previous cohort found workable on this dataset. Two things worth
measuring rather than assuming:

- **`--num-workers`.** NuGraph's data module defaults to 8 but warns that
  worker processes *slow down* this HDF5 loader. Try `--num-workers 0` and
  compare epoch times.
- **`--precision bf16-mixed`.** The A40s have Tensor Cores. Mixed precision may
  buy you a meaningful speedup; check it does not move your metrics first.

If a job dies with CUDA out-of-memory, the levers are `--batch-size` (default
64) and dropping `--no-checkpointing` so gradient checkpointing stays on.

## An alternative: submitit

The clinic's other documented route to SLURM is
[submitit](https://github.com/dsi-clinic/the-clinic/blob/main/tutorials/submit-it.md),
which submits jobs from Python. We use plain `sbatch` here instead, because
NuGraph already has a complete command-line interface and its own
`SLURMEnvironment` requeue handling — wrapping that in submitit would mean
fighting both. If you have a use case that genuinely needs Python-side job
orchestration, the tutorial above is the place to start.

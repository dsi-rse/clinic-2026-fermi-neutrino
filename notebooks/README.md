# Notebooks

Exploratory and analysis notebooks. Anything you want to reuse or test belongs
in `src/utils/` instead, imported from here.

`make env` installs [`nbstripout`](https://github.com/kynan/nbstripout), which
strips cell output on commit so that notebooks diff readably and don't bloat
the repository. Commit the code, not the pictures.

## Start from the ones upstream already wrote

NuGraph ships notebooks that are interactive twins of the `scripts/`, in
`external/nugraph/notebooks/`:

| Notebook | What it does |
|---|---|
| `train.ipynb` | Build the data module and model by hand and train interactively — the best way to understand the pieces |
| `plot.ipynb` | Load a checkpoint and draw event displays with predictions overlaid |
| `test.ipynb` | ROC curves and score distributions per semantic class |
| `evaluate.ipynb` | Offline pandas analysis of a `scripts/test.py` inference dump: per-hit efficiency and purity |
| `process.ipynb` | Step through graph construction and truth labelling one event at a time |
| `inference-time.ipynb` | Throughput vs. batch size |

Copy one here before you change it, rather than editing it in place inside the
submodule — the submodule is for NuGraph changes you intend to contribute back.

## Running a notebook

Notebook kernels are real compute: get a compute node first.

```bash
./slurm/interactive.sh            # interactive GPU shell on the dev queue
source env.sh
```

then point VS Code at that node (see the
[clinic Slurm tutorial](https://github.com/dsi-clinic/the-clinic/blob/main/tutorials/slurm.md)).
`make env` installs an `ipykernel` in the project environment.

Two conventions worth copying from the upstream notebooks:

```python
%load_ext autoreload
%autoreload 2
```

so your edits in `external/nugraph` take effect without restarting, and

```python
import nugraph as ng
ng.util.setup_env()      # prints the NUGRAPH_* paths it resolved
```

as a first cell, so a notebook that is reading the wrong dataset says so.

## Comparing runs

To pull metrics from a finished sweep into a DataFrame rather than clicking
through TensorBoard:

```python
from utils.runs import list_runs, summarize_runs

runs = list_runs("optical-width")
summarize_runs(runs)
```

See `src/utils/runs.py`.

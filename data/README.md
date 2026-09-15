# Data

**The dataset is not in this repository and must not be put in it.** It lives on
the DSI cluster's shared project storage, where every team member and every
batch job can read the same copy.

## Where it is

```
$NUGRAPH_DATA = /net/projects2/fermi2526/data
$NUGRAPH_DATA/uboone-opendata/uboone-opendata-19be46d89d0f22f5a78641d724c1fedd.gnn.h5
```

That filename is NuGraph's built-in default (`DEFAULT_DATA` in
`external/nugraph/nugraph/nugraph/data/data_module.py`), which is why
`train.py` works with no `--data-path` at all once `NUGRAPH_DATA` is exported.
The hex string is a content digest of the file, so the name pins one exact
dataset — if someone hands you a differently-hashed file, it is different data
and your results are not comparable.

> **To verify:** confirm the path and filename above against what is actually
> in `/net/projects2/fermi2526/`, and check whether the file includes the
> optical hierarchy (`ophit`, `pmt`, `flash` node types) that this project
> needs. Update this file and `NUGRAPH_DATA` in `env.sh` if it differs.

## The two file types

| Suffix | What it is |
|---|---|
| `*.evt.h5` | **Event file.** Tabular detector output: `event_table`, `hit_table`, `spacepoint_table`, `particle_table`, `edep_table`, and for the optical system `ophit_table`, `opflash_table`, `opflashsumpe_table`. Not what you train on. |
| `*.gnn.h5` | **Graph file.** The processed PyTorch-Geometric dataset produced from an event file by `pynuml`. This is what `train.py` reads. |

Turning the first into the second is `external/nugraph/scripts/process.py`
(plus `merge.py`) — an MPI job, not something you need unless the graph file
has to be rebuilt. See
[`../docs/nugraph-orientation.md`](../docs/nugraph-orientation.md).

## What is inside the graph file

The graph file is self-describing, which is what makes runs comparable across
people and machines:

| Key | Contents |
|---|---|
| `dataset/<graph-name>` | one event graph each, named `r<run>_sr<subrun>_evt<event>` |
| `planes`, `semantic_classes`, `event_classes` | label metadata |
| `samples/{train,validation,test}` | **the split, frozen in the file** — everyone uses the same one |
| `norm/hit` | input feature normalisations |
| `datasize/train` | per-graph sizes, used by the batch-balancing sampler |
| `gen` | graph schema generation, for backward compatibility |

Have a look for yourself:

```python
import h5py, os
from utils.settings import DEFAULT_DATASET
with h5py.File(DEFAULT_DATASET) as f:
    print(sorted(f.keys()))
    print("graphs:", len(f["dataset"]))
    print("semantic classes:", f["semantic_classes"].asstr()[()].tolist())
```

## Provenance

The sample is from the **MicroBooNE open data release** — real and simulated
data from a liquid argon time projection chamber at Fermilab, published for
public use — processed into graphs with `pynuml`. The open-data release is the
reason this project's results can be published openly.

## This directory

`data/` is for small, committed things: notes, a handful of example values, a
label mapping. `.gitignore` blocks `*.h5`, `*.root`, `*.parquet`, `*.npz` and
friends anywhere in the repo, so an accidental `cp` of the dataset will be
refused rather than silently staged. Do not work around that.

Everything you generate — checkpoints, inference dumps, TensorBoard logs —
belongs under `$NUGRAPH_LOG` on project storage, not here.

Project data and code handling policy: [`../DataPolicy.md`](../DataPolicy.md).

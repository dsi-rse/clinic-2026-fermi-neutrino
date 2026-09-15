# Finding your way around NuGraph

This is a map, not a plan. It tells you where things are so you can spend your
time on the physics and the modelling rather than on archaeology. What to
change, and why, is the project — work that out with your mentor.

Everything below is inside the `external/nugraph` submodule. That submodule is
[dsi-rse/NuGraph](https://github.com/dsi-rse/NuGraph), a fork of
[nugraph/nugraph](https://github.com/nugraph/nugraph), checked out on the
`clinic-2026` branch. **Your changes to NuGraph go there, on that branch, and
get committed and pushed from inside `external/nugraph`.** See
[`onboarding.md`](onboarding.md) for how submodule commits work.

Background reading: the NuGraph2 paper, [arXiv:2403.11872](https://arxiv.org/abs/2403.11872),
and the [NuGraph docs](https://nugraph.readthedocs.io/).

## The two packages

| Path | What it is |
|---|---|
| `external/nugraph/nugraph/` | The GNN itself: model architecture, data loader, losses |
| `external/nugraph/pynuml/` | Turns raw detector event files into graph datasets; truth labelling; plotting |
| `external/nugraph/scripts/` | Command-line entry points: `train.py`, `test.py`, `process.py`, `plot.py` |
| `external/nugraph/notebooks/` | Interactive twins of those scripts |

You will mostly live in `nugraph/`. You only need `pynuml/` if the dataset has
to be rebuilt (see "If the data needs reprocessing" below).

## The graph, in one paragraph

A NuGraph3 event is a *heterogeneous* graph. LArTPC wire hits are `hit` nodes,
grouped into 3D `sp` (spacepoint / "nexus") nodes, all rolled up into a single
`evt` (interaction) node. The optical system adds three more node types:
`ophit` (a pulse on one PMT), `pmt` (per-PMT summed photoelectrons), and
`flash` (a coincident group of pulses across PMTs). Message passing runs for
`--num-iters` rounds over these node types along typed edges.

**The question this project is about lives exactly at the boundary between
those two hierarchies.**

## Where the LArTPC ↔ PMT information flow is implemented

`nugraph/nugraph/models/nugraph3/optical.py` — read this file first.

- **`OpticalEncoder`** embeds the three optical node types. Note the comment
  `# hardcode optical features pending redesign`: the input widths are literal
  `8`, `4` and `10` for ophit / pmt / flash. That is a known rough edge.
- **`NuGraphOptical`** is the message-passing engine for the optical system.
  Its `forward` runs a fixed sequence:

  ```
  ophit -> pmt -> [sp] -> [pmt<->pmt] -> flash -> evt -> flash -> pmt -> [pmt<->pmt] -> [sp] -> ophit
  ```

  The bracketed steps are the **cross-detector links**: `pmt_to_nexus` and
  `nexus_to_pmt` are the only paths by which optical information reaches the
  LArTPC spacepoints and vice versa, and both are guarded by
  `if "edge_index" in pmt_sp_edges and ... .numel() > 0` — so if the dataset
  carries no `("sp", "knn", "pmt")` edges, those steps silently do nothing.
  Check that they are firing before you conclude a configuration "didn't help".

`nugraph/nugraph/models/nugraph3/core.py` — **`NuGraphBlock`**, the single
message-passing primitive every step above is built from: edge attention from
concatenated source+target features, softmax aggregation, two-layer Mish MLP.
If you want to change *how* messages flow rather than *where*, this is the
class.

`nugraph/nugraph/models/nugraph3/transform.py` — where the optical graph
connectivity is *constructed* at load time, not read from the file. Around
line 95 it builds `("pmt", "knn", "pmt")` edges with a hardcoded
`knn = min(3, n_pmt - 1)`. Graph connectivity is a hyperparameter too.

`nugraph/nugraph/models/nugraph3/nugraph3.py` — the `LightningModule` that ties
it together. `NuGraph3.__init__` lists every hyperparameter with its default;
`use_optical` gates the whole optical branch; `add_model_args` and `from_args`
are the argparse bridge, so this is where you add a new flag if you need one.

## Local (node) vs global (graph) performance

The pitchbook asks you to assess performance "at local (node) and global
(graph) levels". That maps onto the decoders in
`nugraph/nugraph/models/nugraph3/decoders/`:

| Decoder | Flag | Level | Predicts |
|---|---|---|---|
| `semantic.py` | `--semantic` | node (per hit) | particle type: MIP, HIP, shower, michel, diffuse |
| `filter.py` | `--filter` | node (per hit) | is this hit background (cosmic) or signal |
| `spacepoint.py` | `--spacepoint` | node (per spacepoint) | true 3D position |
| `instance.py` | `--instance` | node → object | clustering hits into particles |
| `event.py` | `--event` | **graph** (per interaction) | event class: numu / nue / nc |
| `vertex.py` | `--vertex` | **graph** (per interaction) | interaction vertex position |

Each decoder owns its own `torchmetrics` objects — `semantic.py` for instance
carries `Recall`, `Precision`, `F1Score` and a `ConfusionMatrix` — and logs
them to TensorBoard. `utils.runs` will load all of those back into a DataFrame
for you; choosing which are the figure of merit is yours to decide.

A reasonable expectation is that optical information helps the **graph-level**
heads (`--event`, `--vertex`) more than the per-hit ones, since a PMT flash
constrains the interaction as a whole rather than an individual wire hit. That
is a hypothesis to test, not a result.

## The data

`nugraph/nugraph/data/data_module.py` is the loader. Two things worth knowing:

- `DEFAULT_DATA` is the string
  `"$NUGRAPH_DATA/uboone-opendata/uboone-opendata-19be46d89d0f22f5a78641d724c1fedd.gnn.h5"`,
  and `--data-path` defaults to the literal `"auto"`, which resolves to it.
  The variable is expanded when the file is opened, so the same command works
  on any machine with `NUGRAPH_DATA` set. Don't hardcode absolute paths.
- The graph file is **self-describing**: `planes`, `semantic_classes`,
  `event_classes`, the frozen `samples/{train,validation,test}` splits, the
  feature normalisations `norm/hit`, and a schema-generation integer `gen` all
  live inside the HDF5. The train/val/test split is fixed in the file, so every
  run and every team member is comparing like with like. If the loader exits
  with "sample splits not found in file", the file was built without them —
  that is a data problem, not a code problem.

See [`../data/README.md`](../data/README.md) for where the file lives.

## Flags you will actually use

Full list: `source env.sh && python external/nugraph/scripts/train.py --help`.

**Which decoders to train** (at least one is required):
`--semantic --filter --event --vertex --instance --spacepoint`

**Optical system:** `--optical` (enable it at all),
`--ophit-features` (128), `--pmt-features` (64), `--flash-features` (32)

**TPC widths:** `--hit-feats` (128), `--nexus-feats` (32),
`--interaction-feats` (32), `--num-iters` (5)

**Optimisation:** `--learning-rate` (1e-3), `--epochs` (80),
`--batch-size` (64), `--no-lr-scheduler` (disables OneCycleLR),
`--precision 32|bf16-mixed`

**Bookkeeping:** `--name`, `--version` (together these decide where under
`$NUGRAPH_LOG` the run lands), `--logger tensorboard|wandb`

**Debugging:** `--limit_train_batches`, `--limit_val_batches`,
`--num-workers`, `--profiler`

## If the data needs reprocessing

The optical hierarchy only exists in a graph file if it was built with it.
`external/nugraph/scripts/process.py` takes `--optical`, and the graph
construction itself is in
`external/nugraph/pynuml/pynuml/process/hitgraph.py` (that is where PMT
positions and `pmt`–`pmt` edges come from). Reprocessing is an MPI job over a
`.evt.h5` event file followed by a merge step — it is a bigger undertaking than
training, so **confirm with your mentor whether the dataset you have already
carries the optical hierarchy before going down this road.** Check first:

```python
import h5py, os
with h5py.File(os.path.expandvars("$NUGRAPH_DATA/uboone-opendata/"
                                  "uboone-opendata-19be46d89d0f22f5a78641d724c1fedd.gnn.h5")) as f:
    print(list(f.keys()))
```

## Questions to take to your mentor in week 1 or 2

Giuseppe is a NuGraph co-author, so these are cheap for him to answer and
expensive for you to guess at:

1. Which dataset file should we train on, and does it already include the
   optical (`ophit`/`pmt`/`flash`) hierarchy and the `sp`–`pmt` edges?
2. Which decoder head is the figure of merit for "tightening the overall
   measurement"? What number would count as an improvement?
3. What is the published or current-best baseline we should be measuring
   against, and is there a checkpoint for it we can start from?
4. Which parts of `optical.py` have already been explored upstream, so we
   don't rediscover a known answer? What does "pending redesign" refer to?
5. Are there constraints from the physics on the PMT graph connectivity — is
   k-nearest-neighbour over PMT positions the right structure at all?

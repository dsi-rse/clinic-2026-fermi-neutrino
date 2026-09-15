"""Load NuGraph training metrics off disk so that runs can be compared.

NuGraph logs to TensorBoard under ``$NUGRAPH_LOG/<name>/<version>/``, which is
convenient while a job is running and awkward when you want to compare twenty
sweep runs at once.  These helpers turn those event files into DataFrames.

This module is *plumbing only*.  It will hand you every scalar NuGraph logged;
deciding which of them is the figure of merit for this project -- and what
"local (node) level" and "global (graph) level" performance should mean in
practice -- is the actual work.  Talk to your mentor before settling on one.

Typical use in a notebook::

    from utils.runs import list_runs, summarize_runs
    summarize_runs(list_runs("optical-width"))
"""

from pathlib import Path

import pandas as pd

from utils.settings import NUGRAPH_LOG


def list_runs(name: str | None = None, log_dir: Path | None = None) -> list[Path]:
    """List TensorBoard run directories under the logging root.

    A NuGraph run directory is ``<log_dir>/<name>/<version>`` -- ``name`` is
    the ``--name`` passed to ``train.py`` (the sweep name, for sweeps) and
    ``version`` is its ``--version`` (``task-NNN`` for sweeps).

    Args:
        name: Only return runs under this ``--name``. All names if omitted.
        log_dir: Logging root. Defaults to ``$NUGRAPH_LOG``.

    Returns:
        Sorted list of run directories that contain at least one event file.
    """
    root = Path(log_dir) if log_dir is not None else NUGRAPH_LOG
    pattern = f"{name}/*" if name else "*/*"
    return sorted(
        d
        for d in root.glob(pattern)
        if d.is_dir() and any(d.glob("events.out.tfevents.*"))
    )


def load_scalars(run_dir: Path) -> pd.DataFrame:
    """Load every scalar logged in one run into a tidy DataFrame.

    Args:
        run_dir: A single run directory, as returned by :func:`list_runs`.

    Returns:
        DataFrame with columns ``name``, ``version``, ``tag``, ``step``,
        ``wall_time`` and ``value``. One row per logged scalar point. NuGraph
        logs tags such as ``loss/train``, ``loss/val`` and per-decoder metrics;
        run this on a real run to see the full list rather than guessing.
    """
    # Imported lazily: tensorboard comes from the conda environment on the
    # cluster and is not needed to import this module (or to run CI).
    from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

    run_dir = Path(run_dir)
    accumulator = EventAccumulator(str(run_dir), size_guidance={"scalars": 0})
    accumulator.Reload()

    rows = [
        {
            "name": run_dir.parent.name,
            "version": run_dir.name,
            "tag": tag,
            "step": event.step,
            "wall_time": event.wall_time,
            "value": event.value,
        }
        for tag in accumulator.Tags()["scalars"]
        for event in accumulator.Scalars(tag)
    ]
    return pd.DataFrame(
        rows, columns=["name", "version", "tag", "step", "wall_time", "value"]
    )


def summarize_runs(
    run_dirs: list[Path], minimize: tuple[str, ...] = ("loss",)
) -> pd.DataFrame:
    """Reduce a set of runs to one row per run and one column per metric.

    For each scalar tag, keeps the *best* value seen during the run: the
    minimum for tags whose name contains any of ``minimize``, the maximum
    otherwise. That heuristic is a convenience for eyeballing a sweep, not a
    statement about which metric matters -- check it does the right thing for
    the tags you care about.

    Args:
        run_dirs: Run directories, as returned by :func:`list_runs`.
        minimize: Substrings marking tags where lower is better.

    Returns:
        DataFrame indexed by (``name``, ``version``), one column per tag.
    """
    frames = [load_scalars(d) for d in run_dirs]
    frames = [f for f in frames if not f.empty]
    if not frames:
        return pd.DataFrame()

    scalars = pd.concat(frames, ignore_index=True)
    lower_is_better = scalars["tag"].str.contains("|".join(minimize), case=False)
    best = (
        scalars.assign(
            signed=scalars["value"].where(~lower_is_better, -scalars["value"])
        )
        .groupby(["name", "version", "tag"])["signed"]
        .max()
        .reset_index()
    )
    best["value"] = best["signed"].abs()
    return best.pivot_table(index=["name", "version"], columns="tag", values="value")

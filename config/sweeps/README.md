# Sweep configurations

One file per sweep. One set of `train.py` flags per line. Blank lines and
lines starting with `#` are ignored. Submit with:

```bash
./slurm/submit-sweep.sh <name-of-file-without-.txt>
```

Line *N* of the file becomes array task *N*, which trains with
`--name <sweep> --version task-NNN` and therefore logs to
`$NUGRAPH_LOG/<sweep>/task-NNN/`. Keep a comment above each line saying what
the line is testing — six months from now the flags alone will not tell you.

To see every available flag:

```bash
source env.sh
python external/nugraph/scripts/train.py --help
```

## Designing a sweep

Some ground rules that will save you GPU-hours:

- **Change one thing at a time.** A line that differs from the baseline in
  three flags tells you nothing about which of the three mattered.
- **Always include the baseline in the sweep**, as line 1. Runs from different
  sweeps are not always comparable (different code, different data version);
  runs within one sweep are.
- **Check the cost before submitting.** `N` lines means `N` GPU jobs. At ~12 h
  each, a 20-line sweep is 10 GPU-days of a shared partition. Use
  `--array-throttle`, and consider `--epochs` smaller for a first scan.
- **Agree the grid with your mentor before running it.** Giuseppe knows which
  knobs have already been explored upstream, which will save you from
  rediscovering a known result.

## The files here are placeholders

`baseline.txt` and `optical-width.txt` exist to show the format and to give you
something to run on day one. They are **not** the sweep this project needs —
working that out is the project. Replace them.

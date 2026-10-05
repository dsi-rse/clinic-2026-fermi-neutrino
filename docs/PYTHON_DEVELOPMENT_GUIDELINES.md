# Python Development Guidelines

## Environment management
- This project is designed to run on the DSI cluster.
- Use micromamba to build and manage conda environments.
  - `make env` builds the environment; `source env.sh` activates it (see docs/onboarding.md).

## Repo structure
- Core Python code for this project lives in src/utils/ and is imported as `utils`.
- NuGraph itself lives in the external/nugraph git submodule. Only change it for fixes that are intended to be contributed back upstream.

### Runnable Python scripts
- Training and testing run NuGraph's own scripts (external/nugraph/scripts/*.py) through the Slurm batch scripts in slurm/ (see slurm/README.md).
- New project-specific runnable scripts should use argparse.
- Core functionality that is needed for runnable scripts should be imported from `utils`.
- All scripts should be documented in README.md.
- Scripts that users and developers may have to run regularly should be runnable via a `make` command, specified in the Makefile.

### Python notebooks
- Python notebooks live in notebooks/.
- Core functionality that is needed for notebooks should be imported from `utils`.
- To modify one of NuGraph's notebooks (external/nugraph/notebooks/), copy it into notebooks/ first rather than editing it inside the submodule.

### Data
- Data should be read from and written to the directory specified in settings.DATA_DIR (src/utils/settings.py).
  - DATA_DIR should have a documented and well-organized structure that clearly distinguishes different types of files.
  - Runnable scripts can take data input and output paths as arguments, but should have defaults that are standard locations in DATA_DIR.

## Code quality & conventions
- Code should follow the standards described here: https://clinic.ds.uchicago.edu/coding-standards/coding-standards.html.
- All code must pass the [`ruff`](https://docs.astral.sh/ruff/) rules as defined in pyproject.toml (external/ is excluded).
  - `ruff` should be run before each commit via [`pre-commit`](https://pre-commit.com/). If it fails, the commit will be blocked and the user will be shown what needs to be changed.
  - `make env` installs the `pre-commit` hook. To check for errors locally, run `make lint` (equivalent to `pre-commit run --all-files`).
- Run the tests with `make test`.

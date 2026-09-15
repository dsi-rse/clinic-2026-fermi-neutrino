"""Settings for the Clinic 2026 Fermi Neutrino project.

The authoritative source for these paths is ``env.sh`` at the repository root,
which every SLURM script sources.  This module reads the same environment
variables so that notebooks and Python code see the same values, and falls back
to repository-relative defaults when a variable is unset (e.g. when you are
poking at the code on your laptop rather than on the cluster).
"""

import os
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).parent.parent.parent


def resolve_path(path: Path) -> Path:
    """Resolve a path to an absolute path.

    If the path is not absolute, it is assumed to be relative to the project root.
    """
    path = path.expanduser()
    if not path.is_absolute():
        path = PROJECT_ROOT / path
    return path.resolve()


# Load environment variables from .env file if it exists
load_dotenv()

# Set the data directory
DATA_DIR = resolve_path(Path(os.environ["DATA_DIR"]))

# Shared project allocation on the DSI cluster.  See docs/cluster.md.
FERMI_PROJECT_DIR = Path(
    os.environ.get("FERMI_PROJECT_DIR", "/net/projects2/fermi2526")
)

# NuGraph reads exactly these three environment variables; see
# external/nugraph/nugraph/nugraph/util/scriptutils.py.  NUGRAPH_DIR must be a
# directory (the repository root of the submodule), not a script.
NUGRAPH_DIR = resolve_path(
    Path(os.environ.get("NUGRAPH_DIR", PROJECT_ROOT / "external" / "nugraph"))
)
NUGRAPH_DATA = Path(
    os.environ.get("NUGRAPH_DATA", FERMI_PROJECT_DIR / "data")
).expanduser()
NUGRAPH_LOG = Path(
    os.environ.get(
        "NUGRAPH_LOG", FERMI_PROJECT_DIR / "logs" / os.environ.get("USER", "")
    )
).expanduser()

# The graph dataset NuGraph trains on by default.  The hash in the filename is
# the content digest of the file, so this name pins an exact dataset -- see
# DEFAULT_DATA in external/nugraph/nugraph/nugraph/data/data_module.py.
DEFAULT_DATASET = (
    NUGRAPH_DATA
    / "uboone-opendata"
    / "uboone-opendata-19be46d89d0f22f5a78641d724c1fedd.gnn.h5"
)


def check_submodule() -> Path:
    """Check that the nugraph submodule has been checked out, and return its path.

    Raises:
        FileNotFoundError: if the submodule directory is empty.
    """
    if not (NUGRAPH_DIR / "nugraph" / "nugraph" / "__init__.py").exists():
        raise FileNotFoundError(
            f"The nugraph submodule at {NUGRAPH_DIR} is not checked out. Run:\n"
            "    git submodule update --init --recursive"
        )
    return NUGRAPH_DIR

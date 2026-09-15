"""Check that the project's path plumbing honours the environment.

These tests deliberately avoid importing torch or nugraph, so they run in CI
without the GPU stack. They exist to catch the failure mode that bit previous
cohorts: a path variable silently pointing somewhere wrong.
"""

import importlib
from pathlib import Path
from types import ModuleType

import pytest


def _reload_settings(monkeypatch: pytest.MonkeyPatch, **env: str) -> ModuleType:
    """Import utils.settings with a controlled environment."""
    monkeypatch.setenv("DATA_DIR", env.pop("DATA_DIR", "./data"))
    for key in ("FERMI_PROJECT_DIR", "NUGRAPH_DIR", "NUGRAPH_DATA", "NUGRAPH_LOG"):
        monkeypatch.delenv(key, raising=False)
    for key, value in env.items():
        monkeypatch.setenv(key, value)
    # load_dotenv() must not put a developer's local .env back on top of the
    # values we just set.
    monkeypatch.setattr("dotenv.load_dotenv", lambda *a, **k: False)
    import utils.settings

    return importlib.reload(utils.settings)


def test_defaults_are_repo_relative(monkeypatch: pytest.MonkeyPatch) -> None:
    """With nothing exported, NUGRAPH_DIR points at the submodule checkout."""
    settings = _reload_settings(monkeypatch)
    assert settings.NUGRAPH_DIR == settings.PROJECT_ROOT / "external" / "nugraph"
    assert settings.FERMI_PROJECT_DIR == Path("/net/projects2/fermi2526")


def test_environment_wins(monkeypatch: pytest.MonkeyPatch) -> None:
    """Exported values override the defaults, as env.sh relies on."""
    settings = _reload_settings(
        monkeypatch,
        NUGRAPH_DATA="/somewhere/else/data",
        NUGRAPH_LOG="/somewhere/else/logs",
    )
    assert settings.NUGRAPH_DATA == Path("/somewhere/else/data")
    assert settings.NUGRAPH_LOG == Path("/somewhere/else/logs")


def test_default_dataset_follows_nugraph_data(monkeypatch: pytest.MonkeyPatch) -> None:
    """The default dataset name matches DEFAULT_DATA in nugraph's data module."""
    settings = _reload_settings(monkeypatch, NUGRAPH_DATA="/data")
    assert settings.DEFAULT_DATASET == Path(
        "/data/uboone-opendata/"
        "uboone-opendata-19be46d89d0f22f5a78641d724c1fedd.gnn.h5"
    )


def test_resolve_path_makes_relative_paths_repo_relative(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """A relative path is interpreted against the repository root, not the cwd."""
    settings = _reload_settings(monkeypatch)
    assert settings.resolve_path(Path("data")) == settings.PROJECT_ROOT / "data"


def test_check_submodule_explains_how_to_fix_itself(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    """A missing submodule raises with the command that fixes it."""
    settings = _reload_settings(monkeypatch, NUGRAPH_DIR=str(tmp_path))
    with pytest.raises(FileNotFoundError, match="git submodule update --init"):
        settings.check_submodule()

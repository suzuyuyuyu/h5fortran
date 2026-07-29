"""HDF5 I/O layer (scheme-agnostic reader/writer)."""

from .reader import (
    read_scheme_version,
    read_series,
    read_series_glob,
    read_snapshot,
)
from .writer import write_snapshot

__all__ = [
    "read_scheme_version",
    "read_snapshot",
    "read_series",
    "read_series_glob",
    "write_snapshot",
]

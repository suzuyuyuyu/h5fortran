"""Intermediate model -> HDF5.

Primarily for producing test fixtures / sample data that exercise the full
pipeline. The production writer is the Fortran solver (MPI-IO); this Python
writer must therefore agree with the schemes on the exact layout, which it does
by delegating to the same :class:`~h5xdmf.schemes.base.Scheme` objects.
"""

from __future__ import annotations

import h5py

from ..model import Snapshot
from ..schemes import get_scheme


def write_snapshot(path: str, snapshot: Snapshot, *, scheme_version: int | None = None) -> None:
    """Write a fully-loaded :class:`Snapshot` to ``path``.

    ``scheme_version`` defaults to the snapshot's own; pass it explicitly to
    re-emit an existing snapshot under a different layout version.
    """
    version = scheme_version if scheme_version is not None else snapshot.scheme_version
    scheme = get_scheme(version)
    with h5py.File(path, "w") as h5:
        scheme.write_snapshot(h5, snapshot)

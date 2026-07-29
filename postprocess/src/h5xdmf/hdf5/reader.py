"""HDF5 -> intermediate model.

Scheme-agnostic: opens a file, reads the ``scheme_version`` root attribute,
resolves the matching :class:`~h5xdmf.schemes.base.Scheme`, and delegates.
"""

from __future__ import annotations

import glob as _glob
import os
from typing import Iterable, Optional

import h5py

from ..model import Snapshot, Series
from ..schemes import SCHEME_VERSION_ATTR, get_scheme
from .io import decode_attr


def read_scheme_version(h5: h5py.File) -> int:
    if SCHEME_VERSION_ATTR not in h5.attrs:
        raise KeyError(
            f"root attribute {SCHEME_VERSION_ATTR!r} not found in {h5.filename!r}; "
            "cannot determine HDF5 layout"
        )
    return int(decode_attr(h5.attrs[SCHEME_VERSION_ATTR]))


def read_snapshot(
    path: str,
    *,
    load_data: bool = False,
    source_file: Optional[str] = None,
) -> Snapshot:
    """Read one ``seqNNNNN.h5`` file into a :class:`Snapshot`.

    ``source_file`` is what the snapshot records as its origin (defaults to
    ``path``); the XDMF builder later rewrites it relative to the ``.xdmf``.
    ``load_data=False`` reads only metadata (shapes/dtypes/paths).
    """
    with h5py.File(path, "r") as h5:
        version = read_scheme_version(h5)
        scheme = get_scheme(version)
        snap = scheme.read_snapshot(
            h5, source_file=source_file or path, load_data=load_data
        )
    snap.name = os.path.splitext(os.path.basename(path))[0]
    return snap


def read_series(
    paths: Iterable[str],
    *,
    load_data: bool = False,
    sort_by_time: bool = False,
) -> Series:
    """Read many files into a temporal :class:`Series`.

    Files are kept in the given order unless ``sort_by_time`` is set, in which
    case they are ordered by the time stored in each file.
    """
    snaps = [read_snapshot(p, load_data=load_data) for p in paths]
    if sort_by_time:
        snaps.sort(key=lambda s: s.time)
    return Series(snapshots=snaps)


def read_series_glob(pattern: str, **kwargs) -> Series:
    """Convenience wrapper: expand a glob (sorted) and read the series."""
    paths = sorted(_glob.glob(pattern))
    if not paths:
        raise FileNotFoundError(f"no files matched {pattern!r}")
    return read_series(paths, **kwargs)

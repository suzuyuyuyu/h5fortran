"""Thin, scheme-agnostic helpers over h5py.

Kept deliberately small: opening files, reading root/group attributes with
sensible scalar decoding, and walking datasets. Any knowledge about *which*
paths mean *what* belongs in :mod:`h5xdmf.schemes`, not here.
"""

from __future__ import annotations

from typing import Any

import h5py
import numpy as np


def decode_attr(value: Any) -> Any:
    """Normalise an HDF5 attribute into a plain Python value.

    h5py returns bytes for strings and 0-d/1-element arrays for scalars written
    from Fortran; collapse those to ``str`` / Python scalars.
    """
    if isinstance(value, bytes):
        return value.decode("utf-8")
    if isinstance(value, np.ndarray):
        if value.shape == ():
            return value.item()
        if value.size == 1:
            return value.reshape(()).item()
        return [decode_attr(v) for v in value.tolist()]
    if isinstance(value, np.generic):
        return value.item()
    return value


def read_attrs(obj: h5py.HLObject) -> dict[str, Any]:
    """Read all attributes of a file/group/dataset as decoded Python values."""
    return {k: decode_attr(v) for k, v in obj.attrs.items()}


def has_path(h5: h5py.Group, path: str) -> bool:
    return path in h5


def dataset_at(h5: h5py.Group, path: str) -> h5py.Dataset:
    obj = h5[path]
    if not isinstance(obj, h5py.Dataset):
        raise TypeError(f"{path!r} is not a dataset")
    return obj

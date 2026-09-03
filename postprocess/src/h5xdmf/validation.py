"""Explicit validation of snapshot and manifest HDF5 schemas."""

from __future__ import annotations

from collections.abc import Iterable

import h5py

from .hdf5.reader import read_scheme_version
from .schemes import get_scheme


def validate_snapshot(path: str) -> None:
    """Validate one snapshot, raising ``ValueError`` with its first defect."""
    try:
        with h5py.File(path, "r") as h5:
            if "snapshot_complete" in h5.attrs and not bool(h5.attrs["snapshot_complete"]):
                raise ValueError("snapshot_complete marker is false")
            version = read_scheme_version(h5)
            scheme = get_scheme(version)
            snapshot = scheme.read_snapshot(h5, source_file=path, load_data=False)
            if not snapshot.mesh_blocks:
                raise ValueError("no mesh group containing geometry was found")
            for block in snapshot.mesh_blocks:
                nodes = h5[block.nodes_h5path]
                if nodes.ndim != 2 or nodes.shape[1] != 3:
                    raise ValueError(f"mesh {block.name!r}: geometry/nodes must have shape (N, 3)")
                if block.has_connectivity:
                    conn = h5[block.connectivity_h5path]
                    if conn.ndim != 2 or conn.shape[1] != block.nodes_per_element:
                        raise ValueError(
                            f"mesh {block.name!r}: connectivity width differs from nodes_per_element"
                        )
                for field in (*block.point_data, *block.cell_data):
                    expected = block.num_nodes if field.center.value == "Node" else block.num_elements
                    if not field.shape or field.shape[0] != expected:
                        raise ValueError(
                            f"mesh {block.name!r}, field {field.name!r}: entity count mismatch"
                        )
    except (KeyError, OSError, TypeError) as exc:
        raise ValueError(str(exc)) from exc


def validate_snapshots(paths: Iterable[str]) -> list[tuple[str, str]]:
    """Return ``(path, message)`` pairs for invalid snapshots."""
    failures = []
    for path in paths:
        try:
            validate_snapshot(path)
        except ValueError as exc:
            failures.append((path, str(exc)))
    return failures

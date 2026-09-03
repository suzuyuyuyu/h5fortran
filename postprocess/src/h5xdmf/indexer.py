"""Build ``metadata.h5`` from scheme-versioned snapshot files.

Each snapshot is opened once with ``load_data=False``.  MPI rank partitions
have already been concatenated by the Fortran writer, so every root mesh group
is indexed as one complete logical mesh.
"""

from __future__ import annotations

import os
from typing import Iterable

import numpy as np

from .hdf5.reader import read_snapshot
from .manifest import (
    FieldSchema,
    Manifest,
    MeshRecord,
    MeshSchema,
    MeshSeries,
    append_manifest,
    read_manifest,
    write_manifest,
)
from .model import MeshBlock, Snapshot
from .naming import validate_sequence_names


def build_manifest(paths: Iterable[str], *, relative_to: str) -> Manifest:
    """Index ``paths`` in time order."""
    paths = list(paths)
    if not paths:
        raise ValueError("build_manifest: no seq files given")
    validate_sequence_names(paths)

    manifest: Manifest | None = None
    for path in paths:
        manifest = _ingest(path, manifest, relative_to)
    assert manifest is not None
    return manifest


def update_manifest(meta_path: str, paths: Iterable[str], *, relative_to: str) -> Manifest:
    """Append snapshots not already indexed by an existing manifest."""
    paths = list(paths)
    validate_sequence_names(paths)
    if not os.path.exists(meta_path):
        manifest = build_manifest(paths, relative_to=relative_to)
        write_manifest(meta_path, manifest)
        return manifest

    manifest = read_manifest(meta_path)
    indexed = set(manifest.files)
    new_paths = [p for p in paths if os.path.relpath(p, relative_to) not in indexed]
    if not new_paths:
        return manifest

    tail: Manifest | None = None
    for path in new_paths:
        tail = _ingest(path, tail, relative_to)
    assert tail is not None

    # Check against the in-memory copy before touching metadata.h5.
    for name, series in tail.meshes.items():
        existing = manifest.meshes.get(name)
        if existing is not None and existing.schema.signature() != series.schema.signature():
            raise ValueError(f"mesh {name!r}: schema differs from the stored manifest")

    append_manifest(meta_path, tail)
    return read_manifest(meta_path)


def _ingest(path: str, manifest: Manifest | None, relative_to: str) -> Manifest:
    snap = read_snapshot(path, load_data=False)
    if manifest is None:
        manifest = Manifest(scheme_version=snap.scheme_version)
    elif snap.scheme_version != manifest.scheme_version:
        raise ValueError(
            f"{path!r}: scheme_version {snap.scheme_version} != "
            f"{manifest.scheme_version} seen earlier"
        )

    step_index = manifest.num_steps
    manifest.times.append(float(snap.time))
    manifest.files.append(os.path.relpath(path, relative_to))
    _index_meshes(snap, manifest, step_index)
    return manifest


def _index_meshes(snap: Snapshot, manifest: Manifest, step_index: int) -> None:
    seen: set[str] = set()
    for block in snap.mesh_blocks:
        if block.name in seen:
            raise ValueError(f"step {step_index}: duplicate mesh name {block.name!r}")
        seen.add(block.name)

        schema = _mesh_schema(block)
        series = manifest.meshes.get(block.name)
        if series is None:
            series = MeshSeries(schema=schema)
            manifest.meshes[block.name] = series
        elif series.schema.signature() != schema.signature():
            raise ValueError(
                f"mesh {block.name!r}: schema changed across the series "
                f"(topology, field set, dtype and centering must stay constant)"
            )

        series.records.append(
            MeshRecord(
                step_index=step_index,
                num_nodes=block.num_nodes,
                num_elements=block.num_elements,
            )
        )


def _mesh_schema(block: MeshBlock) -> MeshSchema:
    fields = [
        FieldSchema(a.name, a.center, a.attr_type, np.dtype(a.dtype))
        for a in (*block.point_data, *block.cell_data)
    ]
    return MeshSchema(
        name=block.name,
        topology_type=block.topology_type,
        nodes_per_element=block.nodes_per_element,
        nodes_dtype=np.dtype(block.nodes_dtype),
        connectivity_dtype=np.dtype(block.connectivity_dtype) if block.has_connectivity else None,
        fields=fields,
    )

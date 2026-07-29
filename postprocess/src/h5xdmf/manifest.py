"""Compact mesh time-series index stored as ``metadata.h5``.

Scheme version 1 deliberately has no spatial-subdivision/AMR model.  Each root mesh group in
one snapshot is one complete logical mesh, even when MPI ranks contributed
separate node and cell ranges to its HDF5 datasets.

On-disk layout (``format = "h5xdmf-manifest/1"``)::

    /                              attrs: scheme_version, format, mesh_order
    /timeseries/
        time          (N,) f8      one value per snapshot
        file          (N,) str     snapshot path relative to metadata.h5
    /meshes/<name>/                 invariant mesh schema
        attrs: topology_type, nodes_per_element, field_order
        geometry                    attrs: nodes_dtype, connectivity_dtype
        fields/<Name>               attrs: center, attribute_type, dtype
        timeseries/
            step_index (M,) i8      index into /timeseries
            num_nodes  (M,) i8
            num_elements (M,) i8

Usually M == N.  ``step_index`` also permits a mesh to be absent from a
snapshot without introducing a spatial-subdivision abstraction.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional

import h5py
import numpy as np

from .model import AttributeType, Center

MANIFEST_FORMAT = "h5xdmf-manifest/1"
_STR = h5py.string_dtype(encoding="utf-8")


@dataclass
class FieldSchema:
    """Invariant description of one field."""

    name: str
    center: Center
    attr_type: AttributeType
    dtype: np.dtype


@dataclass
class MeshSchema:
    """Invariant description of one logical mesh."""

    name: str
    topology_type: str
    nodes_per_element: int
    nodes_dtype: np.dtype
    connectivity_dtype: Optional[np.dtype]
    fields: list[FieldSchema] = field(default_factory=list)

    @property
    def has_connectivity(self) -> bool:
        return self.connectivity_dtype is not None

    def signature(self) -> tuple:
        return (
            self.topology_type,
            self.nodes_per_element,
            np.dtype(self.nodes_dtype).str,
            np.dtype(self.connectivity_dtype).str if self.connectivity_dtype is not None else None,
            tuple((f.name, f.center.value, f.attr_type.value, np.dtype(f.dtype).str) for f in self.fields),
        )


@dataclass
class MeshRecord:
    """Step-dependent sizes for one complete logical mesh."""

    step_index: int
    num_nodes: int
    num_elements: int


@dataclass
class MeshSeries:
    schema: MeshSchema
    records: list[MeshRecord] = field(default_factory=list)


@dataclass
class Manifest:
    scheme_version: int
    times: list[float] = field(default_factory=list)
    files: list[str] = field(default_factory=list)
    meshes: dict[str, MeshSeries] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if len(self.times) != len(self.files):
            raise ValueError("manifest times and files must have the same length")

    @property
    def num_steps(self) -> int:
        return len(self.times)

    def mesh_order(self) -> list[str]:
        return list(self.meshes)


def write_manifest(path: str, manifest: Manifest) -> None:
    """Serialise ``manifest`` to ``metadata.h5`` (overwrites)."""
    with h5py.File(path, "w") as h5:
        h5.attrs["scheme_version"] = np.int32(manifest.scheme_version)
        h5.attrs["format"] = MANIFEST_FORMAT
        h5.attrs["mesh_order"] = np.array(manifest.mesh_order(), dtype=_STR)

        ts = h5.create_group("timeseries")
        ts.create_dataset("time", data=np.asarray(manifest.times, dtype=np.float64), maxshape=(None,))
        ts.create_dataset("file", data=np.asarray(manifest.files, dtype=_STR), maxshape=(None,))

        meshes = h5.create_group("meshes")
        for series in manifest.meshes.values():
            _write_mesh(meshes, series)


def _write_mesh(meshes: h5py.Group, series: MeshSeries) -> None:
    schema = series.schema
    mg = meshes.create_group(schema.name)
    mg.attrs["topology_type"] = schema.topology_type
    mg.attrs["nodes_per_element"] = np.int32(schema.nodes_per_element)
    mg.attrs["field_order"] = np.array([f.name for f in schema.fields], dtype=_STR)

    geom = mg.create_group("geometry")
    geom.attrs["nodes_dtype"] = np.dtype(schema.nodes_dtype).str
    if schema.connectivity_dtype is not None:
        geom.attrs["connectivity_dtype"] = np.dtype(schema.connectivity_dtype).str

    fields = mg.create_group("fields")
    for field_schema in schema.fields:
        fg = fields.create_group(field_schema.name)
        fg.attrs["center"] = field_schema.center.value
        fg.attrs["attribute_type"] = field_schema.attr_type.value
        fg.attrs["dtype"] = np.dtype(field_schema.dtype).str

    _write_mesh_records(mg.create_group("timeseries"), series.records)


def _write_mesh_records(ts: h5py.Group, records: list[MeshRecord]) -> None:
    ts.create_dataset(
        "step_index", data=np.asarray([r.step_index for r in records], dtype=np.int64), maxshape=(None,)
    )
    ts.create_dataset(
        "num_nodes", data=np.asarray([r.num_nodes for r in records], dtype=np.int64), maxshape=(None,)
    )
    ts.create_dataset(
        "num_elements", data=np.asarray([r.num_elements for r in records], dtype=np.int64), maxshape=(None,)
    )


def append_manifest(path: str, tail: Manifest) -> None:
    """Append newly indexed snapshots without rewriting existing rows."""
    if not tail.times:
        return

    with h5py.File(path, "r+") as h5:
        _check_format(h5, path)
        if int(h5.attrs["scheme_version"]) != tail.scheme_version:
            raise ValueError("scheme_version differs from the stored manifest")

        base_step = len(h5["timeseries/time"])
        _extend(h5["timeseries/time"], tail.times, np.float64)
        _extend(h5["timeseries/file"], tail.files, _STR)

        meshes = h5["meshes"]
        order = [_decode(v) for v in h5.attrs.get("mesh_order", [])]
        for name, series in tail.meshes.items():
            if name in meshes:
                existing = _read_mesh_schema(meshes[name], name)
                if existing.signature() != series.schema.signature():
                    raise ValueError(f"mesh {name!r}: schema differs from the stored manifest")
            else:
                _write_mesh(meshes, MeshSeries(schema=series.schema))
                order.append(name)

            ts = meshes[name]["timeseries"]
            _extend(ts["step_index"], [r.step_index + base_step for r in series.records], np.int64)
            _extend(ts["num_nodes"], [r.num_nodes for r in series.records], np.int64)
            _extend(ts["num_elements"], [r.num_elements for r in series.records], np.int64)

        h5.attrs["mesh_order"] = np.array(order, dtype=_STR)


def _extend(dset: h5py.Dataset, values, dtype) -> None:
    if not values:
        return
    n0 = dset.shape[0]
    dset.resize((n0 + len(values),))
    dset[n0:] = np.asarray(values, dtype=dtype)


def read_manifest(path: str) -> Manifest:
    """Load ``metadata.h5`` without opening any snapshot files."""
    with h5py.File(path, "r") as h5:
        _check_format(h5, path)
        times = [float(v) for v in h5["timeseries/time"][()]]
        files = [_decode(v) for v in h5["timeseries/file"][()]]
        manifest = Manifest(scheme_version=int(h5.attrs["scheme_version"]), times=times, files=files)

        stored_order = [_decode(v) for v in h5.attrs.get("mesh_order", [])]
        names = stored_order or list(h5["meshes"])
        for name in names:
            mg = h5["meshes"][name]
            schema = _read_mesh_schema(mg, name)
            ts = mg["timeseries"]
            records = [
                MeshRecord(int(step), int(nodes), int(elements))
                for step, nodes, elements in zip(
                    ts["step_index"][()], ts["num_nodes"][()], ts["num_elements"][()]
                )
            ]
            manifest.meshes[name] = MeshSeries(schema=schema, records=records)
    return manifest


def _read_mesh_schema(mg: h5py.Group, name: str) -> MeshSchema:
    geom = mg["geometry"]
    conn_dt = geom.attrs.get("connectivity_dtype")
    fields = []
    for raw_name in mg.attrs["field_order"]:
        field_name = _decode(raw_name)
        fg = mg["fields"][field_name]
        fields.append(
            FieldSchema(
                name=field_name,
                center=Center(_decode(fg.attrs["center"])),
                attr_type=AttributeType(_decode(fg.attrs["attribute_type"])),
                dtype=np.dtype(_decode(fg.attrs["dtype"])),
            )
        )
    return MeshSchema(
        name=name,
        topology_type=_decode(mg.attrs["topology_type"]),
        nodes_per_element=int(mg.attrs["nodes_per_element"]),
        nodes_dtype=np.dtype(_decode(geom.attrs["nodes_dtype"])),
        connectivity_dtype=np.dtype(_decode(conn_dt)) if conn_dt is not None else None,
        fields=fields,
    )


def _check_format(h5: h5py.File, path: str) -> None:
    fmt = _decode(h5.attrs.get("format"))
    if fmt != MANIFEST_FORMAT:
        raise ValueError(f"{path!r}: unexpected manifest format {fmt!r}")
    if "meshes" not in h5:
        raise ValueError(f"{path!r}: unsupported metadata layout; run h5xdmf with --rebuild")


def _decode(value):
    return value.decode() if isinstance(value, bytes) else value

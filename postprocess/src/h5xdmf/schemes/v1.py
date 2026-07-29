"""scheme_version = 1.

Layout (matches ``sample/water_ugrid.xdmf`` / ``water_polydata.xdmf``)::

    /                                     attrs: scheme_version=1, time=<float>
    /<mesh>/                              attrs: topology_type, nodes_per_element
    /<mesh>/geometry/nodes                (num_nodes, 3)  float
    /<mesh>/geometry/connectivity         (num_elements, npe) int   [optional]
    /<mesh>/point_data/<Name>             (num_nodes[, ncomp])
    /<mesh>/cell_data/<Name>              (num_elements[, ncomp])

A mesh group is any top-level group containing a ``geometry`` subgroup. A block
without ``geometry/connectivity`` (e.g. a Polyvertex particle cloud) simply
omits that dataset.
"""

from __future__ import annotations

import h5py
import numpy as np

from ..model import Center, MeshBlock, Snapshot
from .base import SCHEME_VERSION_ATTR, Scheme

TIME_ATTR = "time"
TOPOLOGY_TYPE_ATTR = "topology_type"
NODES_PER_ELEMENT_ATTR = "nodes_per_element"

GEOMETRY_GROUP = "geometry"
NODES_DATASET = "nodes"
CONNECTIVITY_DATASET = "connectivity"
POINT_DATA_GROUP = "point_data"
CELL_DATA_GROUP = "cell_data"


class SchemeV1(Scheme):
    version = 1

    # -- reading ----------------------------------------------------------
    def read_time(self, h5: h5py.File) -> float:
        return float(h5.attrs[TIME_ATTR])

    def _mesh_names(self, h5: h5py.File) -> list[str]:
        names = []
        for key, obj in h5.items():
            if isinstance(obj, h5py.Group) and GEOMETRY_GROUP in obj:
                names.append(key)
        return names

    def read_snapshot(self, h5: h5py.File, *, source_file: str, load_data: bool = False) -> Snapshot:
        snap = Snapshot(
            time=self.read_time(h5),
            source_file=source_file,
            scheme_version=self.version,
        )
        for name in self._mesh_names(h5):
            snap.mesh_blocks.append(self._read_block(h5[name], name, load_data))
        return snap

    def _read_block(self, grp: h5py.Group, name: str, load_data: bool) -> MeshBlock:
        geom = grp[GEOMETRY_GROUP]
        nodes = geom[NODES_DATASET]
        conn = geom.get(CONNECTIVITY_DATASET)

        num_nodes = int(nodes.shape[0])
        if conn is not None:
            num_elements = int(conn.shape[0])
            npe = int(conn.shape[1]) if conn.ndim > 1 else 1
        else:
            # Polyvertex-style: one element per node.
            num_elements = num_nodes
            npe = 1

        block = MeshBlock(
            name=name,
            topology_type=self._decode(grp.attrs[TOPOLOGY_TYPE_ATTR]),
            nodes_per_element=int(grp.attrs.get(NODES_PER_ELEMENT_ATTR, npe)),
            num_nodes=num_nodes,
            num_elements=num_elements,
            nodes_h5path=nodes.name,
            nodes_dtype=np.dtype(nodes.dtype),
            connectivity_h5path=conn.name if conn is not None else None,
            connectivity_dtype=np.dtype(conn.dtype) if conn is not None else None,
            nodes=nodes[()] if load_data else None,
            connectivity=conn[()] if (conn is not None and load_data) else None,
        )

        if POINT_DATA_GROUP in grp:
            for fname, ds in grp[POINT_DATA_GROUP].items():
                block.point_data.append(
                    self.make_data_array(ds, name=fname, center=Center.NODE, load_data=load_data)
                )
        if CELL_DATA_GROUP in grp:
            for fname, ds in grp[CELL_DATA_GROUP].items():
                block.cell_data.append(
                    self.make_data_array(ds, name=fname, center=Center.CELL, load_data=load_data)
                )
        return block

    # -- h5path resolution ------------------------------------------------
    def mesh_group_h5path(self, name: str) -> str:
        return name if name.startswith("/") else f"/{name}"

    def nodes_h5path(self, group: str) -> str:
        return f"{group}/{GEOMETRY_GROUP}/{NODES_DATASET}"

    def connectivity_h5path(self, group: str) -> str:
        return f"{group}/{GEOMETRY_GROUP}/{CONNECTIVITY_DATASET}"

    def field_h5path(self, group: str, center: Center, name: str) -> str:
        sub = POINT_DATA_GROUP if center is Center.NODE else CELL_DATA_GROUP
        return f"{group}/{sub}/{name}"

    # -- writing ----------------------------------------------------------
    def write_snapshot(self, h5: h5py.File, snapshot: Snapshot) -> None:
        h5.attrs[SCHEME_VERSION_ATTR] = np.int32(self.version)
        h5.attrs[TIME_ATTR] = np.float64(snapshot.time)
        for block in snapshot.mesh_blocks:
            self._write_block(h5, block)

    def _write_block(self, h5: h5py.File, block: MeshBlock) -> None:
        grp = h5.require_group(block.name)
        grp.attrs[TOPOLOGY_TYPE_ATTR] = block.topology_type
        grp.attrs[NODES_PER_ELEMENT_ATTR] = np.int32(block.nodes_per_element)

        geom = grp.require_group(GEOMETRY_GROUP)
        if block.nodes is None:
            raise ValueError(f"block {block.name!r}: nodes must be loaded to write")
        geom.create_dataset(NODES_DATASET, data=block.nodes)
        if block.connectivity is not None:
            geom.create_dataset(CONNECTIVITY_DATASET, data=block.connectivity)

        if block.point_data:
            pg = grp.require_group(POINT_DATA_GROUP)
            for arr in block.point_data:
                self._write_field(pg, arr)
        if block.cell_data:
            cg = grp.require_group(CELL_DATA_GROUP)
            for arr in block.cell_data:
                self._write_field(cg, arr)

    @staticmethod
    def _write_field(grp: h5py.Group, arr) -> None:
        if arr.values is None:
            raise ValueError(f"field {arr.name!r}: values must be loaded to write")
        ds = grp.create_dataset(arr.name, data=arr.values)
        # Record the rank explicitly so a non-square field (e.g. 3 nodes) is
        # never misread as a Vector on the way back in.
        ds.attrs["attribute_type"] = arr.attr_type.value

    @staticmethod
    def _decode(value) -> str:
        return value.decode() if isinstance(value, bytes) else str(value)

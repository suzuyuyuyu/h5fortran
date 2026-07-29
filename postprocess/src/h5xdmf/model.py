"""Scheme-independent intermediate data model.

This model is deliberately aligned with the XDMF3 vocabulary (AttributeType,
Center, TopologyType) so that the XDMF builder can consume it directly, while
the HDF5 layout details live entirely in :mod:`h5xdmf.schemes`.

Nothing in this module knows *where* data lives inside an HDF5 file; a
``DataArray`` merely records the ``h5path`` a scheme resolved for it plus enough
metadata (shape/dtype) to emit a ``<DataItem>`` without loading the payload.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

import numpy as np


class AttributeType(str, Enum):
    """XDMF attribute rank. Value is the literal XDMF ``AttributeType``."""

    SCALAR = "Scalar"
    VECTOR = "Vector"
    TENSOR6 = "Tensor6"  # symmetric 3x3 -> 6 components
    TENSOR = "Tensor"  # full 3x3 -> 9 components

    @property
    def num_components(self) -> int:
        return {
            AttributeType.SCALAR: 1,
            AttributeType.VECTOR: 3,
            AttributeType.TENSOR6: 6,
            AttributeType.TENSOR: 9,
        }[self]

    @classmethod
    def from_num_components(cls, ncomp: int) -> "AttributeType":
        mapping = {1: cls.SCALAR, 3: cls.VECTOR, 6: cls.TENSOR6, 9: cls.TENSOR}
        try:
            return mapping[ncomp]
        except KeyError as exc:  # pragma: no cover - defensive
            raise ValueError(f"cannot infer AttributeType from {ncomp} components") from exc


class Center(str, Enum):
    """XDMF attribute centering."""

    NODE = "Node"
    CELL = "Cell"


@dataclass
class DataArray:
    """A single field (point_data or cell_data entry).

    ``values`` is populated only when the data was eagerly loaded; for
    XDMF generation the ``h5path`` + ``shape`` + ``dtype`` are sufficient.
    """

    name: str
    center: Center
    attr_type: AttributeType
    shape: tuple[int, ...]
    dtype: np.dtype
    h5path: str
    values: Optional[np.ndarray] = None

    @property
    def num_entities(self) -> int:
        """Number of nodes or cells this field is defined over."""
        return int(self.shape[0]) if self.shape else 0


@dataclass
class MeshBlock:
    """One mesh inside a snapshot (e.g. ``ugrid`` or ``polydata``).

    A block with a single-node topology (Polyvertex) has ``connectivity=None``.
    """

    name: str
    topology_type: str  # XDMF TopologyType, e.g. "Hexahedron", "Polyvertex"
    nodes_per_element: int
    num_nodes: int
    num_elements: int
    nodes_h5path: str
    nodes_dtype: np.dtype
    connectivity_h5path: Optional[str] = None
    connectivity_dtype: Optional[np.dtype] = None
    point_data: list[DataArray] = field(default_factory=list)
    cell_data: list[DataArray] = field(default_factory=list)
    # Eagerly-loaded arrays (optional).
    nodes: Optional[np.ndarray] = None
    connectivity: Optional[np.ndarray] = None

    @property
    def has_connectivity(self) -> bool:
        return self.connectivity_h5path is not None


@dataclass
class Snapshot:
    """A single time step, corresponding to one ``seqNNNNN.h5`` file."""

    time: float
    source_file: str  # path as it should appear/resolve from the XDMF location
    scheme_version: int
    mesh_blocks: list[MeshBlock] = field(default_factory=list)
    name: Optional[str] = None  # e.g. "seq00000"

    def block(self, name: str) -> MeshBlock:
        for b in self.mesh_blocks:
            if b.name == name:
                return b
        raise KeyError(name)


@dataclass
class Series:
    """An ordered temporal collection of snapshots."""

    snapshots: list[Snapshot] = field(default_factory=list)

    def __len__(self) -> int:
        return len(self.snapshots)

    def __iter__(self):
        return iter(self.snapshots)

    @property
    def mesh_names(self) -> list[str]:
        """Union of mesh block names across all snapshots, first-seen order."""
        seen: list[str] = []
        for snap in self.snapshots:
            for b in snap.mesh_blocks:
                if b.name not in seen:
                    seen.append(b.name)
        return seen

"""Abstract base for HDF5 layout schemes.

A *scheme* is the single place that knows how a given ``scheme_version`` lays
data out inside an HDF5 file: group/dataset naming, which attributes carry the
time and topology, and how a field's rank (Scalar/Vector/Tensor...) is decided.

The reader and writer are scheme-agnostic; they resolve a concrete
:class:`Scheme` from the registry and delegate. Adding support for a new output
format is therefore a matter of dropping in ``schemes/vN.py`` and registering
it -- no changes to reader/writer/model.

Subclasses must implement :meth:`read_snapshot` and :meth:`write_snapshot`.
The helpers here (attribute-type inference, DataArray construction) are shared
so that concrete schemes stay short.
"""

from __future__ import annotations

from abc import ABC, abstractmethod

import h5py
import numpy as np

from ..model import AttributeType, Center, DataArray, Snapshot

#: HDF5 root attribute that selects the scheme. Fixed across all versions so the
#: reader can discover the version *before* it knows which scheme to use.
SCHEME_VERSION_ATTR = "scheme_version"


class Scheme(ABC):
    version: int

    # -- version discovery ------------------------------------------------
    @abstractmethod
    def read_time(self, h5: h5py.File) -> float:
        """Return the simulation time stored in the file."""

    # -- main entry points ------------------------------------------------
    @abstractmethod
    def read_snapshot(self, h5: h5py.File, *, source_file: str, load_data: bool = False) -> Snapshot:
        """Build a :class:`Snapshot` from an open HDF5 file."""

    @abstractmethod
    def write_snapshot(self, h5: h5py.File, snapshot: Snapshot) -> None:
        """Serialise a :class:`Snapshot` into an open (writable) HDF5 file."""

    # -- h5path resolution ------------------------------------------------
    # The manifest/XDMF layers store only *logical* coordinates (mesh name,
    # field name, centering) and ask the scheme for the *physical* h5path.
    # This keeps every path convention in one place, so a new layout version
    # never leaks path strings into the manifest.
    @abstractmethod
    def mesh_group_h5path(self, name: str) -> str:
        """Absolute h5path of the group holding mesh ``name`` (e.g. ``/ugrid``)."""

    @abstractmethod
    def nodes_h5path(self, group: str) -> str:
        """Absolute h5path of the node-coordinates dataset for a mesh ``group``."""

    @abstractmethod
    def connectivity_h5path(self, group: str) -> str:
        """Absolute h5path of the connectivity dataset for a mesh ``group``."""

    @abstractmethod
    def field_h5path(self, group: str, center: Center, name: str) -> str:
        """Absolute h5path of field ``name`` (point/cell per ``center``)."""

    # -- shared helpers ---------------------------------------------------
    @staticmethod
    def infer_attr_type(dataset: h5py.Dataset) -> AttributeType:
        """Infer XDMF rank from dataset shape, honouring an explicit override.

        If the writer stored an ``attribute_type`` dataset attribute we trust
        it; otherwise fall back to the trailing-dimension size. This lets a
        Fortran writer that cannot easily annotate datasets still round-trip.
        """
        override = dataset.attrs.get("attribute_type")
        if override is not None:
            text = override.decode() if isinstance(override, bytes) else str(override)
            return AttributeType(text)
        if dataset.ndim == 1:
            return AttributeType.SCALAR
        return AttributeType.from_num_components(int(dataset.shape[1]))

    @classmethod
    def make_data_array(
        cls, dataset: h5py.Dataset, *, name: str, center: Center, load_data: bool
    ) -> DataArray:
        return DataArray(
            name=name,
            center=center,
            attr_type=cls.infer_attr_type(dataset),
            shape=tuple(int(s) for s in dataset.shape),
            dtype=np.dtype(dataset.dtype),
            h5path=dataset.name,
            values=dataset[()] if load_data else None,
        )

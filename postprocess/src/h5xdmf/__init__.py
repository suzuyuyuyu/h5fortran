"""h5xdmf: build XDMF3 visualization files from HDF5 output.

The HDF5 layout is not fixed; a ``scheme_version`` root attribute selects the
layout, resolved via :mod:`h5xdmf.schemes`. See ``docs/design.md``.
"""

from .model import (
    AttributeType,
    Center,
    DataArray,
    MeshBlock,
    Series,
    Snapshot,
)

__all__ = [
    "AttributeType",
    "Center",
    "DataArray",
    "MeshBlock",
    "Snapshot",
    "Series",
]

__version__ = "0.1.0"

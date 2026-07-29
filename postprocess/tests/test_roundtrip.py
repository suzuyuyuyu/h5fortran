"""Write synthetic HDF5 via the scheme, read it back, check the model."""

from __future__ import annotations

import numpy as np

from h5xdmf.hdf5 import read_snapshot, read_scheme_version, write_snapshot
from h5xdmf.model import AttributeType, Center, MeshBlock, Snapshot
from h5xdmf import sample


def test_sample_dimensions_match_reference():
    snap = sample.make_snapshot(0.0, ncells=(20, 20, 20))
    ug = snap.block("ugrid")
    assert ug.num_elements == 8000
    assert ug.num_nodes == 9261  # 21**3


def test_roundtrip_metadata_and_data(tmp_path):
    src = sample.make_snapshot(1.0e-5, ncells=(4, 4, 4), nparticles=17, seed=3)
    path = tmp_path / "seq00000.h5"
    write_snapshot(str(path), src)

    # Metadata-only read.
    meta = read_snapshot(str(path), load_data=False)
    assert meta.name == "seq00000"
    assert meta.scheme_version == 1
    assert meta.time == 1.0e-5
    assert {b.name for b in meta.mesh_blocks} == {"ugrid", "polydata"}

    ug = meta.block("ugrid")
    assert ug.topology_type == "Hexahedron"
    assert ug.has_connectivity
    pressure = next(a for a in ug.point_data if a.name == "Pressure")
    assert pressure.attr_type is AttributeType.SCALAR
    assert pressure.center is Center.NODE
    assert pressure.values is None  # not loaded
    vel = next(a for a in ug.point_data if a.name == "Velocity")
    assert vel.attr_type is AttributeType.VECTOR

    poly = meta.block("polydata")
    assert poly.topology_type == "Polyvertex"
    assert not poly.has_connectivity

    # Full read matches source values.
    full = read_snapshot(str(path), load_data=True)
    fug = full.block("ugrid")
    np.testing.assert_allclose(fug.nodes, src.block("ugrid").nodes)
    np.testing.assert_array_equal(fug.connectivity, src.block("ugrid").connectivity)
    fpressure = next(a for a in fug.point_data if a.name == "Pressure")
    np.testing.assert_allclose(
        fpressure.values, next(a for a in src.block("ugrid").point_data if a.name == "Pressure").values
    )


def test_scheme_version_is_readable(tmp_path):
    import h5py

    path = tmp_path / "s.h5"
    write_snapshot(str(path), sample.make_snapshot(0.0, ncells=(2, 2, 2), nparticles=3))
    with h5py.File(path, "r") as h5:
        assert read_scheme_version(h5) == 1


def test_connectivity_mesh_topologies_roundtrip(tmp_path):
    topologies = [
        ("tetra", "Tetrahedron", 4),
        ("quadrilateral", "Quadrilateral", 4),
        ("triangle", "Triangle", 3),
    ]
    blocks = []
    for name, topology_type, nodes_per_element in topologies:
        nodes = np.arange(nodes_per_element * 3, dtype=np.float64).reshape(nodes_per_element, 3)
        connectivity = np.arange(nodes_per_element, dtype=np.int32).reshape(1, nodes_per_element)
        blocks.append(
            MeshBlock(
                name=name,
                topology_type=topology_type,
                nodes_per_element=nodes_per_element,
                num_nodes=nodes_per_element,
                num_elements=1,
                nodes_h5path=f"/{name}/geometry/nodes",
                nodes_dtype=nodes.dtype,
                connectivity_h5path=f"/{name}/geometry/connectivity",
                connectivity_dtype=connectivity.dtype,
                nodes=nodes,
                connectivity=connectivity,
            )
        )

    path = tmp_path / "mixed_meshes.h5"
    write_snapshot(
        str(path),
        Snapshot(time=0.0, source_file=str(path), scheme_version=1, mesh_blocks=blocks),
    )
    result = read_snapshot(str(path), load_data=False)

    for name, topology_type, nodes_per_element in topologies:
        block = result.block(name)
        assert block.topology_type == topology_type
        assert block.nodes_per_element == nodes_per_element
        assert block.connectivity_h5path is not None

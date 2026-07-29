"""Index seq files -> mesh time series -> XDMF."""

from __future__ import annotations

import pytest
import h5py

from h5xdmf import sample
from h5xdmf.hdf5.writer import write_snapshot
from h5xdmf.indexer import build_manifest, update_manifest
from h5xdmf.manifest import read_manifest, write_manifest
from h5xdmf.xdmf import build_xdmf_files


def _make_run(tmp_path):
    """Write 3 seq files whose mesh + particle counts both change per step."""
    phdf5 = tmp_path / "phdf5"
    phdf5.mkdir()
    ncells = [(3, 3, 3), (4, 4, 4), (6, 6, 6)]
    nparts = [30, 24, 17]
    paths = []
    for i, (nc, npart) in enumerate(zip(ncells, nparts)):
        snap = sample.make_snapshot(i * 1e-5, ncells=nc, nparticles=npart, seed=i)
        p = phdf5 / f"seq{i:05d}.h5"
        write_snapshot(str(p), snap)
        paths.append(str(p))
    return paths, ncells, nparts


def test_manifest_roundtrip_and_varying_sizes(tmp_path):
    paths, ncells, nparts = _make_run(tmp_path)

    manifest = build_manifest(paths, relative_to=str(tmp_path))
    meta = tmp_path / "metadata.h5"
    write_manifest(str(meta), manifest)
    manifest = read_manifest(str(meta))

    with h5py.File(meta, "r") as h5:
        assert set(h5) == {"meshes", "timeseries"}
        assert set(h5["timeseries"]) == {"file", "time"}
        assert set(h5["meshes/ugrid/timeseries"]) == {
            "step_index",
            "num_nodes",
            "num_elements",
        }

    assert manifest.scheme_version == 1
    assert set(manifest.meshes) == {"ugrid", "polydata"}
    assert manifest.meshes["ugrid"].schema.has_connectivity
    assert not manifest.meshes["polydata"].schema.has_connectivity

    # Entity counts may vary while the logical mesh identity remains fixed.
    ug_cells = [nx * ny * nz for nx, ny, nz in ncells]
    ug_nodes = [(nx + 1) * (ny + 1) * (nz + 1) for nx, ny, nz in ncells]
    for ug, pv, exp_cells, exp_nodes, exp_np in zip(
        manifest.meshes["ugrid"].records,
        manifest.meshes["polydata"].records,
        ug_cells,
        ug_nodes,
        nparts,
    ):
        assert (ug.num_elements, ug.num_nodes) == (exp_cells, exp_nodes)
        assert pv.num_nodes == exp_np


def test_xdmf_from_manifest_only(tmp_path):
    paths, ncells, _ = _make_run(tmp_path)
    manifest = build_manifest(paths, relative_to=str(tmp_path))

    out = tmp_path / "xdmf"
    written = build_xdmf_files(manifest, str(out), manifest_dir=str(tmp_path))
    assert set(written) == {"ugrid", "polydata"}

    ug = (out / "ugrid.xdmf").read_text()
    # Varying dimensions are emitted without ever reopening the seq files.
    assert 'NumberType="Int" Precision="4"' in ug  # ProcessorID is int32
    assert f'Dimensions="{ncells[-1][0]**3}' in ug  # last step's cell count
    assert "../phdf5/seq00000.h5:/ugrid/geometry/nodes" in ug
    assert 'CollectionType="Spatial"' not in ug

    pv = (out / "polydata.xdmf").read_text()
    assert 'TopologyType="Polyvertex"' in pv
    assert "<Topology" in pv and "NodesPerElement" in pv


def _summary(manifest):
    return (
        [(round(t, 10), f) for t, f in zip(manifest.times, manifest.files)],
        {
            name: [(r.step_index, r.num_nodes, r.num_elements) for r in series.records]
            for name, series in manifest.meshes.items()
        },
    )


def test_incremental_append_matches_full_rebuild(tmp_path):
    paths, _, _ = _make_run(tmp_path)  # 3 seq files
    meta = tmp_path / "metadata.h5"

    # Build from the first file, then append the rest incrementally.
    update_manifest(str(meta), paths[:1], relative_to=str(tmp_path))
    assert read_manifest(str(meta)).num_steps == 1
    update_manifest(str(meta), paths, relative_to=str(tmp_path))
    update_manifest(str(meta), paths, relative_to=str(tmp_path))  # idempotent no-op

    incremental = read_manifest(str(meta))
    full = build_manifest(paths, relative_to=str(tmp_path))
    assert _summary(incremental) == _summary(full)


def test_update_manifest_builds_when_absent(tmp_path):
    paths, _, _ = _make_run(tmp_path)
    meta = tmp_path / "metadata.h5"
    assert not meta.exists()
    manifest = update_manifest(str(meta), paths, relative_to=str(tmp_path))
    assert meta.exists()
    assert manifest.num_steps == len(paths)


def test_append_rejects_schema_drift(tmp_path):
    phdf5 = tmp_path / "phdf5"
    phdf5.mkdir()
    good = sample.make_snapshot(0.0, ncells=(3, 3, 3), nparticles=10, seed=0)
    p0 = phdf5 / "seq00000.h5"
    write_snapshot(str(p0), good)
    meta = tmp_path / "metadata.h5"
    update_manifest(str(meta), [str(p0)], relative_to=str(tmp_path))

    drifted = sample.make_snapshot(1e-5, ncells=(3, 3, 3), nparticles=10, seed=1)
    drifted.block("ugrid").point_data.pop()
    p1 = phdf5 / "seq00001.h5"
    write_snapshot(str(p1), drifted)

    with pytest.raises(ValueError, match="schema"):
        update_manifest(str(meta), [str(p0), str(p1)], relative_to=str(tmp_path))


def test_indexer_rejects_schema_drift(tmp_path):
    phdf5 = tmp_path / "phdf5"
    phdf5.mkdir()
    good = sample.make_snapshot(0.0, ncells=(3, 3, 3), nparticles=10, seed=0)
    p0 = phdf5 / "seq00000.h5"
    write_snapshot(str(p0), good)

    # Second file drops a field -> the invariant schema no longer holds.
    drifted = sample.make_snapshot(1e-5, ncells=(3, 3, 3), nparticles=10, seed=1)
    drifted.block("ugrid").point_data.pop()  # remove a field
    p1 = phdf5 / "seq00001.h5"
    write_snapshot(str(p1), drifted)

    with pytest.raises(ValueError, match="schema changed"):
        build_manifest([str(p0), str(p1)], relative_to=str(tmp_path))


def test_indexer_rejects_topology_drift(tmp_path):
    phdf5 = tmp_path / "phdf5"
    phdf5.mkdir()
    first = sample.make_snapshot(0.0, ncells=(2, 2, 2), nparticles=3)
    p0 = phdf5 / "seq00000.h5"
    write_snapshot(str(p0), first)

    changed = sample.make_snapshot(1.0, ncells=(2, 2, 2), nparticles=3)
    changed.block("ugrid").topology_type = "AnotherTopology"
    p1 = phdf5 / "seq00001.h5"
    write_snapshot(str(p1), changed)

    with pytest.raises(ValueError, match="schema changed"):
        build_manifest([str(p0), str(p1)], relative_to=str(tmp_path))

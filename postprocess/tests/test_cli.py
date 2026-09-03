from __future__ import annotations

from h5xdmf import sample
from h5xdmf.cli import main
from h5xdmf.hdf5.writer import write_snapshot
from h5xdmf.manifest import read_manifest


def test_cli_builds_manifest_and_xdmf(tmp_path):
    phdf5 = tmp_path / "phdf5"
    phdf5.mkdir()
    for step in range(2):
        write_snapshot(
            str(phdf5 / f"seq{step:05d}.h5"),
            sample.make_snapshot(float(step), ncells=(2, 2, 2), nparticles=3),
        )

    assert main(
        [
            str(phdf5 / "seq*.h5"),
            "--metadata",
            str(tmp_path / "metadata.h5"),
            "--outdir",
            str(tmp_path / "xdmf"),
        ]
    ) == 0
    assert (tmp_path / "metadata.h5").is_file()
    assert (tmp_path / "xdmf" / "ugrid.xdmf").is_file()
    assert (tmp_path / "xdmf" / "polydata.xdmf").is_file()


def test_validate_reports_valid_and_invalid_snapshots(tmp_path):
    good = tmp_path / "seq000000.h5"
    bad = tmp_path / "seq000001.h5"
    write_snapshot(str(good), sample.make_snapshot(0.0, ncells=(2, 2, 2), nparticles=3))
    bad.write_text("not HDF5")

    assert main(["validate", str(good)]) == 0
    assert main(["validate", str(good), str(bad)]) == 1


def test_prune_removes_deleted_snapshot(tmp_path):
    paths = []
    for step in range(2):
        path = tmp_path / f"seq{step:06d}.h5"
        write_snapshot(str(path), sample.make_snapshot(float(step), ncells=(2, 2, 2), nparticles=3))
        paths.append(path)
    metadata = tmp_path / "metadata.h5"
    assert main(
        [str(tmp_path / "seq*.h5"), "--metadata", str(metadata), "--outdir", str(tmp_path / "xdmf")]
    ) == 0
    paths[0].unlink()
    assert main(
        [str(paths[1]), "--metadata", str(metadata), "--prune", "--outdir", str(tmp_path / "xdmf")]
    ) == 0
    manifest = read_manifest(str(metadata))
    assert manifest.files == [paths[1].name]
    assert all(record.step_index == 0 for series in manifest.meshes.values() for record in series.records)


def test_mixed_sequence_width_is_rejected(tmp_path):
    for name in ("seq00001.h5", "seq000002.h5"):
        write_snapshot(str(tmp_path / name), sample.make_snapshot(0.0, ncells=(2, 2, 2), nparticles=3))
    try:
        main([str(tmp_path / "seq*.h5"), "--metadata", str(tmp_path / "metadata.h5")])
    except ValueError as exc:
        assert "zero-padding" in str(exc)
    else:
        raise AssertionError("mixed sequence widths must fail")

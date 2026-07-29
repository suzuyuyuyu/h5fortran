from __future__ import annotations

from h5xdmf import sample
from h5xdmf.cli import main
from h5xdmf.hdf5.writer import write_snapshot


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

"""Synthetic sample data generator.

Reproduces the shape of ``sample/water_*.xdmf``: a hexahedral unstructured grid
(``ugrid``) plus a particle cloud (``polydata``), written one file per step via
the scheme writer. Useful for exercising the reader -> (future) XDMF pipeline
end to end without the Fortran solver.
"""

from __future__ import annotations

import os

import numpy as np

from .model import AttributeType, Center, DataArray, MeshBlock, Snapshot
from .hdf5.writer import write_snapshot


def _hex_grid(ncells: tuple[int, int, int]) -> tuple[np.ndarray, np.ndarray]:
    """Return (nodes[N,3] float64, connectivity[E,8] int64) for a box mesh."""
    nx, ny, nz = ncells
    npx, npy, npz = nx + 1, ny + 1, nz + 1

    lin = lambda i, j, k: i + npx * (j + npy * k)

    xs = np.linspace(0.0, 1.0, npx)
    ys = np.linspace(0.0, 1.0, npy)
    zs = np.linspace(0.0, 1.0, npz)
    gx, gy, gz = np.meshgrid(xs, ys, zs, indexing="ij")
    # Flatten in the same k-major order used by lin().
    nodes = np.empty((npx * npy * npz, 3), dtype=np.float64)
    for k in range(npz):
        for j in range(npy):
            for i in range(npx):
                nodes[lin(i, j, k)] = (xs[i], ys[j], zs[k])

    conn = np.empty((nx * ny * nz, 8), dtype=np.int64)
    e = 0
    for k in range(nz):
        for j in range(ny):
            for i in range(nx):
                conn[e] = (
                    lin(i, j, k),
                    lin(i + 1, j, k),
                    lin(i + 1, j + 1, k),
                    lin(i, j + 1, k),
                    lin(i, j, k + 1),
                    lin(i + 1, j, k + 1),
                    lin(i + 1, j + 1, k + 1),
                    lin(i, j + 1, k + 1),
                )
                e += 1
    return nodes, conn


def make_snapshot(
    time: float,
    *,
    ncells: tuple[int, int, int] = (20, 20, 20),
    nparticles: int = 100,
    seed: int = 0,
) -> Snapshot:
    """Build a fully-loaded two-block snapshot (ugrid + polydata)."""
    rng = np.random.default_rng(seed)
    nodes, conn = _hex_grid(ncells)
    nn, ne = nodes.shape[0], conn.shape[0]

    ugrid = MeshBlock(
        name="ugrid",
        topology_type="Hexahedron",
        nodes_per_element=8,
        num_nodes=nn,
        num_elements=ne,
        nodes_h5path="/ugrid/geometry/nodes",
        nodes_dtype=nodes.dtype,
        connectivity_h5path="/ugrid/geometry/connectivity",
        connectivity_dtype=conn.dtype,
        nodes=nodes,
        connectivity=conn,
        point_data=[
            DataArray(
                "Pressure", Center.NODE, AttributeType.SCALAR, (nn,), np.dtype("f8"),
                "/ugrid/point_data/Pressure",
                values=np.sin(nodes[:, 0] * np.pi + time) * 1.0e3,
            ),
            DataArray(
                "Velocity", Center.NODE, AttributeType.VECTOR, (nn, 3), np.dtype("f8"),
                "/ugrid/point_data/Velocity",
                values=(nodes - 0.5) * float(time),
            ),
        ],
        cell_data=[
            DataArray(
                "ProcessorID", Center.CELL, AttributeType.SCALAR, (ne,), np.dtype("i4"),
                "/ugrid/cell_data/ProcessorID",
                values=(np.arange(ne) % 4).astype(np.int32),
            ),
        ],
    )

    pos = rng.random((nparticles, 3))
    polydata = MeshBlock(
        name="polydata",
        topology_type="Polyvertex",
        nodes_per_element=1,
        num_nodes=nparticles,
        num_elements=nparticles,
        nodes_h5path="/polydata/geometry/nodes",
        nodes_dtype=pos.dtype,
        nodes=pos,
        point_data=[
            DataArray(
                "Velocity", Center.NODE, AttributeType.VECTOR, (nparticles, 3), np.dtype("f8"),
                "/polydata/point_data/Velocity", values=rng.random((nparticles, 3)),
            ),
            DataArray(
                "vonMisesStress", Center.NODE, AttributeType.SCALAR, (nparticles,), np.dtype("f8"),
                "/polydata/point_data/vonMisesStress", values=rng.random(nparticles),
            ),
        ],
    )

    return Snapshot(
        time=time,
        source_file="",
        scheme_version=1,
        mesh_blocks=[ugrid, polydata],
    )


def write_series(
    outdir: str,
    *,
    nsteps: int = 5,
    dt: float = 1.0e-5,
    ncells: tuple[int, int, int] = (20, 20, 20),
    nparticles: int = 100,
    scheme_version: int = 1,
) -> list[str]:
    """Write ``nsteps`` files ``seqNNNNN.h5`` and return their paths."""
    os.makedirs(outdir, exist_ok=True)
    paths = []
    for step in range(nsteps):
        snap = make_snapshot(step * dt, ncells=ncells, nparticles=nparticles, seed=step)
        path = os.path.join(outdir, f"seq{step:05d}.h5")
        write_snapshot(path, snap, scheme_version=scheme_version)
        paths.append(path)
    return paths

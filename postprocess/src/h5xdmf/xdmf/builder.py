"""Generate one temporal XDMF3 file per logical mesh."""

from __future__ import annotations

import os

from ..manifest import Manifest, MeshRecord, MeshSchema
from ..model import AttributeType, Center
from ..schemes import get_scheme

_HEADER = '<?xml version="1.0"?>\n<!DOCTYPE Xdmf SYSTEM "Xdmf.dtd">\n<Xdmf Version="3.0">\n'
_FOOTER = "</Xdmf>\n"


def build_xdmf_files(manifest: Manifest, outdir: str, *, manifest_dir: str) -> dict[str, str]:
    """Write one ``<mesh_name>.xdmf`` per logical mesh."""
    os.makedirs(outdir, exist_ok=True)
    scheme = get_scheme(manifest.scheme_version)
    written: dict[str, str] = {}
    for name, series in manifest.meshes.items():
        xml = _build_mesh_xml(
            manifest,
            series.schema,
            series.records,
            scheme,
            outdir=outdir,
            manifest_dir=manifest_dir,
        )
        path = os.path.join(outdir, f"{name}.xdmf")
        with open(path, "w") as fh:
            fh.write(xml)
        written[name] = path
    return written


def _build_mesh_xml(
    manifest: Manifest,
    schema: MeshSchema,
    records: list[MeshRecord],
    scheme,
    *,
    outdir: str,
    manifest_dir: str,
) -> str:
    lines = [_HEADER, "  <Domain>\n"]
    lines.append('    <Grid Name="TimeSeries" GridType="Collection" CollectionType="Temporal">\n')
    for record in records:
        step = record.step_index
        lines.append(
            _uniform_grid(
                name=f"step{step:05d}",
                time=manifest.times[step],
                rel_file=manifest.files[step],
                record=record,
                schema=schema,
                scheme=scheme,
                outdir=outdir,
                manifest_dir=manifest_dir,
            )
        )
    lines.append("    </Grid>\n")
    lines.append("  </Domain>\n")
    lines.append(_FOOTER)
    return "".join(lines)


def _uniform_grid(
    *,
    name: str,
    time: float,
    rel_file: str,
    record: MeshRecord,
    schema: MeshSchema,
    scheme,
    outdir: str,
    manifest_dir: str,
) -> str:
    pad = "      "
    ref = _ref(rel_file, manifest_dir, outdir)
    group = scheme.mesh_group_h5path(schema.name)
    out = [f'{pad}<Grid Name="{name}" GridType="Uniform">\n']
    out.append(f'{pad}  <Time Value="{_fmt_time(time)}"/>\n')

    if schema.has_connectivity:
        out.append(
            f'{pad}  <Topology TopologyType="{schema.topology_type}" '
            f'NumberOfElements="{record.num_elements}">\n'
        )
        out.append(
            _data_item(
                f"{ref}:{scheme.connectivity_h5path(group)}",
                schema.connectivity_dtype,
                f"{record.num_elements} {schema.nodes_per_element}",
                4,
            )
        )
        out.append(f"{pad}  </Topology>\n")
    else:
        out.append(
            f'{pad}  <Topology TopologyType="{schema.topology_type}" '
            f'NumberOfElements="{record.num_elements}" '
            f'NodesPerElement="{schema.nodes_per_element}"/>\n'
        )

    out.append(f'{pad}  <Geometry GeometryType="XYZ">\n')
    out.append(
        _data_item(
            f"{ref}:{scheme.nodes_h5path(group)}",
            schema.nodes_dtype,
            f"{record.num_nodes} 3",
            4,
        )
    )
    out.append(f"{pad}  </Geometry>\n")

    for field_schema in schema.fields:
        n = record.num_nodes if field_schema.center is Center.NODE else record.num_elements
        dims = (
            str(n)
            if field_schema.attr_type is AttributeType.SCALAR
            else f"{n} {field_schema.attr_type.num_components}"
        )
        out.append(
            f'{pad}  <Attribute Name="{field_schema.name}" '
            f'AttributeType="{field_schema.attr_type.value}" '
            f'Center="{field_schema.center.value}">\n'
        )
        out.append(
            _data_item(
                f"{ref}:{scheme.field_h5path(group, field_schema.center, field_schema.name)}",
                field_schema.dtype,
                dims,
                4,
            )
        )
        out.append(f"{pad}  </Attribute>\n")

    out.append(f"{pad}</Grid>\n")
    return "".join(out)


def _data_item(body: str, dtype, dims: str, indent: int) -> str:
    pad = "  " * indent
    number_type, precision = _number_type(dtype)
    return (
        f'{pad}<DataItem Format="HDF" NumberType="{number_type}" '
        f'Precision="{precision}" Dimensions="{dims}">\n'
        f"{pad}  {body}\n"
        f"{pad}</DataItem>\n"
    )


def _number_type(dtype) -> tuple[str, int]:
    import numpy as np

    dt = np.dtype(dtype)
    kind = {"f": "Float", "i": "Int", "u": "UInt"}.get(dt.kind, "Float")
    return kind, dt.itemsize


def _ref(rel_file: str, manifest_dir: str, outdir: str) -> str:
    abs_seq = os.path.normpath(os.path.join(manifest_dir, rel_file))
    return os.path.relpath(abs_seq, outdir)


def _fmt_time(t: float) -> str:
    return f"{t:.15E}"

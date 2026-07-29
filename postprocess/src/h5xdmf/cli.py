"""Command line interface for indexing HDF5 snapshots and generating XDMF3."""

from __future__ import annotations

import argparse
import glob
import os
from collections.abc import Sequence

from .indexer import build_manifest, update_manifest
from .manifest import read_manifest, write_manifest
from .xdmf import build_xdmf_files


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="h5xdmf",
        description="Build metadata.h5 and XDMF3 files from scheme-versioned HDF5 snapshots.",
    )
    parser.add_argument("inputs", nargs="*", help="HDF5 paths or glob patterns, in time order")
    parser.add_argument("-m", "--metadata", default="metadata.h5", help="manifest path")
    parser.add_argument("-o", "--outdir", default=".", help="directory for generated XDMF files")
    parser.add_argument(
        "--generate-only",
        action="store_true",
        help="generate XDMF from an existing manifest without scanning snapshots",
    )
    parser.add_argument(
        "--rebuild",
        action="store_true",
        help="replace the manifest instead of incrementally appending new snapshots",
    )
    return parser


def _expand_inputs(patterns: Sequence[str]) -> list[str]:
    paths: list[str] = []
    for pattern in patterns:
        matches = sorted(glob.glob(pattern))
        paths.extend(matches if matches else [pattern])
    return paths


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    metadata = os.path.abspath(args.metadata)
    manifest_dir = os.path.dirname(metadata)

    if args.generate_only:
        if args.inputs:
            _parser().error("inputs cannot be used with --generate-only")
        manifest = read_manifest(metadata)
    else:
        paths = _expand_inputs(args.inputs)
        if not paths:
            _parser().error("at least one HDF5 input or glob is required")
        missing = [path for path in paths if not os.path.isfile(path)]
        if missing:
            _parser().error(f"input does not exist: {missing[0]}")
        if args.rebuild:
            manifest = build_manifest(paths, relative_to=manifest_dir)
            write_manifest(metadata, manifest)
        else:
            manifest = update_manifest(metadata, paths, relative_to=manifest_dir)

    written = build_xdmf_files(
        manifest,
        os.path.abspath(args.outdir),
        manifest_dir=manifest_dir,
    )
    print(f"manifest: {metadata} ({manifest.num_steps} steps)")
    for mesh_name, path in written.items():
        print(f"{mesh_name}: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""XDMF3 generation (manifest -> .xdmf, one file per mesh kind)."""

from .builder import build_xdmf_files

__all__ = ["build_xdmf_files"]

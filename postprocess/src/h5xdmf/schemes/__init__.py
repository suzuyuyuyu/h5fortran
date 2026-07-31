"""Scheme registry: map ``scheme_version`` -> :class:`Scheme` instance.

Register a new output format by importing it here and adding it to
``_REGISTRY``. Everything else (reader/writer/CLI) discovers it automatically.
"""

from __future__ import annotations

from .._version import __version__
from .base import SCHEME_VERSION_ATTR, Scheme
from .v1 import SchemeV1

CURRENT_SCHEME_VERSION = int(__version__.split(".", maxsplit=1)[0])

_REGISTRY: dict[int, Scheme] = {
    SchemeV1.version: SchemeV1(),
}

if CURRENT_SCHEME_VERSION not in _REGISTRY:
    raise RuntimeError(
        f"product major version {CURRENT_SCHEME_VERSION} has no registered HDF5 scheme"
    )


def get_scheme(version: int) -> Scheme:
    try:
        return _REGISTRY[int(version)]
    except KeyError as exc:
        known = ", ".join(str(v) for v in sorted(_REGISTRY))
        raise ValueError(
            f"unsupported scheme_version={version!r}; known versions: {known}"
        ) from exc


def available_versions() -> list[int]:
    return sorted(_REGISTRY)


__all__ = [
    "CURRENT_SCHEME_VERSION",
    "Scheme",
    "get_scheme",
    "available_versions",
    "SCHEME_VERSION_ATTR",
]

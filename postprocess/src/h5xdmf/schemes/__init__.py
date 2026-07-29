"""Scheme registry: map ``scheme_version`` -> :class:`Scheme` instance.

Register a new output format by importing it here and adding it to
``_REGISTRY``. Everything else (reader/writer/CLI) discovers it automatically.
"""

from __future__ import annotations

from .base import SCHEME_VERSION_ATTR, Scheme
from .v1 import SchemeV1

_REGISTRY: dict[int, Scheme] = {
    SchemeV1.version: SchemeV1(),
}


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


__all__ = ["Scheme", "get_scheme", "available_versions", "SCHEME_VERSION_ATTR"]

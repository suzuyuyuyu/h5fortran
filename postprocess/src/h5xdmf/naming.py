"""Snapshot filename ordering checks."""

from __future__ import annotations

import os
import re
from collections.abc import Sequence

_SEQUENCE_NAME = re.compile(r"^(.*?)(\d+)(\.[^.]+)$")


def validate_sequence_names(paths: Sequence[str]) -> None:
    """Require one zero-padding width for numbered files in the same run."""
    parsed = []
    for path in paths:
        match = _SEQUENCE_NAME.match(os.path.basename(path))
        if match is not None:
            parsed.append((path, match.group(1), match.group(2), match.group(3)))
    if len(parsed) < 2:
        return

    families = {(prefix, suffix) for _, prefix, _, suffix in parsed}
    if len(families) != 1:
        return
    widths = {len(number) for _, _, number, _ in parsed}
    if len(widths) != 1:
        raise ValueError(
            "snapshot sequence uses inconsistent zero-padding widths; "
            "use one width within a run (for example seq000001.h5)"
        )

    lexical = [path for path, *_ in parsed]
    chronological = [item[0] for item in sorted(parsed, key=lambda item: int(item[2]))]
    if lexical != chronological:
        raise ValueError("snapshot filenames are not lexically ordered by sequence number")

#!/usr/bin/env python3
"""Build a modern PNG-backed ICNS file without third-party dependencies."""

from __future__ import annotations

import argparse
import struct
from pathlib import Path


ICON_CHUNKS = (
    ("icp4", 16, "icon_16x16.png"),
    ("icp5", 32, "icon_32x32.png"),
    ("icp6", 64, "icon_64x64.png"),
    ("ic07", 128, "icon_128x128.png"),
    ("ic08", 256, "icon_256x256.png"),
    ("ic09", 512, "icon_512x512.png"),
    ("ic10", 1024, "icon_1024x1024.png"),
)
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def png_size(data: bytes) -> tuple[int, int]:
    if len(data) < 24 or not data.startswith(PNG_SIGNATURE):
        raise ValueError("input is not a valid PNG")
    return struct.unpack(">II", data[16:24])


def build(icon_directory: Path, output: Path) -> None:
    chunks: list[bytes] = []
    for chunk_type, expected_size, filename in ICON_CHUNKS:
        data = (icon_directory / filename).read_bytes()
        width, height = png_size(data)
        if (width, height) != (expected_size, expected_size):
            raise ValueError(
                f"{filename} must be {expected_size}x{expected_size}, "
                f"found {width}x{height}"
            )
        chunks.append(
            chunk_type.encode("ascii")
            + struct.pack(">I", len(data) + 8)
            + data
        )

    body = b"".join(chunks)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("icon_directory", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    build(args.icon_directory, args.output)


if __name__ == "__main__":
    main()

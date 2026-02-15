#!/usr/bin/env python3
"""
Copy PNG golden-test result files from source to target, removing the
`_testImage` (case-insensitive) portion from filenames while copying.
Used for using test failure images from CI runs to check in as new test image

Usage:
  python3 scripts/copy_golden_images.py /path/to/src /path/to/dst [--dry-run]

  Ex:
  While sitting in the root of the repo, I run:
  python3 scripts/copy_golden_images.py \
    '/Users/joefreeman/Downloads/adaptive_cards_golden_test_failures' \
        'packages/flutter_adaptive_cards_plus/test/gold_files'
"""

import argparse
import re
import shutil
import sys
from pathlib import Path
from typing import Iterable

# We'll match `_testImage` case-insensitively anywhere in the filename (before
# the extension) and remove it. This handles names with spaces and mixed-case
# extensions like `.PNG`.
_TESTIMAGE_RE = re.compile(r"(?i)_testimage")


def find_pngs(src: Path, recursive: bool) -> Iterable[Path]:
    """Return an iterator of PNG files in ``src``.

    The pattern is case-insensitive for the extension and supports recursive
    search when ``recursive`` is True.
    """
    pattern = "*.[pP][nN][gG]"
    return src.rglob(pattern) if recursive else src.glob(pattern)


def target_name(src_name: str) -> str:
    """Return the filename after removing one `_testImage` from the stem.

    Preserves the original extension and collapses redundant spaces or
    underscores produced by the removal.
    """
    path_obj = Path(src_name)
    suffix = path_obj.suffix
    stem = src_name[: -len(suffix)] if suffix else src_name

    new_stem = _TESTIMAGE_RE.sub("", stem, count=1)
    new_stem = re.sub(r"\s+", " ", new_stem).strip()
    new_stem = re.sub(r"_+", "_", new_stem)
    new_stem = new_stem.rstrip(" _")

    return f"{new_stem}{suffix}"


def copy_and_rename(
    src: Path, dst: Path, recursive: bool = True, dry_run: bool = False
) -> int:
    """Copy matching PNG files from ``src`` to ``dst`` with renames.

    Returns zero on success or a non-zero status code otherwise.
    """
    files = list(find_pngs(src, recursive))
    if not files:
        print(f"No PNG files found in {src} (recursive={recursive})")
        return 1

    dst.mkdir(parents=True, exist_ok=True)
    copied = 0
    skipped = 0

    for file_path in files:
        name = file_path.name
        if not _TESTIMAGE_RE.search(name):
            skipped += 1
            continue

        new_name = target_name(name)
        target_path = dst / new_name

        if dry_run:
            print(f"[dry-run] {file_path} -> {target_path}")
            copied += 1
            continue

        shutil.copy2(file_path, target_path)
        print(f"{file_path} -> {target_path}")
        copied += 1

    print(f"Completed. Copied: {copied}. Skipped (no match): {skipped}.")
    return 0


def parse_args():
    """
    Parses command-line arguments for copying and renaming golden PNG images.

    Returns:
        argparse.Namespace:
            Parsed command-line arguments with the following attributes:
            src (Path): Source directory to search for PNG files.
            dst (Path): Target directory to copy and rename PNG files.
            recursive (bool):
                Whether to search directories recursively (default: True).
            dry_run (bool):
            If True,
            only show what would be copied without performing any operations.
    """
    p = argparse.ArgumentParser(
        description="Copy golden PNGs and remove _testImage in names"
    )
    p.add_argument(
        "src", type=Path, help="Source directory to search for PNGs"
    )
    p.add_argument(
        "dst", type=Path, help="Target directory to copy renamed PNGs into"
    )
    p.add_argument(
        "--no-recursive",
        dest="recursive",
        action="store_false",
        help="Do not search recursively",
    )
    p.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="Show what would be copied without writing files",
    )
    return p.parse_args()


def main():
    """
    Main entry point for the script that copies and renames golden images.

    Parses command-line arguments to get source and destination directories,
    validates that the source directory exists,
    and executes the copy and rename operation.
    Returns appropriate exit codes for success or various error conditions.

    Returns:
        int: Exit code - 0 for success, 2 if source directory is invalid,
             3 if an error occurs during copy operation.
    """
    args = parse_args()
    src: Path = args.src
    dst: Path = args.dst
    if not src.exists() or not src.is_dir():
        print(
            f"Source directory does not exist or is not a directory: {src}",
            file=sys.stderr,
        )
        return 2
    try:
        return copy_and_rename(
            src, dst, recursive=args.recursive, dry_run=args.dry_run
        )
    except Exception as e:
        print("Error:", e, file=sys.stderr)
        return 3


if __name__ == "__main__":
    raise SystemExit(main())

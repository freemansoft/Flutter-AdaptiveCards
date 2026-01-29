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
        'packages/flutter_adaptive_cards/test/gold_files'
"""

import argparse
import re
import shutil
import sys
from pathlib import Path

# We'll match `_testImage` case-insensitively anywhere in the filename (before
# the extension) and remove it. This handles names with spaces and mixed-case
# extensions like `.PNG`.
_TESTIMAGE_RE = re.compile(r"(?i)_testimage")


def find_pngs(src: Path, recursive: bool):
    pattern = "*.[pP][nN][gG]"
    if recursive:
        return src.rglob(pattern)
    return src.glob(pattern)


def target_name(src_name: str) -> str:
    # Preserve the original suffix (case preserved), but remove the first
    # occurrence of `_testImage` (case-insensitive) from the stem. Then tidy
    # up whitespace/underscores that may be left behind.
    p = Path(src_name)
    suffix = p.suffix  # includes the dot
    stem = src_name[: -len(suffix)] if suffix else src_name

    # remove `_testImage` occurrences
    new_stem = _TESTIMAGE_RE.sub("", stem, count=1)

    # collapse multiple spaces and multiple underscores, and remove leading/trailing
    new_stem = re.sub(r"\s+", " ", new_stem).strip()
    new_stem = re.sub(r"_+", "_", new_stem)

    # if the stem ends with an underscore or space because of the removal, strip it
    new_stem = new_stem.rstrip(" _")

    return f"{new_stem}{suffix}"


def copy_and_rename(
    src: Path, dst: Path, recursive: bool = True, dry_run: bool = False
):
    files = list(find_pngs(src, recursive))
    if not files:
        print(f"No PNG files found in {src} (recursive={recursive})")
        return 1

    dst.mkdir(parents=True, exist_ok=True)
    copied = 0
    skipped = 0

    for f in files:
        name = f.name
        # only operate on names that contain `_testImage` (case-insensitive)
        if not _TESTIMAGE_RE.search(name):
            skipped += 1
            continue
        new_name = target_name(name)
        target_path = dst / new_name
        if dry_run:
            print(f"[dry-run] {f} -> {target_path}")
            copied += 1
            continue
        shutil.copy2(f, target_path)
        print(f"{f} -> {target_path}")
        copied += 1

    print(f"Completed. Copied: {copied}. Skipped (no match): {skipped}.")
    return 0


def parse_args():
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

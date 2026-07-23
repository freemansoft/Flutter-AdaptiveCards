#!/bin/sh
# Materializes the project-local .fvm/ symlinks for a fresh clone.
#
# .fvm/ is gitignored (it holds machine-specific symlinks), so a fresh clone has
# no .fvm/versions/<version> until fvm is run once. VS Code's committed
# dart.flutterSdkPath (.fvm/versions/<version>) points at nothing until then,
# and the Dart/Flutter extension can't find an SDK. `fvm install` reads the
# pinned version from .fvmrc and creates those links (offline if the SDK is
# already in the global fvm cache).
set -e
cd "$(dirname "$0")/.."

if ! command -v fvm >/dev/null 2>&1; then
  echo "setup-workspace: fvm not found on PATH." >&2
  echo "  Install it first, e.g.: brew install leoafarias/fvm/fvm" >&2
  echo "  See https://fvm.app/documentation/getting-started/installation" >&2
  exit 1
fi

echo "setup-workspace: installing pinned Flutter SDK from .fvmrc"
fvm install
echo "setup-workspace: .fvm/ links created — reload the VS Code window to pick up dart.flutterSdkPath"

echo "setup-workspace: activating pana (pub-score gate)"
fvm dart pub global activate pana 0.23.14

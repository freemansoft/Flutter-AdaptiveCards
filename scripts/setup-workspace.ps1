# Materializes the project-local .fvm/ symlinks for a fresh clone.
#
# .fvm/ is gitignored (it holds machine-specific symlinks), so a fresh clone has
# no .fvm/versions/<version> until fvm is run once. VS Code's committed
# dart.flutterSdkPath (.fvm/versions/<version>) points at nothing until then,
# and the Dart/Flutter extension can't find an SDK. `fvm install` reads the
# pinned version from .fvmrc and creates those links (offline if the SDK is
# already in the global fvm cache).
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if (-not (Get-Command fvm -ErrorAction SilentlyContinue)) {
  Write-Error @'
setup-workspace: fvm not found on PATH.
  Install it first, e.g.: choco install fvm
  See https://fvm.app/documentation/getting-started/installation
'@
  exit 1
}

Write-Host "setup-workspace: installing pinned Flutter SDK from .fvmrc"
fvm install
Write-Host "setup-workspace: .fvm\ links created - reload the VS Code window to pick up dart.flutterSdkPath"

# Creates adaptive_chat_server\.venv and installs its requirements if missing.
# Requires Python 3.10+: FastAPI evaluates PEP 604 `X | None` type hints at
# runtime, which raises `TypeError: Unable to evaluate type annotation` on 3.9
# and older.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\adaptive_chat_server")

function Test-PythonVersion {
  param([string]$Exe, [string[]]$ExeArgs)
  try {
    $checkArgs = $ExeArgs + @("-c", "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)")
    & $Exe @checkArgs 2>$null
    return $LASTEXITCODE -eq 0
  } catch {
    return $false
  }
}

function Find-Python {
  $candidates = @(
    @("py", "-3.13"),
    @("py", "-3.12"),
    @("py", "-3.11"),
    @("py", "-3.10"),
    @("python3"),
    @("python")
  )
  foreach ($c in $candidates) {
    $exe = $c[0]
    $exeArgs = @()
    if ($c.Length -gt 1) { $exeArgs = $c[1..($c.Length - 1)] }
    if (Get-Command $exe -ErrorAction SilentlyContinue) {
      if (Test-PythonVersion -Exe $exe -ExeArgs $exeArgs) {
        return $c
      }
    }
  }
  return $null
}

if (-not (Test-Path .venv\Scripts\python.exe)) {
  $pythonCmd = Find-Python
  if (-not $pythonCmd) {
    Write-Error "adaptive_chat_server: no Python 3.10+ interpreter found. FastAPI evaluates 'str | None' style type hints at runtime, which fails on Python 3.9 and older. Install a newer Python (e.g. from python.org) and ensure it's on PATH or available via the 'py' launcher."
    exit 1
  }
  $exe = $pythonCmd[0]
  $exeArgs = @()
  if ($pythonCmd.Length -gt 1) { $exeArgs = $pythonCmd[1..($pythonCmd.Length - 1)] }
  $versionStr = & $exe @($exeArgs + @("--version"))
  Write-Host "adaptive_chat_server: using $versionStr ($exe $($exeArgs -join ' '))"
  & $exe @($exeArgs + @("-m", "venv", ".venv"))
  .venv\Scripts\pip install -q -r requirements.txt
  Write-Host "adaptive_chat_server: .venv created and requirements installed"
} else {
  & .venv\Scripts\python.exe -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)"
  if ($LASTEXITCODE -ne 0) {
    Write-Error "adaptive_chat_server: existing .venv uses an older Python than 3.10. Delete adaptive_chat_server\.venv and re-run this task to rebuild it with a newer Python."
    exit 1
  }
  Write-Host "adaptive_chat_server: .venv already present"
}

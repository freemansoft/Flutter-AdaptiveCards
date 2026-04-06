param (
    [switch]$DryRun
)

$packages = @(
    "packages\flutter_adaptive_cards_fs",
    "packages\flutter_adaptive_charts_fs",
    "packages\flutter_adaptive_template_fs"
)

$rootDir = (Get-Item -Path ".\").FullName

foreach ($pkg in $packages) {
    $pkgDir = Join-Path -Path $rootDir -ChildPath $pkg
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Processing $pkg" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    if (Test-Path -Path $pkgDir) {
        Set-Location -Path $pkgDir

        Write-Host "Running dart format..." -ForegroundColor Yellow
        dart format .


        Write-Host "Publishing packet to pub.dev..." -ForegroundColor Yellow
        if ($DryRun) {
            flutter pub publish --dry-run
        } else {
            flutter pub publish
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Publish failed in $pkg." -ForegroundColor Red
            Set-Location -Path $rootDir
            exit 1
        }

    } else {
        Write-Host "Directory $pkgDir not found!" -ForegroundColor Red
    }
}

Set-Location -Path $rootDir
Write-Host "All packages processed successfully." -ForegroundColor Green

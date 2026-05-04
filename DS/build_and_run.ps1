# DNAsearch Build and Run Script

Write-Host "--- DNAsearch Build and Run Utility ---" -ForegroundColor Cyan

# 1. Build the project
if (-not (Test-Path "build")) {
    New-Item -ItemType Directory -Path "build" | Out-Null
}

Push-Location "build"
Write-Host "`nBuilding project..." -ForegroundColor Yellow
cmake .. -G "MinGW Makefiles"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: CMake configuration failed." -ForegroundColor Red
    Pop-Location
    exit $LASTEXITCODE
}

mingw32-make
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed." -ForegroundColor Red
    Pop-Location
    exit $LASTEXITCODE
}
Pop-Location

Write-Host "`nBuild successful! Executable is at build\bin\dna_search.exe" -ForegroundColor Green

# 2. Ask if user wants to run with sample data
$choice = Read-Host "`nDo you want to run a sample search now? (y/n)"
if ($choice -eq 'y') {
    $pattern = Read-Host "Enter DNA pattern to search (e.g., ATGCGT)"
    if ([string]::IsNullOrWhiteSpace($pattern)) { $pattern = "ATGCGT" }
    
    Write-Host "`nRunning: .\build\bin\dna_search.exe .\data\sequences\sample.fasta $pattern" -ForegroundColor Gray
    .\build\bin\dna_search.exe .\data\sequences\sample.fasta $pattern
}

Write-Host "`nTo run manually, use:" -ForegroundColor Cyan
Write-Host ".\build\bin\dna_search.exe <fasta_file> [pattern]"

$ErrorActionPreference = "Stop"

# WinLibs x86_64 GCC + MinGW-w64, UCRT, POSIX threads.
# Internet is needed only once to download the toolchain.
$downloadUrl = "https://github.com/brechtsanders/winlibs_mingw/releases/download/16.2.0posix-23.1.3-14.0.0-ucrt-r3/winlibs-x86_64-posix-seh-gcc-16.2.0-mingw-w64ucrt-14.0.0-r3.zip"

$featureDir = $PSScriptRoot
$installDir = Join-Path $featureDir "gcc"
$tempDir = Join-Path $env:TEMP ("godot-gcc-" + [Guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $tempDir "winlibs-gcc.zip"
$extractDir = Join-Path $tempDir "extracted"

try {
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

    Write-Host "Downloading official WinLibs GCC 16.2.0 package..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath

    Write-Host "Extracting toolchain..."
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractDir -Force

    $compiler = Get-ChildItem -LiteralPath $extractDir -Filter "g++.exe" -File -Recurse |
        Where-Object { $_.FullName -match "\\mingw64\\bin\\g\+\+\.exe$" } |
        Select-Object -First 1

    if (-not $compiler) {
        throw "The downloaded archive did not contain mingw64\bin\g++.exe."
    }

    # g++.exe is <toolchain-root>\mingw64\bin\g++.exe
    $toolchainRoot = Split-Path (Split-Path $compiler.FullName -Parent) -Parent

    if (Test-Path $installDir) {
        Remove-Item -LiteralPath $installDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    Copy-Item -Path (Join-Path $toolchainRoot "*") -Destination $installDir -Recurse -Force

    $gccExe = Join-Path $installDir "bin\g++.exe"
    if (-not (Test-Path $gccExe)) {
        throw "GCC copy failed: $gccExe was not found."
    }

    $env:PATH = (Join-Path $installDir "bin") + ";" + $env:PATH
    Write-Host "Checking compiler version..."
    & $gccExe --version
    if ($LASTEXITCODE -ne 0) {
        throw "GCC could not start successfully."
    }

    $sampleCpp = Join-Path $tempDir "cpp17_check.cpp"
    $sampleExe = Join-Path $tempDir "cpp17_check.exe"
    Set-Content -LiteralPath $sampleCpp -Encoding ASCII -Value '#include <iostream>
#include <string>
int main() { std::string s = "C++17"; std::cout << s; return 0; }'

    Write-Host "Checking C++17 compilation..."
    & $gccExe "-std=c++17" $sampleCpp "-o" $sampleExe
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $sampleExe)) {
        throw "The C++17 test program did not compile."
    }

    Write-Host "Checking test program..."
    & $sampleExe
    if ($LASTEXITCODE -ne 0) {
        throw "The C++17 test program did not run successfully."
    }

    Write-Host ""
    Write-Host "GCC is installed successfully at:"
    Write-Host $gccExe
    Write-Host "The game can now use the bundled compiler without requiring GCC in PATH."
}
catch {
    Write-Error $_
    exit 1
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

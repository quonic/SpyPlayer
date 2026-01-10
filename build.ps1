#!/usr/bin/env pwsh

param(
    [ValidateSet("Debug", "Release")]
    [string]$Build = "Release"
)

$outputDir = "dist"

$BuildExecutableFile = ""
$BuildOS = ""
$BuildArch = ""

if ($IsLinux) {
    $BuildOS = "linux"
    $BuildArch = "x86_64"
    $BuildExecutableFile = "SpyPlayer"
}
else {
    $BuildOS = "windows"
    $BuildArch = "x86_64"
    $BuildExecutableFile = "SpyPlayer.exe"
}

# Check if Odin is installed
if (!(Get-Command odin -ErrorAction SilentlyContinue)) {
    Write-Error "Odin is not installed. Please install Odin first."
    exit 1
}

if (Test-Path $outputDir -ErrorAction SilentlyContinue) {
    Remove-Item -Recurse -Force $outputDir
    Write-Host "Cleaned build directory: $outputDir"
}

if (-not (Test-Path $outputDir -ErrorAction SilentlyContinue)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Build the project
if ($Build -like "Debug") {
    Write-Host "Building in Debug mode"
    # Build with or without our debug options
    odin build . -debug -o:speed -define:leaks=true -define:trace=true -out:$BuildExecutableFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed"
        exit 1
    }
}
if ($Build -like "Release") {
    # Build with or without our debug options
    odin build . -o:speed -out:$BuildExecutableFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed"
        exit 1
    }
}
else {
    Write-Error "Unknown build configuration: $Build"
    exit 1
}

# Package the build
if ($Build -like "Release") {

    $ErrorActionPreference = "Stop"

    if (Test-Path $outputDir -ErrorAction SilentlyContinue) {
        Remove-Item -Recurse -Force $outputDir
        Write-Host "Cleaned build directory: $outputDir"
    }

    Write-Host "Packaging the build"
    if (-not (Test-Path $outputDir -ErrorAction SilentlyContinue)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    Copy-Item -Path $BuildExecutableFile -Destination "$outputDir/$BuildExecutableFile" -Force

    # Copy assets
    if (Test-Path "assets") {
        if (Test-Path "$outputDir/assets" -ErrorAction SilentlyContinue) {
            Remove-Item -Recurse -Force "$outputDir/assets"
        }
        New-Item -ItemType Directory -Path "$outputDir/assets" | Out-Null
        Copy-Item -Path "assets/*" -Destination "$outputDir/assets" -Filter "*.png" -Force
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipFile = "$outputDir/SpyPlayer_$($timestamp)_$($BuildOS)_$($BuildArch).zip"
    Compress-Archive -Path "$outputDir/$BuildExecutableFile", "$outputDir/assets" -DestinationPath $zipFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Packaging failed"
        exit 1
    }
    Write-Host "Packaged to $zipFile"

    # Clean up copied files
    Remove-Item -Force "$outputDir/$BuildExecutableFile"
    Remove-Item -Recurse -Force "$outputDir/assets"
}

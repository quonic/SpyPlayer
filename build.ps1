#!/usr/bin/env pwsh

param(
    [switch]$trace,
    [switch]$leaks,
    [switch]$vet
)

if (!(Get-Command odin -ErrorAction SilentlyContinue)) {
    Write-Error "Odin is not installed. Please install Odin first."
    exit 1
}

$_vet = ""
if ($vet) {
    $_vet = "-vet"
}

# Validate that building with "-vet -define:leaks=true -define:trace=true" we don't have build errors
odin build . $_vet -define:leaks=true -define:trace=true
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

# Build with or without our debug options
odin build . -debug -o:speed -define:leaks=$(if ($leaks) { "true" } else { "false" }) -define:trace=$(if ($trace) { "true" } else { "false" })
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}
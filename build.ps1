#!/usr/bin/env pwsh

param(
    [switch]$trace,
    [switch]$leaks
)

if (!(Get-Command odin -ErrorAction SilentlyContinue)) {
    Write-Error "Odin is not installed. Please install Odin first."
    exit 1
}

# Validate that building with "-vet -define:leaks=true -define:trace=true" we don't have build errors
odin build . -vet -define:leaks=true -define:trace=true
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

# Build with or without our debug options
odin build . -define:leaks=$(if ($leaks) { "true" } else { "false" }) -define:trace=$(if ($trace) { "true" } else { "false" })
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}
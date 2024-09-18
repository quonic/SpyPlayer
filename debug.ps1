#!/usr/bin/env pwsh

# Build with or without our debug options
odin build . -debug
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

if ((Get-Command insight -ErrorAction SilentlyContinue).Count -gt 0) {
    if ($IsWindows) {
        insight.exe ./SpyPlayer
    }
    elseif ($IsLinux) {
        insight ./SpyPlayer
    }
    else {
        Write-Error "Unsupported platform"
        exit 1
    }
}
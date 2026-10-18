# Builds dist/StarlightRescue.love and a standalone Windows build in dist/StarlightRescue-win/
# Usage: powershell -ExecutionPolicy Bypass -File build.ps1 [-LovePath "C:\Program Files\LOVE"]
param([string]$LovePath = "C:\Program Files\LOVE")

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$name = "StarlightRescue"
$dist = Join-Path $root "dist"

if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
New-Item -ItemType Directory -Path $dist | Out-Null

# 1. The .love file is a zip of the game. Built by hand because Compress-Archive in
#    Windows PowerShell writes backslash paths, which LÖVE can't read.
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$loveFile = Join-Path $dist "$name.love"
$files = @("main.lua", "conf.lua") + (Get-ChildItem -Path (Join-Path $root "src") -Recurse -File |
    ForEach-Object { $_.FullName.Substring($root.Length + 1) })

$archive = [System.IO.Compression.ZipFile]::Open($loveFile, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($relative in $files) {
        $entryName = $relative -replace '\\', '/'
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, (Join-Path $root $relative), $entryName) | Out-Null
    }
} finally {
    $archive.Dispose()
}

# 2. Windows build: love.exe with the .love appended, plus LÖVE's DLLs
$winDir = Join-Path $dist "$name-win"
New-Item -ItemType Directory -Path $winDir | Out-Null
$exe = Join-Path $winDir "$name.exe"

$out = [System.IO.File]::Create($exe)
try {
    foreach ($source in @((Join-Path $LovePath "love.exe"), $loveFile)) {
        $in = [System.IO.File]::OpenRead($source)
        try { $in.CopyTo($out) } finally { $in.Dispose() }
    }
} finally {
    $out.Dispose()
}
Copy-Item (Join-Path $LovePath "*.dll") $winDir
Copy-Item (Join-Path $LovePath "license.txt") $winDir

Write-Host "Built $loveFile"
Write-Host "Built $exe"

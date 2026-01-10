#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Publish DbCli for all platforms (Windows, Linux, macOS)
    
.DESCRIPTION
    This script publishes DbCli to multiple platforms with proper directory structure
    
.EXAMPLE
    .\publish-all.ps1

.EXAMPLE
    # Publish only one runtime identifier (RID)
    .\publish-all.ps1 -Platform win-x64

.EXAMPLE
    # Publish only one OS family
    .\publish-all.ps1 -Platform windows
#>

[CmdletBinding()]
param(
    # all | windows | linux | macos | win-x64 | win-arm64 | linux-x64 | linux-arm64 | macos-x64 | macos-arm64
    # Note: dotnet uses RID "osx-x64"/"osx-arm64". We accept legacy "osx-*" too.
    [Parameter()][string]$Platform = "all",

    # Version string used for zip naming (e.g. 1.2.3). In CI, pass the tag version.
    [Parameter()][string]$Version
)

$ErrorActionPreference = "Stop"

# Avoid garbled non-ASCII output (e.g., dotnet restore/publish messages) in some terminals.
try {
    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    $OutputEncoding = [Text.Encoding]::UTF8
} catch {
    # ignore
}

Write-Host "🚀 DbCli Multi-Platform Publisher" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

$version = if ($Version -and -not [string]::IsNullOrWhiteSpace($Version)) { $Version.Trim() } else { "0.0.0-dev" }

# Platform configurations
$platforms = @(
    @{ Name = "Windows x64";     Runtime = "win-x64";      Archive = "win-x64";      Ext = ".exe";  DistDir = "dist-win-x64" }
    @{ Name = "Windows ARM64";   Runtime = "win-arm64";    Archive = "win-arm64";    Ext = ".exe";  DistDir = "dist-win-arm64" }
    @{ Name = "Linux x64";       Runtime = "linux-x64";    Archive = "linux-x64";    Ext = "";      DistDir = "dist-linux-x64" }
    @{ Name = "Linux ARM64";     Runtime = "linux-arm64";  Archive = "linux-arm64";  Ext = "";      DistDir = "dist-linux-arm64" }
    @{ Name = "macOS x64";       Runtime = "osx-x64";      Archive = "macos-x64";    Ext = "";      DistDir = "dist-macos-x64" }
    @{ Name = "macOS ARM64";     Runtime = "osx-arm64";    Archive = "macos-arm64";  Ext = "";      DistDir = "dist-macos-arm64" }
)

function Resolve-TargetPlatforms {
    param(
        [Parameter(Mandatory = $true)][array]$All,
        [Parameter(Mandatory = $true)][string]$Platform
    )

    $p = ($Platform ?? "all").Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($p) -or $p -eq "all") { return @($All) }

    # Normalize macos-* aliases to dotnet RIDs.
    $p = switch ($p) {
        "macos-x64" { "osx-x64" }
        "macos-arm64" { "osx-arm64" }
        default { $p }
    }

    $allowed = @(
        "windows", "linux", "macos",
        "win-x64", "win-arm64", "linux-x64", "linux-arm64",
        "macos-x64", "macos-arm64",
        "osx-x64", "osx-arm64" # legacy
    )
    if ($allowed -notcontains $p) {
        throw "Unknown -Platform '$Platform'. Allowed: all, windows, linux, macos, win-x64, win-arm64, linux-x64, linux-arm64, macos-x64, macos-arm64 (legacy: osx-x64, osx-arm64)"
    }

    if ($p -in @("windows", "linux", "macos")) {
        $prefix = switch ($p) {
            "windows" { "win-" }
            "linux" { "linux-" }
            "macos" { "osx-" }
        }
        return @($All | Where-Object { $_['Runtime'] -like "$prefix*" })
    }

    return @($All | Where-Object { $_['Runtime'] -eq $p })
}

$targetPlatforms = Resolve-TargetPlatforms -All $platforms -Platform $Platform
Write-Host "Target: $Platform" -ForegroundColor Gray

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
if (($Platform ?? "all").Trim().ToLowerInvariant() -eq "all") {
    Remove-Item -Recurse -Force .\dist-* -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force .\publish -ErrorAction SilentlyContinue
    Remove-Item .\dbcli-*.zip -ErrorAction SilentlyContinue
}
else {
    foreach ($tp in $targetPlatforms) {
        Remove-Item -Recurse -Force ".\$($tp['DistDir'])" -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force ".\publish\$($tp['Runtime'])" -ErrorAction SilentlyContinue
        Remove-Item ".\dbcli-$($tp['Runtime'])-v$version.zip" -ErrorAction SilentlyContinue
        if ($tp.ContainsKey('Archive') -and $tp['Archive']) {
            Remove-Item ".\dbcli-$($tp['Archive'])-v$version.zip" -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "✅ Cleaned`n" -ForegroundColor Green

# Publish each platform
foreach ($tp in $targetPlatforms) {
    Write-Host "📦 Publishing $($tp['Name'])..." -ForegroundColor Cyan
    
    $publishDir = ".\publish\$($tp['Runtime'])"
    
    try {
        # Publish using the project file directly (not solution)
        dotnet publish dbcli.csproj `
            -c Release `
            -r $tp['Runtime'] `
            --self-contained `
            -o $publishDir `
            -p:PublishSingleFile=true `
            -p:DebugType=None `
            -p:DebugSymbols=false
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Published successfully" -ForegroundColor Green
            
            # Create distribution directory
            $distDir = $tp['DistDir']
            New-Item -ItemType Directory -Path $distDir -Force | Out-Null
            
            # Copy executable
            $exeName = "dbcli$($tp['Ext'])"
            Copy-Item "$publishDir\$exeName" "$distDir\" -Force
            
            # Copy deployment scripts
            Copy-Item ".\deploy-skills.ps1" "$distDir\" -Force -ErrorAction SilentlyContinue
            Copy-Item ".\deploy-skills.py" "$distDir\" -Force -ErrorAction SilentlyContinue

            # Copy install scripts (required by deploy-skills.ps1 -InstallScripts)
            Copy-Item ".\install-dbcli.ps1" "$distDir\" -Force -ErrorAction SilentlyContinue
            Copy-Item ".\install-dbcli.py" "$distDir\" -Force -ErrorAction SilentlyContinue
            
            # Copy skills directory
            Copy-Item ".\skills" "$distDir\" -Recurse -Force -ErrorAction SilentlyContinue

            # Remove README docs from published artifacts (keep SKILL.md files)
            Remove-Item "$distDir\README*.md" -Force -ErrorAction SilentlyContinue
            Remove-Item "$distDir\skills\README*.md" -Force -ErrorAction SilentlyContinue
            
            # Create zip
            $zipRid = if ($tp.ContainsKey('Archive') -and $tp['Archive']) { $tp['Archive'] } else { $tp['Runtime'] }
            $zipName = "dbcli-$zipRid-v$version.zip"
            Write-Host "  📦 Creating $zipName..." -ForegroundColor Gray
            Compress-Archive -Path "$distDir\*" -DestinationPath $zipName -Force
            
            # Show size
            $size = [math]::Round((Get-Item $zipName).Length / 1MB, 2)
            Write-Host "  ✅ Created: $zipName ($size MB)`n" -ForegroundColor Green
        }
        else {
            Write-Host "  ❌ Failed to publish $($tp['Name'])`n" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  ❌ Error: $_`n" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n================================" -ForegroundColor Green
Write-Host "✅ Publishing Complete!" -ForegroundColor Green
Write-Host "================================`n" -ForegroundColor Green

$platformKey = ($Platform ?? "all").Trim().ToLowerInvariant()
$isAll = $platformKey -eq "all"

Write-Host "📦 Distribution Packages:" -ForegroundColor Cyan
if ($isAll) {
    Get-ChildItem .\dbcli-*.zip | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  • $($_.Name) - $size MB" -ForegroundColor Gray
    }
}
else {
    foreach ($tp in $targetPlatforms) {
        $zipRid = if ($tp.ContainsKey('Archive') -and $tp['Archive']) { $tp['Archive'] } else { $tp['Runtime'] }
        $zipName = "dbcli-$zipRid-v$version.zip"
        if (Test-Path ".\$zipName") {
            $size = [math]::Round((Get-Item ".\$zipName").Length / 1MB, 2)
            Write-Host "  • $zipName - $size MB" -ForegroundColor Gray
        }
        else {
            Write-Host "  • $zipName - (not created)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n📂 Distribution Directories:" -ForegroundColor Cyan
if ($isAll) {
    Get-ChildItem -Directory .\dist-* | ForEach-Object {
        Write-Host "  • $($_.Name)\" -ForegroundColor Gray
    }
}
else {
    foreach ($tp in $targetPlatforms) {
        Write-Host "  • $($tp['DistDir'])\" -ForegroundColor Gray
    }
}

if ($isAll) {
    Write-Host "`n🎉 All platforms published successfully!" -ForegroundColor Green
    Write-Host "Ready to distribute:`n"
    Write-Host "  Windows: dbcli-win-x64-v$version.zip, dbcli-win-arm64-v$version.zip" -ForegroundColor White
    Write-Host "  Linux:   dbcli-linux-x64-v$version.zip, dbcli-linux-arm64-v$version.zip" -ForegroundColor White
    Write-Host "  macOS:   dbcli-macos-x64-v$version.zip, dbcli-macos-arm64-v$version.zip" -ForegroundColor White
}
else {
    Write-Host "`n🎉 Selected platform(s) published successfully!" -ForegroundColor Green
    Write-Host "Ready to distribute: $Platform" -ForegroundColor White
}

Write-Host ""

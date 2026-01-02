#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install DbCli executable + deployment scripts into ~/tools/dbcli

.DESCRIPTION
    Installs the DbCli executable, deploy scripts, skills, and docs into
    the user's tools directory and optionally adds it to PATH.

.PARAMETER AddToPath
    Force add DbCli to PATH

.PARAMETER FixUserPath
    Normalize user PATH (trim, de-dup) and ensure a trailing ';' (Windows only)

.PARAMETER Force
    Overwrite existing installation

.EXAMPLE
    .\install-dbcli.ps1

.EXAMPLE
    .\install-dbcli.ps1 -AddToPath
#>

param(
    [switch]$Force,
    [switch]$AddToPath,
    [switch]$FixUserPath
)

$ErrorActionPreference = "Stop"

function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Cyan }
function Write-Warning { Write-Host "⚠️  $args" -ForegroundColor Yellow }
function Write-Error-Custom { Write-Host "❌ $args" -ForegroundColor Red }

function Normalize-PathParts {
    param([string[]]$Parts)
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $result = New-Object 'System.Collections.Generic.List[string]'
    foreach ($part in $Parts) {
        if ($seen.Add($part)) {
            [void]$result.Add($part)
        }
    }
    return ,$result.ToArray()
}

function Remove-PathEntry {
    param(
        [string[]]$Parts,
        [string]$Entry
    )
    $result = New-Object 'System.Collections.Generic.List[string]'
    foreach ($part in $Parts) {
        if (-not $part.Equals($Entry, [System.StringComparison]::OrdinalIgnoreCase)) {
            [void]$result.Add($part)
        }
    }
    return ,$result.ToArray()
}

function Get-ScriptDir {
    if ($MyInvocation.MyCommand.Path) {
        return (Split-Path -Parent $MyInvocation.MyCommand.Path)
    }
    if ($PSScriptRoot) {
        return $PSScriptRoot
    }
    return (Get-Location).Path
}

function Get-DbCliDistDirs {
    # Prefer the current platform's dist folder so WSL/Linux doesn't accidentally pick dbcli.exe.
    if ($IsWindows) {
        $osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
        $isArm64Windows = $osArch -eq "Arm64"
        return @(
            $(if ($isArm64Windows) { "dist-win-arm64" } else { "dist-win-x64" })
        )
    }
    elseif ($IsMacOS) {
        return @(
            "dist-macos-x64",
            "dist-macos-arm64",
            "dist-linux-x64",
            "dist-linux-arm64",
            "dist-win-x64",
            "dist-win-arm64"
        )
    }
    else {
        # Linux/WSL and other Unix-like platforms
        return @(
            "dist-linux-x64",
            "dist-linux-arm64",
            "dist-macos-x64",
            "dist-macos-arm64",
            "dist-win-x64",
            "dist-win-arm64"
        )
    }
}

function Test-IsSkillsDir {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Dir
    )

    if (-not $Dir -or -not (Test-Path $Dir)) { return $false }
    if (-not (Test-Path (Join-Path $Dir "INTEGRATION.md"))) { return $false }
    if (Test-Path (Join-Path $Dir "dbcli-query/SKILL.md")) { return $true }

    # Fallback: any SKILL.md in the tree (keeps working even if README.md is removed from release zips)
    $anySkill = Get-ChildItem -Path $Dir -Recurse -Filter "SKILL.md" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    return [bool]$anySkill
}

function Find-DbCliExecutable {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptDir
    )

    # Priority 1: dist-* directories
    foreach ($distDir in (Get-DbCliDistDirs)) {
        $distPath = Join-Path $ScriptDir $distDir
        if (-not (Test-Path $distPath)) { continue }

        $exeInDist = Get-ChildItem -Path $distPath -Filter "dbcli*" -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Extension -eq ".exe" -or ($_.Extension -eq "" -and $_.Name -eq "dbcli")
        } | Select-Object -First 1

        if ($exeInDist) {
            return $exeInDist
        }
    }

    # Priority 2: current directory
    if (Test-Path $ScriptDir) {
        $localExe = Get-ChildItem -Path $ScriptDir -Filter "dbcli*" -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Extension -eq ".exe" -or ($_.Extension -eq "" -and $_.Name -eq "dbcli")
        } | Select-Object -First 1
        if ($localExe) {
            return $localExe
        }
    }

    # Priority 3: build output directories (best-effort)
    $netRootRelease = Join-Path $ScriptDir "bin/Release/net10.0"
    $netRootDebug = Join-Path $ScriptDir "bin/Debug/net10.0"
    foreach ($root in @($netRootRelease, $netRootDebug)) {
        if (-not (Test-Path $root)) { continue }
        $exe = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -eq "dbcli" -or $_.Name -eq "dbcli.exe"
        } | Select-Object -First 1
        if ($exe) {
            return $exe
        }
    }

    # Priority 4: PATH
    $pathCommands = @()
    $cmd = Get-Command dbcli -ErrorAction SilentlyContinue
    if ($cmd) { $pathCommands += $cmd }
    $cmdExe = Get-Command dbcli.exe -ErrorAction SilentlyContinue
    if ($cmdExe) { $pathCommands += $cmdExe }

    foreach ($command in $pathCommands) {
        if ($command.CommandType -eq "Application" -and $command.Source -and (Test-Path $command.Source)) {
            return (Get-Item $command.Source)
        }
    }

    return $null
}

function Add-ToPath-Unix {
    param(
        [Parameter(Mandatory=$true)]
        [string]$InstallDir,
        [switch]$AddToPath
    )

    $installDirResolved = $InstallDir
    $pathParts = ($env:PATH -split ":")
    if ($pathParts -contains $installDirResolved) {
        Write-Success "Already in PATH"
        return
    }

    Write-Warning "DbCli is not in your PATH"
    Write-Info "Location: $installDirResolved"

    if ($AddToPath) {
        Write-Info "Adding to PATH (automatic)..."
    }
    else {
        Write-Info "Adding to PATH (default)..."
    }

    $profileFile = Join-Path $UserHome ".profile"
    $zshrcFile = Join-Path $UserHome ".zshrc"
    $exportLine = 'export PATH="' + $installDirResolved + ':$PATH"'

    function Ensure-ExportInFile {
        param([Parameter(Mandatory=$true)][string]$FilePath)

        if (-not (Test-Path $FilePath)) {
            New-Item -ItemType File -Path $FilePath -Force | Out-Null
        }
        $content = ""
        try { $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue } catch { $content = "" }
        if ($content -and $content.Contains($installDirResolved)) {
            return $false
        }

        Add-Content -Path $FilePath -Value "`n# DbCli`n$exportLine`n" -Encoding UTF8
        return $true
    }

    $changedProfile = Ensure-ExportInFile -FilePath $profileFile

    # If user uses zsh or already has .zshrc, also add there.
    if ((Test-Path $zshrcFile) -or ($env:SHELL -and $env:SHELL.EndsWith("zsh"))) {
        [void](Ensure-ExportInFile -FilePath $zshrcFile)
    }

    # Update current session so subsequent steps can run dbcli immediately.
    $env:PATH = "${installDirResolved}:$env:PATH"

    if ($changedProfile) {
        Write-Success "Added to PATH in $profileFile"
    }
    else {
        Write-Success "PATH entry already present in $profileFile"
    }
    Write-Warning "Run: source $profileFile (or restart your terminal)"
}

# Resolve home directory in a cross-platform way (Windows + pwsh on Linux/WSL/macOS)
$UserHome = [Environment]::GetFolderPath("UserProfile")
if (-not $UserHome) {
    $UserHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
}

$scriptDir = Get-ScriptDir
$toolsDir = Join-Path $UserHome "tools/dbcli"
$SkillsSourceDir = $null

$scriptSkills = Join-Path $scriptDir "skills"
if (Test-IsSkillsDir -Dir $scriptSkills) {
    $SkillsSourceDir = $scriptSkills
}
else {
    $toolsSkills = Join-Path $toolsDir "skills"
    if (Test-IsSkillsDir -Dir $toolsSkills) {
        $SkillsSourceDir = $toolsSkills
    }
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "DbCli Install" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

$exePath = Find-DbCliExecutable -ScriptDir $scriptDir
if ($exePath) {
    $distHint = Split-Path -Leaf (Split-Path -Parent $exePath.FullName)
    Write-Info "Found: $distHint/$($exePath.Name)"
}

if (-not $exePath) {
    Write-Error-Custom "DbCli executable not found"
    Write-Warning "Build the project first: dotnet build -c Release"
    exit 1
}

$sourceDir = Split-Path -Parent $exePath.FullName
$installDir = $toolsDir
Write-Info "Installing to: $installDir"

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

$sourceResolved = [System.IO.Path]::GetFullPath($sourceDir)
$installResolved = [System.IO.Path]::GetFullPath($installDir)

if ($sourceResolved -eq $installResolved) {
    Write-Warning "Source and install directory are the same; skipping binary copy"
}
else {
    Write-Info "Copying binaries from: $sourceDir"
    Copy-Item (Join-Path $sourceDir "*") -Destination $installDir -Recurse -Force -Exclude "skills"
}

foreach ($scriptName in @("deploy-skills.ps1", "deploy-skills.py", "install-dbcli.ps1", "install-dbcli.py")) {
    $scriptPath = Join-Path $scriptDir $scriptName
    if (Test-Path $scriptPath) {
        if ($sourceResolved -eq $installResolved -and (Join-Path $installDir $scriptName) -eq $scriptPath) {
            continue
        }
        Copy-Item $scriptPath -Destination $installDir -Force
        Write-Host "  ✓ $scriptName" -ForegroundColor Gray
    }
}

if ($SkillsSourceDir -and (Test-IsSkillsDir -Dir $SkillsSourceDir)) {
    $destSkillsDir = Join-Path $installDir "skills"
    $skillsResolved = [System.IO.Path]::GetFullPath($SkillsSourceDir)
    $destResolved = [System.IO.Path]::GetFullPath($destSkillsDir)

    if ($skillsResolved -ne $destResolved) {
        if (Test-Path $destSkillsDir) {
            Remove-Item -Recurse -Force $destSkillsDir
        }
        Copy-Item $SkillsSourceDir -Destination $destSkillsDir -Recurse -Force
        Write-Host "  ✓ skills/ (source)" -ForegroundColor Gray
    }
    else {
        Write-Warning "Skills already in tools directory; skipping skills copy"
    }
}

foreach ($docName in @("README.md", "LICENSE")) {
    $docPath = Join-Path $scriptDir $docName
    if (Test-Path $docPath) {
        $destDoc = Join-Path $installDir $docName
        if ([System.IO.Path]::GetFullPath($docPath) -ne [System.IO.Path]::GetFullPath($destDoc)) {
            Copy-Item $docPath -Destination $installDir -Force
            Write-Host "  ✓ $docName" -ForegroundColor Gray
        }
    }
}

Write-Success "Installed $($exePath.Name) to $installDir"

if ($IsWindows) {
    $pathScope = "User"
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($null -eq $currentPath) { $currentPath = "" }
    $pathEntry = $installDir
    $pathParts = @()
    if ($currentPath) {
        $pathParts = $currentPath -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
    $pathParts = Normalize-PathParts -Parts $pathParts

    if ($FixUserPath) {
        $fixedPath = if ($pathParts.Count -gt 0) { ($pathParts -join ";") + ";" } else { "" }
        if ($fixedPath -ne $currentPath) {
            [Environment]::SetEnvironmentVariable("PATH", $fixedPath, "User")
            $currentPath = $fixedPath
            Write-Success "Normalized user PATH"
        }
    }

    $inPath = $pathParts -contains $pathEntry

    if (-not $inPath) {
        Write-Warning "DbCli is not in your PATH"
        Write-Info "Location: $installDir"

        if ($AddToPath) {
            Write-Info "Adding to PATH (User, append, automatic)..."
        }
        else {
            Write-Info "Adding to PATH (User, append, default)..."
        }
        try {
            $pathPartsNoEntry = Remove-PathEntry -Parts $pathParts -Entry $pathEntry
            $newParts = $pathPartsNoEntry + $pathEntry
            $newPath = $newParts -join ";"
            if ($FixUserPath -and $newPath -and -not $newPath.EndsWith(";")) {
                $newPath += ";"
            }

            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

            $sessionParts = $env:PATH -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            $sessionParts = Normalize-PathParts -Parts $sessionParts
            if (-not ($sessionParts -contains $pathEntry)) {
                $sessionNoEntry = Remove-PathEntry -Parts $sessionParts -Entry $pathEntry
                $sessionParts = $sessionNoEntry + $pathEntry
                $env:PATH = $sessionParts -join ";"
            }

            Write-Success "Added to PATH"
            Write-Warning "Restart your terminal for changes to take effect"
        }
        catch {
            Write-Error-Custom "Failed to add to PATH: $_"
            Write-Warning "Add manually: $installDir"
        }
    }
    else {
        $sessionParts = $env:PATH -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        $sessionParts = Normalize-PathParts -Parts $sessionParts
        if (-not ($sessionParts -contains $pathEntry)) {
            $sessionNoEntry = Remove-PathEntry -Parts $sessionParts -Entry $pathEntry
            $sessionParts = $sessionNoEntry + $pathEntry
            $env:PATH = $sessionParts -join ";"
            Write-Success "Already in PATH (User); updated current session PATH"
        }
        else {
            Write-Success "Already in PATH"
        }
    }
}
else {
    Add-ToPath-Unix -InstallDir $installDir -AddToPath:$AddToPath
}

Write-Host ""

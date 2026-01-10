#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy DbCli Skills to Claude Code / OpenAI Codex environments

.DESCRIPTION
    This script deploys DbCli skills to AI assistant environments:
    - Claude Code: ./.claude/skills/dbcli (when running inside this repo), otherwise ~/.claude/skills/dbcli
    - GitHub Copilot: .github/copilot-instructions.md
    - OpenAI Codex: .codex/skills/dbcli (USER: ~/.codex, REPO: ./.codex)
    - Project workspace: ./skills/dbcli (for Cursor/Cline/Roo/Kilo/etc)

.PARAMETER Target
    Target environment: claude, copilot, codex, workspace, or all

.PARAMETER GlobalClaudeDir
    Custom Claude directory (default: repo ./.claude if detected, otherwise ~/.claude)

.PARAMETER WorkDir
    Target workspace directory for deployment outputs (and where deploy scripts will be copied)

.PARAMETER CodexGlobalOnly
    Deploy Codex skills to USER profile only (~/.codex) and skip repo/workspace outputs

.PARAMETER InstallScripts
    Install DbCli executable + deployment scripts (deploy-skills.ps1/py) to ~/tools/dbcli

.PARAMETER AddToPath
    Force add DbCli to PATH when -InstallScripts is used

.PARAMETER Force
    Overwrite existing installation

.PARAMETER PackageClaudeSkill
    Create Claude (Web/App) upload ZIP(s) for one or more skills (packaging-only mode)

.PARAMETER PackageClaudeAll
    Create Claude (Web/App) upload ZIPs for all skills (packaging-only mode)

.PARAMETER PackageOutDir
    Output directory for packaged Claude ZIPs (default: .)

.EXAMPLE
    .\deploy-skills.ps1 -Target claude -WorkDir .
    Deploy to Claude Code only

.EXAMPLE
    .\deploy-skills.ps1 -Target all -WorkDir . -Force
    Deploy to all environments, overwriting existing files

.EXAMPLE
    .\deploy-skills.ps1 -Target codex -CodexGlobalOnly
    Deploy Codex skills to USER profile only (no repo/workspace)

.EXAMPLE
    .\deploy-skills.ps1 -PackageClaudeSkill dbcli-query -PackageOutDir .
    Package one skill ZIP for Claude web/app upload

.EXAMPLE
    .\deploy-skills.ps1 -PackageClaudeAll -PackageOutDir .
    Package all skills as separate ZIPs for Claude web/app upload

.NOTES
    Requires: DbCli executable installed and skills/ directory available
#>

[CmdletBinding(DefaultParameterSetName = "deploy")]
param(
    [Parameter(ParameterSetName = "deploy", Mandatory = $true)]
    [ValidateSet("claude", "copilot", "codex", "workspace", "all")]
    [string]$Target,
    
    [Parameter(ParameterSetName = "deploy", Mandatory = $false)]
    [string]$GlobalClaudeDir,
    
    [Parameter(ParameterSetName = "deploy", Mandatory = $false)]
    [string]$WorkDir,

    [Parameter(ParameterSetName = "deploy")]
    [switch]$CodexGlobalOnly,
    
    [Parameter(ParameterSetName = "deploy")]
    [switch]$Force,
    
    [Parameter(ParameterSetName = "deploy")]
    [switch]$InstallScripts,
    
    [Parameter(ParameterSetName = "deploy")]
    [switch]$AddToPath,

    [Parameter(ParameterSetName = "package-one", Mandatory = $true)]
    [string[]]$PackageClaudeSkill,

    [Parameter(ParameterSetName = "package-all", Mandatory = $true)]
    [switch]$PackageClaudeAll,

    [Parameter(ParameterSetName = "package-one")]
    [Parameter(ParameterSetName = "package-all")]
    [string]$PackageOutDir = "."
)

$ErrorActionPreference = "Stop"

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

function Resolve-RepoRoot {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$StartDirs
    )

    foreach ($start in $StartDirs) {
        if (-not $start) { continue }
        $current = $start
        while ($current -and (Test-Path $current)) {
            $hasSln = Test-Path (Join-Path $current "dbcli.sln")
            $hasGit = Test-Path (Join-Path $current ".git")
            if ($hasSln -or $hasGit) {
                return $current
            }

            $parent = Split-Path -Parent $current
            if (-not $parent -or $parent -eq $current) { break }
            $current = $parent
        }
    }

    return $null
}

# Resolve home directory in a cross-platform way (Windows + pwsh on Linux/WSL/macOS)
$UserHome = [Environment]::GetFolderPath("UserProfile")
if (-not $UserHome) {
    $UserHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
}

# Resolve working directory for skills and repo scope
$WorkDirPath = $null
if ($PSCmdlet.ParameterSetName -eq "deploy") {
    if ($CodexGlobalOnly -and $Target -ne "codex") {
        Write-Error-Custom "-CodexGlobalOnly is only supported with -Target codex"
        exit 1
    }

    if (-not $WorkDir) {
        if (-not $CodexGlobalOnly) {
            Write-Error-Custom "WorkDir is required unless -CodexGlobalOnly is used. Use -WorkDir <path>."
            exit 1
        }
    }
    elseif (-not (Test-Path $WorkDir)) {
        Write-Error-Custom "WorkDir does not exist: $WorkDir"
        exit 1
    }
    else {
        $WorkDirPath = (Resolve-Path $WorkDir).Path
    }
}
$scriptDir = Get-ScriptDir
$toolsDir = Join-Path $UserHome "tools/dbcli"
$SkillsSourceDir = $null

# Skills source priority:
# 1) alongside the script (repo or tools), 2) tools/dbcli/skills, 3) target workspace (if it already has skills)
$scriptSkills = Join-Path $scriptDir "skills"
$toolsSkills = Join-Path $toolsDir "skills"
if (Test-IsSkillsDir -Dir $scriptSkills) {
    $SkillsSourceDir = $scriptSkills
}
elseif (Test-IsSkillsDir -Dir $toolsSkills) {
    $SkillsSourceDir = $toolsSkills
}
elseif ($WorkDirPath) {
    $fallbackSkills = Join-Path $WorkDirPath "skills"
    if (Test-IsSkillsDir -Dir $fallbackSkills) {
        $SkillsSourceDir = $fallbackSkills
    }
}

if (-not $GlobalClaudeDir) {
    if ($WorkDirPath) {
        $GlobalClaudeDir = Join-Path $WorkDirPath ".claude"
    }
    else {
        $GlobalClaudeDir = Join-Path $UserHome ".claude"
    }
}

# Colors
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Cyan }
function Write-Warning { Write-Host "⚠️  $args" -ForegroundColor Yellow }
function Write-Error-Custom { Write-Host "❌ $args" -ForegroundColor Red }

function Get-DbCliRulesBlock {
    if (-not $SkillsSourceDir) { return $null }
    $integrationPath = Join-Path $SkillsSourceDir "INTEGRATION.md"
    if (-not (Test-Path $integrationPath)) { return $null }
    $content = Get-Content $integrationPath -Raw
    $pattern = '(?s)<!-- DBCLI_RULES_START -->\s*(.*?)\s*<!-- DBCLI_RULES_END -->'
    $match = [regex]::Match($content, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }
    return $null
}

function Append-DbCliRulesToFile {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string]$RulesText
    )

    if ([string]::IsNullOrWhiteSpace($RulesText)) { return }

    $parentDir = Split-Path -Parent $FilePath
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }

    $ext = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    $commented = ($RulesText -split "`r?`n") | ForEach-Object { "# " + $_ }
    $yamlBlock = "`n`n# DBCLI_RULES_START`n" + ($commented -join "`n") + "`n# DBCLI_RULES_END`n"
    $htmlBlock = "`n`n<!-- DBCLI_RULES_START -->`n$RulesText`n<!-- DBCLI_RULES_END -->`n"

    $yamlPattern = '(?ms)^\s*#\s*DBCLI_RULES_START\s*$.*?^\s*#\s*DBCLI_RULES_END\s*$\r?\n?'
    $htmlPattern = '(?s)<!--\s*DBCLI_RULES_START\s*-->.*?<!--\s*DBCLI_RULES_END\s*-->\s*\r?\n?'

    $existing = ""
    if (Test-Path $FilePath) {
        $existing = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    }

    $preferredBlock = if ($ext -eq ".yml" -or $ext -eq ".yaml") { $yamlBlock } else { $htmlBlock }

    if ($existing) {
        $updated = $existing

        if ($existing -match $yamlPattern) {
            $updated = [regex]::Replace($existing, $yamlPattern, ($yamlBlock.TrimStart("`r", "`n")))
        }
        elseif ($existing -match $htmlPattern) {
            $updated = [regex]::Replace($existing, $htmlPattern, ($htmlBlock.TrimStart("`r", "`n")))
        }
        elseif ($existing.Contains("DBCLI_RULES_START")) {
            # Marker exists but format is unexpected (or end marker missing). Don't risk mangling; append a fresh block.
            $updated = $existing + $preferredBlock
        }
        else {
            $updated = $existing + $preferredBlock
        }

        if ($updated -ne $existing) {
            Set-Content -Path $FilePath -Value $updated -Encoding UTF8 -NoNewline
        }
    }
    else {
        Add-Content -Path $FilePath -Value $preferredBlock -Encoding UTF8
    }
}

function Append-DbCliRules {
    param(
        [switch]$IncludeCopilot
    )

    $rules = Get-DbCliRulesBlock
    if ([string]::IsNullOrWhiteSpace($rules)) {
        Write-Warning "DbCli rules block not found in INTEGRATION.md; skipping rules append"
        return
    }

    $ruleFiles = @(
        (Join-Path $WorkDirPath "CLAUDE.md"),
        (Join-Path $WorkDirPath "Claude.md"),
        (Join-Path $WorkDirPath "AGENTS.md"),
        (Join-Path $WorkDirPath "Agents.md"),
        (Join-Path $WorkDirPath ".cursorrules"),
        (Join-Path $WorkDirPath ".vscode/context.md"),
        (Join-Path $WorkDirPath ".gemini/skills.yaml"),
        (Join-Path $WorkDirPath ".gemini/skills.yml")
    )

    foreach ($file in $ruleFiles) {
        Append-DbCliRulesToFile -FilePath $file -RulesText $rules
    }

    if ($IncludeCopilot) {
        $copilotFile = Join-Path $WorkDirPath ".github/copilot-instructions.md"
        Append-DbCliRulesToFile -FilePath $copilotFile -RulesText $rules
    }
}

function Get-ClaudeSkillNames {
    param(
        [Parameter(Mandatory = $true)][string]$SkillsDir
    )

    $names = @()
    foreach ($child in (Get-ChildItem -Path $SkillsDir -Directory -ErrorAction SilentlyContinue)) {
        if (Test-Path (Join-Path $child.FullName "SKILL.md")) {
            $names += $child.Name
        }
    }
    return $names
}

function Package-ClaudeSkillZip {
    param(
        [Parameter(Mandatory = $true)][string]$SkillName,
        [Parameter(Mandatory = $true)][string]$SkillsDir,
        [Parameter(Mandatory = $true)][string]$OutDir
    )

    $srcDir = Join-Path $SkillsDir $SkillName
    if (-not (Test-Path $srcDir)) {
        Write-Error-Custom "Skill not found: $srcDir"
        return $false
    }

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-skill-" + $SkillName + "-" + [Guid]::NewGuid().ToString("n"))
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

    $skillTempDir = Join-Path $tempRoot $SkillName
    Copy-Item -Recurse -Force -Path $srcDir -Destination $skillTempDir

    if (-not (Test-Path $OutDir)) {
        New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    }
    $zipPath = Join-Path $OutDir ("{0}.zip" -f $SkillName)
    if (Test-Path $zipPath) { Remove-Item -Force $zipPath }

    # Build the ZIP with a case-correct Skill.md entry name (Windows FS is case-insensitive).
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
    $zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        # Create the root folder entry (optional but harmless)
        [void]$zip.CreateEntry(("{0}/" -f $SkillName))

        $files = Get-ChildItem -Path $skillTempDir -Recurse -File -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $relWin = $file.FullName.Substring($skillTempDir.Length).TrimStart('\', '/')

            if ($file.Name -ieq "skill.md") {
                $parent = Split-Path $relWin -Parent
                if ([string]::IsNullOrWhiteSpace($parent)) {
                    $relWin = "Skill.md"
                }
                else {
                    $relWin = (Join-Path $parent "Skill.md")
                }
            }

            $relPosix = $relWin -replace '\\', '/'
            $entryName = ("{0}/{1}" -f $SkillName, $relPosix)
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }

        if (-not ($files | Where-Object { $_.Name -ieq "skill.md" })) {
            Write-Warning "Skill.md not found in skill folder (expected by Claude upload): $SkillName"
        }
    }
    finally {
        $zip.Dispose()
    }
    Remove-Item -Recurse -Force -Path $tempRoot -ErrorAction SilentlyContinue

    Write-Success "Created Claude skill ZIP: $zipPath"
    return $true
}

function Package-ClaudeSkills {
    param(
        [Parameter(Mandatory = $true)][string[]]$SkillNames,
        [Parameter(Mandatory = $true)][string]$SkillsDir,
        [Parameter(Mandatory = $true)][string]$OutDir
    )

    $ok = $true
    foreach ($name in $SkillNames) {
        $ok = (Package-ClaudeSkillZip -SkillName $name -SkillsDir $SkillsDir -OutDir $OutDir) -and $ok
    }
    return $ok
}

# Packaging-only mode (Claude Web/App upload ZIPs)
if ($PSCmdlet.ParameterSetName -eq "package-one" -or $PSCmdlet.ParameterSetName -eq "package-all") {
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host "Claude Skills Packaging" -ForegroundColor Cyan
    Write-Host "================================`n" -ForegroundColor Cyan

    if (-not $SkillsSourceDir -or -not (Test-IsSkillsDir -Dir $SkillsSourceDir)) {
        Write-Error-Custom "skills/ directory not found"
        Write-Info "Run from dbcli repo root (where ./skills exists), or install scripts with skills into tools (InstallScripts) first"
        exit 1
    }

    $skillNames = if ($PSCmdlet.ParameterSetName -eq "package-all") {
        Get-ClaudeSkillNames -SkillsDir $SkillsSourceDir
    }
    else {
        $PackageClaudeSkill
    }

    if (-not $skillNames -or $skillNames.Count -eq 0) {
        Write-Error-Custom "No skills to package"
        exit 1
    }

    Write-Info "Skills source: $SkillsSourceDir"
    Write-Info "Output dir: $PackageOutDir"

    $result = Package-ClaudeSkills -SkillNames $skillNames -SkillsDir $SkillsSourceDir -OutDir $PackageOutDir
    if (-not $result) { exit 1 }
    exit 0
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "DbCli Skills Deployment" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Step 0: Install DbCli executable + scripts (if requested)
if ($InstallScripts) {
    $installScript = Join-Path $scriptDir "install-dbcli.ps1"
    if (-not (Test-Path $installScript)) {
        Write-Error-Custom "install-dbcli.ps1 not found next to deploy-skills.ps1"
        exit 1
    }

    & $installScript -AddToPath:$AddToPath -Force:$Force
}

# Check skills directory exists
if (-not $SkillsSourceDir -or -not (Test-IsSkillsDir -Dir $SkillsSourceDir)) {
    Write-Error-Custom "skills/ directory not found"
    Write-Info "Install scripts with skills into tools (InstallScripts) or run from dbcli repo"
    exit 1
}

# Deployment functions

function Deploy-ClaudeSkills {
    param(
        [switch]$CopyExe
    )
    Write-Info "Deploying to Claude Code..."
    
    try {
        $claudeDbcliDir = Join-Path (Join-Path $GlobalClaudeDir "skills") "dbcli"
        $claudeSkillsDir = Join-Path $claudeDbcliDir "skills"
        
        # Check if already exists
        if ((Test-Path $claudeDbcliDir) -and -not $Force) {
            Write-Warning "Claude dbcli already exists at $claudeDbcliDir"
            $response = Read-Host "Overwrite? (y/N)"
            if ($response -ne 'y') {
                Write-Info "Skipping Claude deployment"
                return
            }
        }
        
        # Create directories
        New-Item -ItemType Directory -Force -Path $claudeDbcliDir -ErrorAction Stop | Out-Null
        if ($Force -and (Test-Path $claudeSkillsDir)) {
            # Force means "clean update": remove stale files that might not be overwritten by Copy-Item.
            Remove-Item -Recurse -Force -Path $claudeSkillsDir -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Force -Path $claudeSkillsDir -ErrorAction Stop | Out-Null
    
        if ($CopyExe) {
            # Copy executable to dbcli/ (top level)
            $exePath = Find-DbCliExecutable -ScriptDir $scriptDir
            
            if ($exePath -and $exePath.FullName) {
                Copy-Item $exePath.FullName -Destination $claudeDbcliDir -Force
                Write-Host "  ✓ $($exePath.Name) (executable)" -ForegroundColor Gray
            }
            else {
                Write-Warning "DbCli executable not found, skipping exe deployment"
            }
        }
        
        # Copy skills to dbcli/skills/ (nested)
        $skillItems = @(
            "README.md",
            "INTEGRATION.md",
            "CONNECTION_STRINGS.md",
            "dbcli-query",
            "dbcli-exec",
            "dbcli-db-ddl",
            "dbcli-tables",
            "dbcli-export",
            "dbcli-view",
            "dbcli-index",
            "dbcli-procedure",
            "dbcli-interactive"
        )
        
        foreach ($item in $skillItems) {
            $sourcePath = Join-Path $SkillsSourceDir $item
            if ((Test-Path $sourcePath) -and $sourcePath) {
                $destPath = Join-Path $claudeSkillsDir $item
                Copy-Item $sourcePath -Destination $destPath -Recurse -Force -ErrorAction Stop
                Write-Host "  ✓ skills/$item" -ForegroundColor Gray
            }
        }

        Write-Success "Claude Code deployed to $claudeDbcliDir"
        Write-Info "Structure: dbcli/ (exe) + dbcli/skills/ (skills)"
        Write-Info "Skills location: $claudeSkillsDir"
        Write-Info "Skills will be available in Claude Code after restart"
        Append-DbCliRules
    }
    catch {
        Write-Error-Custom "Failed to deploy to Claude: $_"
        Write-Host "  Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
    }
}

function Deploy-CopilotInstructions {
    Write-Info "Deploying GitHub Copilot instructions..."
    
    $githubDir = Join-Path $WorkDirPath ".github"
    $instructionsFile = Join-Path $githubDir "copilot-instructions.md"
    
    # Create .github if not exists
    if (-not (Test-Path $githubDir)) {
        New-Item -ItemType Directory -Force -Path $githubDir | Out-Null
    }
    
    # Check if already exists
    if ((Test-Path $instructionsFile) -and -not $Force) {
        Write-Warning "copilot-instructions.md already exists"
        $response = Read-Host "Overwrite? (y/N)"
        if ($response -ne 'y') {
            Write-Info "Skipping Copilot deployment"
            return
        }
    }
    
    # Read template from INTEGRATION.md
    $integrationDoc = Get-Content (Join-Path $SkillsSourceDir "INTEGRATION.md") -Raw
    
    # Extract Copilot section
    $copilotSection = $integrationDoc -match '## 2\. GitHub Copilot Integration[\s\S]*?(?=## 3\.)'
    
    if ($Matches) {
        $copilotContent = $Matches[0]
        
        # Extract the markdown content from Method 1
        if ($copilotContent -match '```markdown\s*([\s\S]*?)\s*```') {
            $instructionsContent = $Matches[1]
            Set-Content -Path $instructionsFile -Value $instructionsContent -Encoding UTF8
            Write-Success "GitHub Copilot instructions created at $instructionsFile"
            Write-Info "Copilot will use these instructions automatically"
            Append-DbCliRules -IncludeCopilot
        } else {
            Write-Error-Custom "Could not extract Copilot instructions template"
        }
    } else {
        Write-Error-Custom "Could not find Copilot section in INTEGRATION.md"
    }
}

function Deploy-CodexSkills {
    param(
        [switch]$CopyExe,
        [switch]$GlobalOnly
    )
    Write-Info "Deploying to OpenAI Codex..."
    
    $exePath = Find-DbCliExecutable -ScriptDir $scriptDir

    # Deploy to USER scope: ~/.codex/skills/dbcli/skills/
    $userCodexDbcliDir = Join-Path $UserHome ".codex/skills/dbcli"
    $userCodexSkillsDir = Join-Path $userCodexDbcliDir "skills"
    
    if (Test-Path $userCodexDbcliDir) {
        if ($Force) {
            Write-Warning "Overwriting existing Codex USER dbcli"
            Remove-Item -Recurse -Force $userCodexDbcliDir
        } else {
            Write-Warning "Codex USER dbcli already exists at: $userCodexDbcliDir"
            Write-Info "Use -Force to overwrite"
        }
    }
    
    if (-not (Test-Path $userCodexDbcliDir) -or $Force) {
        New-Item -ItemType Directory -Force -Path $userCodexDbcliDir | Out-Null
        New-Item -ItemType Directory -Force -Path $userCodexSkillsDir | Out-Null
        
        # Copy executable
        if ($CopyExe -and $exePath -and $exePath.FullName) {
            Copy-Item $exePath.FullName -Destination $userCodexDbcliDir -Force
            Write-Host "  ✓ $($exePath.Name)" -ForegroundColor Gray
        }
        
        # Copy skills to nested directory
        $skillItems = @(
            "dbcli-query", "dbcli-exec", "dbcli-db-ddl", "dbcli-tables",
            "dbcli-view", "dbcli-index", "dbcli-procedure",
            "dbcli-export", "dbcli-interactive",
            "README.md", "INTEGRATION.md", "CONNECTION_STRINGS.md"
        )
        
        foreach ($item in $skillItems) {
            $sourcePath = Join-Path $SkillsSourceDir $item
            if (Test-Path $sourcePath) {
                Copy-Item $sourcePath -Destination (Join-Path $userCodexSkillsDir $item) -Recurse -Force
                Write-Host "  ✓ skills/$item" -ForegroundColor Gray
            }
        }

        Write-Success "Codex USER deployed to: $userCodexDbcliDir"
    }
    
    if ($GlobalOnly) {
        Write-Info "Codex global-only mode: skipping repo deployment"
        return
    }

    # Deploy to REPO scope: ./.codex/skills/dbcli/skills/ (if in a git repo)
    if ($WorkDirPath -and (Test-Path (Join-Path $WorkDirPath ".git"))) {
        $repoCodexDbcliDir = Join-Path (Join-Path $WorkDirPath ".codex/skills") "dbcli"
        $repoCodexSkillsDir = Join-Path $repoCodexDbcliDir "skills"
        
        if (Test-Path $repoCodexDbcliDir) {
            if ($Force) {
                Write-Warning "Overwriting existing Codex REPO dbcli"
                Remove-Item -Recurse -Force $repoCodexDbcliDir
            } else {
                Write-Info "Codex REPO dbcli already exists at: $repoCodexDbcliDir (skipping)"
                return
            }
        }
        
        if (-not (Test-Path $repoCodexDbcliDir) -or $Force) {
            New-Item -ItemType Directory -Force -Path $repoCodexDbcliDir | Out-Null
            New-Item -ItemType Directory -Force -Path $repoCodexSkillsDir | Out-Null
            
            # Copy executable
            if ($CopyExe -and $exePath) {
                Copy-Item $exePath.FullName -Destination $repoCodexDbcliDir -Force
            }
            
            # Copy skills to nested directory
            foreach ($item in $skillItems) {
                $sourcePath = Join-Path $SkillsSourceDir $item
                if (Test-Path $sourcePath) {
                    Copy-Item $sourcePath -Destination (Join-Path $repoCodexSkillsDir $item) -Recurse -Force
                }
            }

            Write-Success "Codex REPO deployed to: $repoCodexDbcliDir"
            Write-Info "Consider committing .codex/ to repository for team sharing"
        }
    }

    if ($WorkDirPath) {
        Append-DbCliRules
    }
}

function Deploy-WorkspaceSkills {
    Write-Info "Deploying to workspace skills directory..."
    
    $workspaceSkillsDir = Join-Path $WorkDirPath "skills/dbcli"
    
    # If user points -WorkDir to an existing skills root folder (contains dbcli-query directly),
    # avoid nesting skills/skills/.
    if (Test-Path (Join-Path $WorkDirPath "dbcli-query")) {
        Write-Warning "WorkDir looks like a skills root directory"
        Write-Info "For workspace deployment, pass your project root: -WorkDir <project-root>"
        return
    }
    
    # Create skills directory structure
    if ($Force -and (Test-Path $workspaceSkillsDir)) {
        # Force means "clean update": remove stale files that might not be overwritten by Copy-Item.
        Remove-Item -Recurse -Force -Path $workspaceSkillsDir -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Force -Path $workspaceSkillsDir | Out-Null
    
    # If we're in dbcli repo, copy from current location
    if (Test-IsSkillsDir -Dir $SkillsSourceDir) {
        $sourceDir = $SkillsSourceDir
    } else {
        Write-Error-Custom "Cannot find skills source directory"
        Write-Info "Please copy skills manually or run from dbcli repository"
        return
    }
    
    # Copy all skills
    $items = Get-ChildItem $sourceDir
    foreach ($item in $items) {
        Copy-Item $item.FullName -Destination $workspaceSkillsDir -Recurse -Force
    }

    Write-Success "Workspace skills deployed to $workspaceSkillsDir"
    Write-Info "Skills available for Cursor, Cline/Roo/Kilo, and other workspace-based assistants"
}

# Execute deployments based on target

switch ($Target) {
    "claude" {
        Deploy-ClaudeSkills -CopyExe:$false
    }
    "copilot" {
        Deploy-CopilotInstructions
    }
    "codex" {
        Deploy-CodexSkills -CopyExe:$false -GlobalOnly:$CodexGlobalOnly
    }
    "workspace" {
        Deploy-WorkspaceSkills
    }
    "all" {
        Deploy-ClaudeSkills -CopyExe:$false
        Write-Host ""
        Deploy-CopilotInstructions
        Write-Host ""
        Deploy-CodexSkills -CopyExe:$false
        Write-Host ""
        Deploy-WorkspaceSkills
    }
}

# Verify dbcli is installed
Write-Host ""
Write-Info "Verifying DbCli installation..."

try {
    $version = & dbcli --version 2>&1
    if ($version) {
        Write-Success "DbCli is installed: $version"
    } else {
        Write-Warning "DbCli command not found in PATH"
        Write-Info "DbCli is not installed. Re-run with: -InstallScripts"
    }
} catch {
    Write-Warning "DbCli not found in PATH"
    Write-Info "Install DbCli: pwsh ./deploy-skills.ps1 -InstallScripts -Target all -WorkDir . -Force"
}

# Final summary
Write-Host "`n================================" -ForegroundColor Green
Write-Host "Deployment Complete! ✅" -ForegroundColor Green
Write-Host "================================`n" -ForegroundColor Green

Write-Host "Deployed to: $Target" -ForegroundColor Cyan

if ($Target -eq "claude" -or $Target -eq "all") {
    Write-Host "`nClaude Code:" -ForegroundColor Cyan
    Write-Host "  Location: $(Join-Path (Join-Path $GlobalClaudeDir 'skills') 'dbcli')" -ForegroundColor Gray
    Write-Host "  Skills: $(Join-Path (Join-Path (Join-Path $GlobalClaudeDir 'skills') 'dbcli') 'skills')" -ForegroundColor Gray
    Write-Host "  Usage: Restart Claude Code, then skills auto-available" -ForegroundColor Gray
}

if ($Target -eq "copilot" -or $Target -eq "all") {
    Write-Host "`nGitHub Copilot:" -ForegroundColor Cyan
    Write-Host "  Location: $(Join-Path $WorkDirPath '.github/copilot-instructions.md')" -ForegroundColor Gray
    Write-Host "  Usage: Copilot reads automatically from workspace" -ForegroundColor Gray
}
if ($Target -eq "codex" -or $Target -eq "all") {
    Write-Host "`nOpenAI Codex:" -ForegroundColor Cyan
    Write-Host "  USER: $(Join-Path $UserHome '.codex/skills/dbcli')" -ForegroundColor Gray
    Write-Host "  USER Skills: $(Join-Path (Join-Path $UserHome '.codex/skills/dbcli') 'skills')" -ForegroundColor Gray
    if (-not $CodexGlobalOnly -and $WorkDirPath) {
        Write-Host "  REPO: $(Join-Path $WorkDirPath '.codex/skills/dbcli') (if in git repo)" -ForegroundColor Gray
        Write-Host "  REPO Skills: $(Join-Path (Join-Path $WorkDirPath '.codex/skills/dbcli') 'skills')" -ForegroundColor Gray
    }
    Write-Host "  Usage: Restart Codex, skills auto-available" -ForegroundColor Gray
}

if ($Target -eq "workspace" -or $Target -eq "all") {
    Write-Host "`nWorkspace Skills:" -ForegroundColor Cyan
    Write-Host "  Location: $(Join-Path $WorkDirPath 'skills/dbcli')" -ForegroundColor Gray
    Write-Host "  Usage: Available to Cursor, Cline/Roo/Kilo, etc." -ForegroundColor Gray
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Restart your AI assistant (if needed)" -ForegroundColor White
Write-Host "2. Test a skill:" -ForegroundColor White
Write-Host "   Ask: 'Query my SQLite database for all users'" -ForegroundColor Gray
Write-Host "3. See skills/INTEGRATION.md for platform-specific usage" -ForegroundColor White
Write-Host ""

exit 0

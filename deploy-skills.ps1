#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy DbCli Skills to Claude Code / OpenAI Codex environments

.DESCRIPTION
    This script deploys DbCli skills to AI assistant environments:
    - Claude Code: ./.claude/skills/dbcli (when running inside this repo), otherwise ~/.claude/skills/dbcli
    - GitHub Copilot: .github/copilot-instructions.md
    - OpenAI Codex: .codex/skills/dbcli (USER: ~/.codex, REPO: ./.codex)
    - Project workspace: ./skills/dbcli (for Cursor/Windsurf/etc)

.PARAMETER Target
    Target environment: claude, copilot, codex, workspace, or all

.PARAMETER GlobalClaudeDir
    Custom Claude directory (default: repo ./.claude if detected, otherwise ~/.claude)

.PARAMETER Force
    Overwrite existing installation

.EXAMPLE
    .\deploy-skills.ps1 -Target claude
    Deploy to Claude Code only

.EXAMPLE
    .\deploy-skills.ps1 -Target all -Force
    Deploy to all environments, overwriting existing files

.NOTES
    Requires: DbCli executable installed and skills/ directory available
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("claude", "copilot", "codex", "workspace", "all")]
    [string]$Target = "all",
    
    [Parameter(Mandatory=$false)]
    [string]$GlobalClaudeDir,
    
    [switch]$Force,
    
    [switch]$InstallExe,
    
    [switch]$AddToPath,
    
    [switch]$SkipPath
)

$ErrorActionPreference = "Stop"

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

if (-not $GlobalClaudeDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $repoRoot = Resolve-RepoRoot -StartDirs @($scriptDir, (Get-Location).Path)
    if ($repoRoot) {
        $GlobalClaudeDir = Join-Path $repoRoot ".claude"
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

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "DbCli Skills Deployment" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Step 0: Install DbCli executable (if requested)
if ($InstallExe) {
    Write-Host "`n📦 Installing DbCli Executable" -ForegroundColor Cyan
    Write-Host "------------------------------`n" -ForegroundColor Cyan
    
    # Find executable
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $exePath = $null
    
    # Priority 1: Check dist-* deployment directories first
    # Prefer the current platform's dist folder so WSL/Linux doesn't accidentally pick dbcli.exe.
    if ($IsWindows) {
        $osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
        $isArm64Windows = $osArch -eq "Arm64"
        $distDirs = @(
            $(if ($isArm64Windows) { "dist-win-arm64" } else { "dist-win-x64" })
        )
    }
    elseif ($IsMacOS) {
        $distDirs = @(
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
        $distDirs = @(
            "dist-linux-x64",
            "dist-linux-arm64",
            "dist-macos-x64",
            "dist-macos-arm64",
            "dist-win-x64",
            "dist-win-arm64"
        )
    }
    
    foreach ($distDir in $distDirs) {
        $distPath = Join-Path $scriptDir $distDir
        if (Test-Path $distPath) {
            $exeInDist = Get-ChildItem -Path $distPath -Filter "dbcli*" -File -ErrorAction SilentlyContinue | Where-Object { 
                $_.Extension -eq ".exe" -or ($_.Extension -eq "" -and $_.Name -eq "dbcli") 
            } | Select-Object -First 1
            
            if ($exeInDist) {
                $exePath = $exeInDist
                Write-Info "Found deployment: $distDir\$($exePath.Name)"
                break
            }
        }
    }
    
    # Priority 2: Check current directory
    if (-not $exePath) {
        $localExe = Get-ChildItem -Path $scriptDir -Filter "dbcli*" -File -ErrorAction SilentlyContinue | Where-Object { 
            $_.Extension -eq ".exe" -or ($_.Extension -eq "" -and $_.Name -eq "dbcli") 
        } | Select-Object -First 1
        
        if ($localExe) {
            $exePath = $localExe
            Write-Info "Found: $($exePath.Name)"
        }
    }
    
    # Priority 3: Try build output directories (last resort)
    if (-not $exePath) {
        $buildPaths = @(
            "bin\Release\net10.0\win-x64\dbcli.exe",
            "bin\Debug\net10.0\win-x64\dbcli.exe",
            "..\bin\Release\net10.0\win-x64\dbcli.exe",
            "..\bin\Debug\net10.0\win-x64\dbcli.exe"
        )
        
        foreach ($path in $buildPaths) {
            $fullPath = Join-Path $scriptDir $path
            if (Test-Path $fullPath) {
                $exePath = Get-Item $fullPath
                Write-Info "Found build: $($exePath.FullName)"
                break
            }
        }
    }
    
    if (-not $exePath) {
        Write-Error-Custom "DbCli executable not found"
        Write-Warning "Build the project first: dotnet build -c Release"
        exit 1
    }
    
    # Get source directory
    $sourceDir = Split-Path -Parent $exePath.FullName
    
    # Copy to target installation directory
    $installDir = Join-Path $UserHome "tools/dbcli"
    Write-Info "Installing to: $installDir"
    
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }
    
    # Copy all files from source directory
    Write-Info "Copying from: $sourceDir"
    Copy-Item "$sourceDir\*" -Destination $installDir -Recurse -Force -Exclude "skills"
    Write-Success "Installed $($exePath.Name) to $installDir"
    
    # Check and add to PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $pathEntry = $installDir
    $inPath = $currentPath -split ';' | Where-Object { $_ -eq $pathEntry }
    
    if (-not $inPath) {
        Write-Warning "DbCli is not in your PATH"
        Write-Info "Location: $installDir"
        
        $shouldAddToPath = $false
        
        if ($AddToPath) {
            $shouldAddToPath = $true
            Write-Info "Adding to PATH (automatic)..."
        }
        elseif ($SkipPath) {
            Write-Info "Skipping PATH addition (automatic)"
        }
        else {
            Write-Host "`n  To use 'dbcli' from any directory, add it to PATH." -ForegroundColor White
            $response = Read-Host "  Add to PATH? (Y/n)"
            $shouldAddToPath = $response -eq "" -or $response -like "y*"
        }
        
        if ($shouldAddToPath) {
            try {
                $newPath = $currentPath
                if ($newPath -and -not $newPath.EndsWith(";")) {
                    $newPath += ";"
                }
                $newPath += $pathEntry
                
                [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                $env:PATH = "$env:PATH;$pathEntry"
                
                Write-Success "Added to PATH"
                Write-Warning "Restart your terminal for changes to take effect"
            }
            catch {
                Write-Error-Custom "Failed to add to PATH: $_"
                Write-Warning "Add manually: $installDir"
            }
        }
        else {
            Write-Info "Skipped PATH addition"
            Write-Info "Use full path: $installDir\dbcli.exe"
        }
    }
    else {
        # The install dir may already exist in the persisted (User) PATH, but the current
        # process may not have picked it up (e.g., terminal started before it was added).
        # Ensure the current session can run `dbcli` immediately.
        $sessionInPath = $env:PATH -split ';' | Where-Object { $_ -eq $pathEntry }
        if (-not $sessionInPath) {
            $env:PATH = "$env:PATH;$pathEntry"
            Write-Success "Already in PATH (User); updated current session PATH"
        }
        else {
            Write-Success "Already in PATH"
        }
    }
    
    Write-Host ""
}

# Check skills directory exists
if (-not (Test-Path (Join-Path "skills" "README.md"))) {
    Write-Error-Custom "skills/ directory not found"
    Write-Info "Please run this script from the dbcli repository root"
    exit 1
}

# Deployment functions

function Deploy-ClaudeSkills {
    Write-Info "Deploying to Claude Code..."
    
    try {
        $claudeDbcliDir = Join-Path $GlobalClaudeDir "skills\dbcli"
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
        New-Item -ItemType Directory -Force -Path $claudeSkillsDir -ErrorAction Stop | Out-Null
    
        # Copy executable to dbcli/ (top level)
        $scriptDir = if ($MyInvocation.MyCommand.Path) {
            Split-Path -Parent $MyInvocation.MyCommand.Path
        } else {
            $PSScriptRoot
        }
        if (-not $scriptDir) {
            $scriptDir = Get-Location
        }
        $exePath = $null
        
        # Try current directory first
        if (Test-Path $scriptDir) {
            $exePath = Get-ChildItem -Path $scriptDir -Filter "dbcli*" -File -ErrorAction SilentlyContinue | Where-Object { 
                $_.Extension -eq ".exe" -or ($_.Extension -eq "" -and $_.Name -eq "dbcli") 
            } | Select-Object -First 1
        }
        
        if (-not $exePath) {
            # Try build output
            $buildPaths = @(
                "bin\Release\net10.0\win-x64\dbcli.exe",
                "bin\Debug\net10.0\win-x64\dbcli.exe",
                "..\bin\Release\net10.0\win-x64\dbcli.exe",
                "..\bin\Debug\net10.0\win-x64\dbcli.exe"
            )
            
            foreach ($path in $buildPaths) {
                $fullPath = Join-Path $scriptDir $path
                if (Test-Path $fullPath) {
                    $exePath = Get-Item $fullPath
                    break
                }
            }
        }
        
        if ($exePath -and $exePath.FullName) {
            Copy-Item $exePath.FullName -Destination "$claudeDbcliDir\" -Force
            Write-Host "  ✓ $($exePath.Name) (executable)" -ForegroundColor Gray
        }
        else {
            Write-Warning "DbCli executable not found, skipping exe deployment"
        }
        
        # Copy skills to dbcli/skills/ (nested)
        $skillItems = @(
            "README.md",
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
            $sourcePath = "skills\$item"
            if ((Test-Path $sourcePath) -and $sourcePath) {
                $destPath = Join-Path $claudeSkillsDir $item
                Copy-Item $sourcePath -Destination $destPath -Recurse -Force -ErrorAction Stop
                Write-Host "  ✓ skills/$item" -ForegroundColor Gray
            }
        }
        
        
        $integrationPath = Join-Path $claudeSkillsDir "INTEGRATION.md"
        if (Test-Path $integrationPath) {
            Remove-Item -Force $integrationPath
        }

        Write-Success "Claude Code deployed to $claudeDbcliDir"
        Write-Info "Structure: dbcli/ (exe) + dbcli/skills/ (skills)"
        Write-Info "Skills will be available in Claude Code after restart"
    }
    catch {
        Write-Error-Custom "Failed to deploy to Claude: $_"
        Write-Host "  Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
    }
}

function Deploy-CopilotInstructions {
    Write-Info "Deploying GitHub Copilot instructions..."
    
    $githubDir = ".github"
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
    $integrationDoc = Get-Content "skills\INTEGRATION.md" -Raw
    
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
        } else {
            Write-Error-Custom "Could not extract Copilot instructions template"
        }
    } else {
        Write-Error-Custom "Could not find Copilot section in INTEGRATION.md"
    }
}

function Deploy-CodexSkills {
    Write-Info "Deploying to OpenAI Codex..."
    
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
        $scriptDir = if ($MyInvocation.MyCommand.Path) {
            Split-Path -Parent $MyInvocation.MyCommand.Path
        } else {
            $PSScriptRoot
        }
        if (-not $scriptDir) {
            $scriptDir = Get-Location
        }
        
        $exePath = $null
        
        # Priority 1: dist-* directories
        if ($IsWindows) {
            $osArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
            $isArm64Windows = $osArch -eq "Arm64"
            $distDirs = @(
                $(if ($isArm64Windows) { "dist-win-arm64" } else { "dist-win-x64" })
            )
        }
        elseif ($IsMacOS) {
            $distDirs = @(
                "dist-macos-x64",
                "dist-macos-arm64",
                "dist-linux-x64",
                "dist-linux-arm64",
                "dist-win-x64",
                "dist-win-arm64"
            )
        }
        else {
            $distDirs = @(
                "dist-linux-x64",
                "dist-linux-arm64",
                "dist-macos-x64",
                "dist-macos-arm64",
                "dist-win-x64",
                "dist-win-arm64"
            )
        }
        
        foreach ($distDir in $distDirs) {
            $distPath = Join-Path $scriptDir $distDir
            if (Test-Path $distPath) {
                $exeInDist = Get-ChildItem -Path $distPath -Filter "dbcli*" -File -ErrorAction SilentlyContinue | Where-Object { 
                    $_.Extension -eq ".exe" -or ($_.Extension -eq "" -and $_.Name -eq "dbcli") 
                } | Select-Object -First 1
                
                if ($exeInDist) {
                    $exePath = $exeInDist
                    break
                }
            }
        }
        
        # Priority 2: current directory
        if (-not $exePath -and (Test-Path $scriptDir)) {
            $exePath = Get-ChildItem -Path $scriptDir -Filter "dbcli*" -File -ErrorAction SilentlyContinue | Where-Object { 
                $_.Extension -eq ".exe" -or ($_.Extension -eq "" -and $_.Name -eq "dbcli") 
            } | Select-Object -First 1
        }
        
        # Priority 3: build output
        if (-not $exePath) {
            $buildPaths = @(
                "bin\Release\net10.0\win-x64\dbcli.exe",
                "bin\Debug\net10.0\win-x64\dbcli.exe"
            )
            foreach ($path in $buildPaths) {
                $fullPath = Join-Path $scriptDir $path
                if (Test-Path $fullPath) {
                    $exePath = Get-Item $fullPath
                    break
                }
            }
        }
        
        if ($exePath -and $exePath.FullName) {
            Copy-Item $exePath.FullName -Destination "$userCodexDbcliDir\" -Force
            Write-Host "  ✓ $($exePath.Name)" -ForegroundColor Gray
        }
        
        # Copy skills to nested directory
        $skillItems = @(
            "dbcli-query", "dbcli-exec", "dbcli-db-ddl", "dbcli-tables",
            "dbcli-view", "dbcli-index", "dbcli-procedure",
            "dbcli-export", "dbcli-interactive",
            "README.md", "CONNECTION_STRINGS.md"
        )
        
        foreach ($item in $skillItems) {
            $sourcePath = "skills\$item"
            if (Test-Path $sourcePath) {
                Copy-Item $sourcePath -Destination "$userCodexSkillsDir\$item" -Recurse -Force
                Write-Host "  ✓ skills/$item" -ForegroundColor Gray
            }
        }
        
        
        $integrationPath = Join-Path $userCodexSkillsDir "INTEGRATION.md"
        if (Test-Path $integrationPath) {
            Remove-Item -Force $integrationPath
        }

        Write-Success "Codex USER deployed to: $userCodexDbcliDir"
    }
    
    # Deploy to REPO scope: ./.codex/skills/dbcli/skills/ (if in a git repo)
    if (Test-Path ".git") {
        $repoCodexDbcliDir = ".codex\skills\dbcli"
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
            if ($exePath) {
                Copy-Item $exePath.FullName -Destination "$repoCodexDbcliDir\" -Force
            }
            
            # Copy skills to nested directory
            foreach ($item in $skillItems) {
                $sourcePath = "skills\$item"
                if (Test-Path $sourcePath) {
                    Copy-Item $sourcePath -Destination "$repoCodexSkillsDir\$item" -Recurse -Force
                }
            }
            
            
            $integrationPath = Join-Path $repoCodexSkillsDir "INTEGRATION.md"
            if (Test-Path $integrationPath) {
                Remove-Item -Force $integrationPath
            }

            Write-Success "Codex REPO deployed to: $repoCodexDbcliDir"
            Write-Info "Consider committing .codex/ to repository for team sharing"
        }
    }
}

function Deploy-WorkspaceSkills {
    Write-Info "Deploying to workspace skills directory..."
    
    $workspaceSkillsDir = "skills\dbcli"
    
    # Check if this IS the skills directory
    if (Test-Path "skills\dbcli-query") {
        Write-Warning "Already in skills root directory"
        Write-Info "For workspace deployment, run from a different project directory"
        return
    }
    
    # Create skills directory structure
    New-Item -ItemType Directory -Force -Path $workspaceSkillsDir | Out-Null
    
    # If we're in dbcli repo, copy from current location
    if (Test-Path "skills\README.md") {
        $sourceDir = "skills"
    } else {
        Write-Error-Custom "Cannot find skills source directory"
        Write-Info "Please copy skills manually or run from dbcli repository"
        return
    }
    
    # Copy all skills
    $items = Get-ChildItem $sourceDir | Where-Object { $_.Name -ne "INTEGRATION.md" }
    foreach ($item in $items) {
        Copy-Item $item.FullName -Destination "$workspaceSkillsDir\" -Recurse -Force
    }
    
    
    $integrationPath = Join-Path $workspaceSkillsDir "INTEGRATION.md"
    if (Test-Path $integrationPath) {
        Remove-Item -Force $integrationPath
    }

    Write-Success "Workspace skills deployed to $workspaceSkillsDir"
    Write-Info "Skills available for Cursor, Windsurf, Continue, and other workspace-based assistants"
}

# Execute deployments based on target

switch ($Target) {
    "claude" {
        Deploy-ClaudeSkills
    }
    "copilot" {
        Deploy-CopilotInstructions
    }
    "codex" {
        Deploy-CodexSkills
    }
    "workspace" {
        Deploy-WorkspaceSkills
    }
    "all" {
        Deploy-ClaudeSkills
        Write-Host ""
        Deploy-CopilotInstructions
        Write-Host ""
        Deploy-CodexSkills
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
        Write-Info "DbCli is not installed. Re-run with: -InstallExe -AddToPath"
    }
} catch {
    Write-Warning "DbCli not found in PATH"
    Write-Info "Install DbCli: pwsh .\deploy-skills.ps1 -InstallExe -AddToPath -Target all -Force"
}

# Final summary
Write-Host "`n================================" -ForegroundColor Green
Write-Host "Deployment Complete! ✅" -ForegroundColor Green
Write-Host "================================`n" -ForegroundColor Green

Write-Host "Deployed to: $Target" -ForegroundColor Cyan

if ($Target -eq "claude" -or $Target -eq "all") {
    Write-Host "`nClaude Code:" -ForegroundColor Cyan
    Write-Host "  Location: $GlobalClaudeDir\skills\dbcli" -ForegroundColor Gray
    Write-Host "  Usage: Restart Claude Code, then skills auto-available" -ForegroundColor Gray
}

if ($Target -eq "copilot" -or $Target -eq "all") {
    Write-Host "`nGitHub Copilot:" -ForegroundColor Cyan
    Write-Host "  Location: .github\copilot-instructions.md" -ForegroundColor Gray
    Write-Host "  Usage: Copilot reads automatically from workspace" -ForegroundColor Gray
}
if ($Target -eq "codex" -or $Target -eq "all") {
    Write-Host "`nOpenAI Codex:" -ForegroundColor Cyan
    Write-Host "  USER: $(Join-Path $UserHome '.codex/skills/dbcli')" -ForegroundColor Gray
    Write-Host "  REPO: .codex\skills\dbcli (if in git repo)" -ForegroundColor Gray
    Write-Host "  Usage: Restart Codex, skills auto-available" -ForegroundColor Gray
}

if ($Target -eq "workspace" -or $Target -eq "all") {
    Write-Host "`nWorkspace Skills:" -ForegroundColor Cyan
    Write-Host "  Location: skills\dbcli\" -ForegroundColor Gray
    Write-Host "  Usage: Available to Cursor, Windsurf, Continue, etc." -ForegroundColor Gray
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Restart your AI assistant (if needed)" -ForegroundColor White
Write-Host "2. Test a skill:" -ForegroundColor White
Write-Host "   Ask: 'Query my SQLite database for all users'" -ForegroundColor Gray
Write-Host "3. See skills\\README.md for platform-specific usage" -ForegroundColor White
Write-Host ""

exit 0

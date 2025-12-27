# DbCli Skills - Installation Guide

This directory contains universal AI Agent Skills for DbCli. These skills work with the DbCli executable.

## Prerequisites

**DbCli executable is required**. The skills documentation references the `dbcli` command, which must be installed and accessible in your system PATH.

### Where to Get DbCli

DbCli executables are available in the parent directory:

- **Windows**: `../dist/dbcli.exe` or download `dbcli-win-x64-v1.0.0.zip`
- **Linux**: `../dist-linux/dbcli` or download `dbcli-linux-x64-v1.0.0.zip`

## Installation Options

### Option 1: Install DbCli + Skills Together (Recommended)

Use the deployment script as the single automated entrypoint (installs `dbcli` and deploys skills to your chosen AI assistant):

#### PowerShell (Windows/Linux/macOS with pwsh)

```powershell
# Run from the repository root
pwsh .\deploy-skills.ps1 -InstallExe -AddToPath -Target all -Force
```

#### Python (Windows/Linux/macOS)

```bash
# Run from the repository root
python3 deploy-skills.py --install-exe --add-to-path --target all --force
```

---

### Option 2: Install DbCli Only

If you just want the command-line tool without AI agent integration:

#### Windows

```powershell
# Extract to tools directory
Expand-Archive dbcli-win-x64-v1.0.0.zip -DestinationPath $env:USERPROFILE\tools\dbcli

# Add to PATH
$path = "$env:USERPROFILE\tools\dbcli"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$path", "User")

# Restart terminal, then verify
dbcli --help
```

#### Linux/macOS

```bash
# Extract and install
unzip dbcli-linux-x64-v1.0.0.zip
sudo mv dbcli /usr/local/bin/
sudo chmod +x /usr/local/bin/dbcli

# Verify
dbcli --help
```

See `../dist/INSTALL.md` (Windows) or `../dist-linux/INSTALL.md` (Linux) for detailed instructions.

---

### Option 3: Install Skills for AI Agents

If DbCli is already installed and you only need to add skills to your AI agent:

#### For Claude Code

```bash
# Copy skills to Claude's skills directory
cp -r skills ~/.claude/skills/dbcli
```

#### For GitHub Copilot

Copy `skills/` to your workspace and reference in `.github/copilot-instructions.md`:

```markdown
# Available Skills
- dbcli-query - Query databases
- dbcli-exec - Execute INSERT/UPDATE/DELETE
- dbcli-db-ddl - Manage table structures
[... etc]
```

#### For Generic AI Agents

```bash
# Copy to your agent's skills directory
cp -r skills /path/to/your-agent/skills/dbcli
```

---

## Directory Structure After Installation

### Windows
```
%USERPROFILE%/
├── tools/
│   └── dbcli/
│       └── dbcli.exe          # Main executable
└── .dbcli/
    └── skills/                # AI Agent Skills
        ├── README.md
        ├── CONNECTION_STRINGS.md
        ├── dbcli-query/
        ├── dbcli-exec/
        ├── dbcli-db-ddl/
        ├── dbcli-view/
        ├── dbcli-index/
        ├── dbcli-procedure/
        └── ...
```

### Linux/macOS
```
~/
├── .local/
│   └── bin/
│       └── dbcli              # Main executable
└── .dbcli/
    └── skills/                # AI Agent Skills
        ├── README.md
        ├── CONNECTION_STRINGS.md
        ├── dbcli-query/
        ├── dbcli-exec/
        └── ...
```

---

## Verification

After installation, verify both DbCli and skills are working:

```bash
# Check DbCli is installed
dbcli --version
dbcli --help

# Test with SQLite (no connection string needed)
dbcli -c "Data Source=test.db" query "SELECT 'Hello from DbCli!' as message"

# List available skills (if using Claude Code)
ls ~/.claude/skills/dbcli/
```

Expected output:
```
dbcli-query/  dbcli-exec/  dbcli-db-ddl/  dbcli-tables/  
dbcli-export/  dbcli-view/  dbcli-index/  dbcli-procedure/  
dbcli-interactive/  README.md  CONNECTION_STRINGS.md
```

---

## Quick Start with Skills

Once installed, AI agents can use skills like:

**In Claude Code CLI:**
```bash
# Use the query skill
/use dbcli-query "Show me all tables"

# Use the backup skill before modifying data
/use dbcli-exec "I need to update user emails, help me create a backup first"
```

**In GitHub Copilot:**
Type in editor:
```javascript
// @dbcli-query: get all users from SQLite database
```

Copilot will suggest:
```javascript
const { execSync } = require('child_process');
const users = JSON.parse(
  execSync('dbcli -c "Data Source=app.db" query "SELECT * FROM Users"').toString()
);
```

---

## Troubleshooting

### "dbcli: command not found"

**Cause**: DbCli is not in your PATH.

**Solution**:

Windows:
```powershell
# Check if in PATH
where.exe dbcli

# If not found, add manually
$path = "$env:USERPROFILE\tools\dbcli"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$path", "User")
# Restart terminal
```

Linux/macOS:
```bash
# Check if in PATH
which dbcli

# If not found, add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Skills Not Recognized by AI Agent

**Cause**: Skills directory not in agent's search path.

**Solution**:

For Claude Code:
```bash
# Check skills location
ls ~/.claude/skills/

# If empty, copy skills
cp -r skills ~/.claude/skills/dbcli
```

For GitHub Copilot:
- Ensure `.github/copilot-instructions.md` references the skills
- Or place skills in project root under `skills/` directory

### Permission Denied (Linux)

**Cause**: dbcli binary is not executable.

**Solution**:
```bash
sudo chmod +x /usr/local/bin/dbcli
# Or if in ~/.local/bin
chmod +x ~/.local/bin/dbcli
```

---

## Uninstallation

### Windows

```powershell
# Remove from PATH
$path = "$env:USERPROFILE\tools\dbcli"
$newPath = ($env:PATH -split ';' | Where-Object { $_ -ne $path }) -join ';'
[Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

# Delete files
Remove-Item -Recurse -Force "$env:USERPROFILE\tools\dbcli"
Remove-Item -Recurse -Force "$env:USERPROFILE\.dbcli"
```

### Linux/macOS

```bash
# Remove executable
sudo rm /usr/local/bin/dbcli
# Or if installed in user directory
rm ~/.local/bin/dbcli

# Remove skills
rm -rf ~/.dbcli
rm -rf ~/.claude/skills/dbcli
```

---

## Platform-Specific Notes

### Windows
- Requires .NET 10 Runtime (included in self-contained build)
- Works in PowerShell, CMD, and Git Bash
- Use `dbcli.exe` or just `dbcli` in commands

### Linux
- Binary is built for x64 architecture
- Self-contained (no .NET installation required)
- Tested on Ubuntu 20.04+, Debian 11+, RHEL 8+

### macOS
- Use Linux binary with Rosetta 2 on Apple Silicon (M1/M2)
- Or build from source for native ARM64

---

## Building from Source

If you need to build DbCli from source:

```bash
# Clone repository
git clone https://github.com/your-repo/dbcli.git
cd dbcli

# Build for your platform
dotnet publish -c Release -r win-x64 --self-contained
# Or for Linux
dotnet publish -c Release -r linux-x64 --self-contained

# Output will be in:
# bin/Release/net10.0/win-x64/publish/
# or bin/Release/net10.0/linux-x64/publish/
```

---

## Additional Resources

- **Main Documentation**: [../README.md](../README.md)
- **Windows Install Guide**: [../dist/INSTALL.md](../dist/INSTALL.md)
- **Linux Install Guide**: [../dist-linux/INSTALL.md](../dist-linux/INSTALL.md)
- **Skills Reference**: [README.md](README.md)
- **Connection Strings**: [CONNECTION_STRINGS.md](CONNECTION_STRINGS.md)
- **AI Integration**: [../AI_INTEGRATION.md](../AI_INTEGRATION.md)

---

## Support

- **GitHub Issues**: https://github.com/your-repo/dbcli/issues
- **Discussions**: https://github.com/your-repo/dbcli/discussions

---

**License**: MIT  
**Version**: 1.0.0  


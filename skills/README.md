# DbCli Agent Skills

Universal agent skills for DbCli - cross-database CLI tool supporting 30+ databases.

## Skills Specification Format

These skills conform to the [Agent Skills Specification](https://agentskills.io/specification) - a universal format compatible with 10+ coding agents (e.g. Claude Code, Claude Web/App, GitHub Copilot, OpenAI Codex, Cursor, Gemini Code Assist, Gemini-Cli, and VS Code extensions like Cline, Roo Code, Kilo Code).

## Available Skills

| Skill | Description | Safety Level |
|-------|-------------|--------------|
| [**dbcli-query**](dbcli-query/) | Execute SELECT queries | Safe (read-only) |
| [**dbcli-exec**](dbcli-exec/) | Execute INSERT/UPDATE/DELETE | Requires backup for UPDATE/DELETE |
| [**dbcli-db-ddl**](dbcli-db-ddl/) | Execute CREATE/ALTER/DROP tables | Critical - mandatory backup |
| [**dbcli-tables**](dbcli-tables/) | List tables and view structure | Safe (read-only) |
| [**dbcli-export**](dbcli-export/) | Export table data as SQL | Safe (backup operation) |
| [**dbcli-compare**](dbcli-compare/) | Compare results of two SQL queries | Safe (read-only) |
| [**dbcli-view**](dbcli-view/) | Manage database views | Moderate - backup recommended |
| [**dbcli-index**](dbcli-index/) | Manage database indexes | Moderate - backup recommended |
| [**dbcli-procedure**](dbcli-procedure/) | Manage stored procedures/functions/triggers | Critical - mandatory backup |
| [**dbcli-interactive**](dbcli-interactive/) | Interactive SQL mode (REPL) | Safety prompts enabled |

## Command Style (Use PATH)

All examples in skills use the plain command name `dbcli` (no directory prefix).  
Ensure `dbcli` is on PATH (e.g., run `install-dbcli.ps1 -AddToPath`) instead of hardcoding paths like `.\.claude\skills\dbcli\dbcli.exe`.

## Parameterized SQL (RDB)

DbCli supports parameterized SQL for relational databases using JSON parameters and `@Param` placeholders:

```bash
dbcli query "SELECT @Id AS Id" -p '{"Id":1}'
dbcli exec "INSERT INTO Users (Id, Name) VALUES (@Id, @Name)" -p '{"Id":1,"Name":"Alice"}'
```

Notes:

- `IN (...)` supports JSON arrays (DbCli expands `@Ids`).
- SQLite providers may require `DisableClearParameters: true` in config (maps to SqlSugar `IsClearParameters=false`).
- SQL Server supports `GO` batch separators for `ddl` and non-parameterized `exec`. `GO` is not supported with `-p/-P`.
- DbCli returns a single result set. SqlSugar supports multi-result sets/output parameters, but DbCli does not surface them yet.

## Installation

### Quick Install (Recommended)

Use the deployment script as the single automated entrypoint (it can also install `dbcli`):

```powershell
# PowerShell (Windows/Linux/macOS with pwsh)
pwsh ./deploy-skills.ps1 -InstallScripts -Target all -WorkDir . -Force
```

```bash
# Python (Linux/macOS/WSL)
python3 ./deploy-skills.py --install-scripts --target all --force
```

Note: PowerShell requires `-WorkDir` (target workspace). `-InstallScripts` installs dbcli + scripts + skills into `~/tools/dbcli` and adds PATH (required). It also copies deploy scripts into `tools/dbcli/` under the target (Codex global deploy does not copy scripts or exe).

### For AI Agents Only

If DbCli is already installed:

```bash
# Claude Code
mkdir -p ./.claude/skills/dbcli/skills
cp -r skills/* ./.claude/skills/dbcli/skills/

# Generic AI agent
cp -r skills /path/to/agent/skills/dbcli
```

### Claude (Web/App) ZIP Upload

Claude (web/app) expects a ZIP containing **one** skill folder, with `Skill.md` at the skill root. Use the deploy scripts to package ZIPs (they stage a temp copy and set the ZIP entry name to `Skill.md` without changing your source tree):

```powershell
pwsh ./deploy-skills.ps1 -PackageClaudeSkill dbcli-query -PackageOutDir .
pwsh ./deploy-skills.ps1 -PackageClaudeAll -PackageOutDir .
```

```bash
python3 ./deploy-skills.py --package-claude-skill dbcli-query --package-out-dir .
python3 ./deploy-skills.py --package-claude-all --package-out-dir .
```

### For Developers

Skills can be referenced directly from this repository or cloned locally:

```bash
git clone https://github.com/yourusername/dbcli.git
cd dbcli/skills
```

## Skill Categories

### Read-Only Operations (Safe)

- **dbcli-query** - Execute SELECT queries
- **dbcli-tables** - List tables and view structure
- **dbcli-compare** - Compare results of two SQL queries

### Data Modification (Backup Required)

- **dbcli-exec** - INSERT/UPDATE/DELETE operations
- **dbcli-export** - Export table data (for backup)

### Schema Modification (Critical - Backup Mandatory)


## CLI Options (`--help`)

DbCli commands and options are defined per-command. Use `dbcli --help` / `dbcli <command> --help` as the source of truth. Options shown in examples (like `-c/-t/-f/-F`) are not truly “global” — they exist only on the commands that define them.

- `-F/--file` is available only on `query/exec/ddl` (read SQL from a file)
- `backup` additionally supports `-o/--target`
- `restore` additionally supports `-s/--from` and `-k/--keep-data`
- `export-schema` accepts a positional `<type>` (e.g. `all/view/index`) and supports `-n/--name`, `-o/--output`, and `--output-dir`

For the full, current parameter list, run:

- `dbcli --help`
- `dbcli query --help`
- `dbcli exec --help`
- `dbcli ddl --help`
- `dbcli backup --help`
- `dbcli restore --help`
- `dbcli export-schema --help`
### Interactive Mode (Safety Prompts)
- **dbcli-interactive** - Interactive SQL with built-in safety prompts

## Supported Databases

All skills support 30+ databases including:

### Relational Databases
SQLite, Microsoft SQL Server, MySQL, MySQL Connector, MariaDB, TiDB, PostgreSQL, Oracle, DaMeng, KingbaseES, Oscar, HighGo, GaussDB, GBase, IBM DB2, SAP HANA, Microsoft Access

### Distributed & Cloud
OceanBase, TDengine, ClickHouse, Amazon Aurora, Azure Database, Google Cloud SQL

### Analytics
QuestDB, DuckDB

### NoSQL
MongoDB

See [CONNECTION_STRINGS.md](CONNECTION_STRINGS.md) for detailed connection examples.

## Quick Start

### 1. Install DbCli + Skills

```powershell
pwsh ./deploy-skills.ps1 -InstallScripts -Target all -WorkDir . -Force
```

```bash
python3 ./deploy-skills.py --install-scripts --target all --force
```

### 2. Deploy to AI Assistant

**Quick Deploy (workspace only for Claude/Copilot):**

Note: Claude Code / Copilot only support workspace deployment (global locations are ignored).

```powershell
# Windows / Linux / macOS (pwsh)
pwsh ./deploy-skills.ps1 -Target claude -WorkDir .    # Claude Code only
pwsh ./deploy-skills.ps1 -Target all -WorkDir .       # All environments

# Python (Linux/macOS/WSL)
python3 ./deploy-skills.py --target claude
python3 ./deploy-skills.py --target all
```


**Supported AI Assistants:**
- Claude Code
- Claude (Web/App)
- GitHub Copilot
- OpenAI Codex
- OpenAI-compatible API (Direct)
- Cursor
- Gemini Code Assist
- Gemini-Cli
- Cline
- Roo Code
- Kilo Code

See the [Integration Guide](INTEGRATION.md) and [DbCli README](../README.md) for details.

### 3. Use Skills

```bash
# SQLite (using environment variables)
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"
dbcli query "SELECT * FROM Users"

# Microsoft SQL Server
export DBCLI_CONNECTION="Server=localhost;Database=mydb;Trusted_Connection=True"
dbcli -t sqlserver query "SELECT TOP 10 * FROM Users"
```

### 2. Safe Data Modification

```bash
# ALWAYS create backup first
export DBCLI_CONNECTION="Data Source=app.db"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
dbcli export Users > Users_backup_${TIMESTAMP}.sql

# Then modify
dbcli exec "UPDATE Users SET verified = 1 WHERE email_confirmed = 1"
```

### 3. Explore Schema

```bash
# Set connection
export DBCLI_CONNECTION="Data Source=app.db"

# List all tables
dbcli -f table tables

# View table structure
dbcli -f table columns Users
```

### 4. Interactive Mode

```bash
# Start interactive session
export DBCLI_CONNECTION="Data Source=app.db"
dbcli interactive

# Then use dot commands:
dbcli> .tables
dbcli> .columns Users
dbcli> SELECT * FROM Users LIMIT 5;
dbcli> .exit
```

## Safety Guidelines

### Backup Before Dangerous Operations

**MANDATORY** backup creation before:
- UPDATE operations
- DELETE operations
- DROP TABLE
- ALTER TABLE

### Default Backup Naming Convention

```
tablename_copy_YYYYMMDD_HHMMSS           # Table copy (fastest recovery)
tablename_backup_YYYYMMDD_HHMMSS.sql     # SQL export (portable)
database_backup_YYYYMMDD_HHMMSS.db       # Full database (SQLite)
```

### Quick Backup Commands

```bash
export DBCLI_CONNECTION="Data Source=mydb.db"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Method 1: Table copy (fastest)
dbcli query "CREATE TABLE Users_copy_${TIMESTAMP} AS SELECT * FROM Users"

# Method 2: SQL export (portable)
dbcli export Users > Users_backup_${TIMESTAMP}.sql

# Method 3: Full database backup (SQLite)
cp mydb.db mydb_backup_${TIMESTAMP}.db
```

## Configuration Methods

### Method 1: Environment Variables (Recommended)

```bash
# Linux/macOS
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"
dbcli query "SELECT * FROM Users"

# Windows PowerShell
$env:DBCLI_CONNECTION = "Data Source=app.db"
$env:DBCLI_DBTYPE = "sqlite"
dbcli query "SELECT * FROM Users"
```
[Environment]::SetEnvironmentVariable("DBCLI_DBTYPE", "sqlite", "User")

# Then use without connection string
dbcli query "SELECT * FROM Users"
```

### Method 3: Configuration File

Create `appsettings.json`:

```json
{
  "ConnectionString": "Data Source=app.db",
  "DbType": "sqlite"
}
```

Usage:

```bash
# If appsettings.json is in the current working directory, DbCli auto-loads it
dbcli query "SELECT * FROM Users"
```

## Common Options Reference

DbCli options are defined per-command (use `dbcli <command> --help` as the source of truth). The following are the most commonly used options across many commands:

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--db-type` | `-t` | Database type | `sqlite` |
| `--format` | `-f` | Output format (json/table/csv) | `json` |
| `--config` | - | Config file path | - |
| `--file` | `-F` | Read SQL from file (query/exec/ddl only) | - |

**Connection Method**: Use `appsettings.json` in the current working directory (DbCli auto-loads it) or environment variables `DBCLI_CONNECTION` and `DBCLI_DBTYPE`.

## Command Format (ConsoleAppFramework)

DbCli uses ConsoleAppFramework (command-first routing).

```bash
# Set connection via environment variable
export DBCLI_CONNECTION="Data Source=app.db"

# Execute query
dbcli query "SELECT * FROM Users" -f table
```

## Programmatic Usage

### Python Example

```python
import subprocess
import json
import os

# Set environment
os.environ['DBCLI_CONNECTION'] = 'Data Source=app.db'

# Query database
result = subprocess.run([
    'dbcli', 'query', 'SELECT * FROM Users'
], capture_output=True, text=True)

users = json.loads(result.stdout)
for user in users:
    print(f"{user['Name']} - {user['Email']}")
```

### Node.js Example

```javascript
const { execSync } = require('child_process');

// Set environment
process.env.DBCLI_CONNECTION = 'Data Source=app.db';

const result = execSync('dbcli query "SELECT * FROM Users"');
const users = JSON.parse(result.toString());

users.forEach(user => {
    console.log(`${user.Name} - ${user.Email}`);
});
```

### PowerShell Example

```powershell
$env:DBCLI_CONNECTION = "Data Source=app.db"
$result = dbcli query "SELECT * FROM Users" | ConvertFrom-Json
$result | ForEach-Object { Write-Host "$($_.Name) - $($_.Email)" }
```

## Skill Compatibility

These skills are compatible with Claude Code, GitHub Copilot, OpenAI Codex, Cursor, Gemini-Cli, Cline/Roo/Kilo, and any Agent Skills-compliant AI coding assistant.

## Directory Structure

```
skills/
├── README.md                          # This file
├── CONNECTION_STRINGS.md              # Database connection reference
│
├── dbcli-query/
│   └── SKILL.md                       # Query skill
│
├── dbcli-exec/
│   └── SKILL.md                       # Execute (INSERT/UPDATE/DELETE) skill
│
├── dbcli-db-ddl/
│   └── SKILL.md                       # DDL (CREATE/ALTER/DROP tables) skill
│
├── dbcli-tables/
│   └── SKILL.md                       # List tables skill
│
├── dbcli-export/
│   └── SKILL.md                       # Export data skill
│
├── dbcli-view/
│   └── SKILL.md                       # View management skill
│
├── dbcli-index/
│   └── SKILL.md                       # Index management skill
│
├── dbcli-procedure/
│   └── SKILL.md                       # Procedure/function/trigger management skill
│
└── dbcli-interactive/
    └── SKILL.md                       # Interactive mode skill
```

## Contributing

Skills follow the [Agent Skills Specification](https://agentskills.io/specification):

- **name**: lowercase-with-hyphens (max 64 chars)
- **description**: 1-1024 chars, includes use cases
- **SKILL.md**: YAML frontmatter + Markdown body
- **Progressive disclosure**: Metadata → Instructions → Resources

## See Also

- [Agent Skills Specification](https://agentskills.io/specification)
- [Connection Strings](CONNECTION_STRINGS.md) - 30+ database examples
- [OpenAI Codex Skills](https://developers.openai.com/codex/skills)
- [Claude Skills](https://support.claude.com/en/articles/12512180-using-skills-in-claude)

## License

MIT - See [LICENSE](../LICENSE) for details


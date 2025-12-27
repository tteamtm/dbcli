# DbCli Agent Skills

Universal agent skills for DbCli - cross-database CLI tool supporting 30+ databases.

## Skills Specification Format

These skills conform to the [Agent Skills Specification](https://agentskills.io/specification) - a universal format compatible with multiple AI coding assistants including GitHub Copilot, OpenAI Codex, Claude Code, Gemini CLI, Cline/Roo/Kilo, et al.

## Available Skills

| Skill | Description | Safety Level |
|-------|-------------|--------------|
| [**dbcli-query**](dbcli-query/) | Execute SELECT queries | Safe (read-only) |
| [**dbcli-exec**](dbcli-exec/) | Execute INSERT/UPDATE/DELETE | Requires backup for UPDATE/DELETE |
| [**dbcli-db-ddl**](dbcli-db-ddl/) | Execute CREATE/ALTER/DROP tables | Critical - mandatory backup |
| [**dbcli-tables**](dbcli-tables/) | List tables and view structure | Safe (read-only) |
| [**dbcli-export**](dbcli-export/) | Export table data as SQL | Safe (backup operation) |
| [**dbcli-view**](dbcli-view/) | Manage database views | Moderate - backup recommended |
| [**dbcli-index**](dbcli-index/) | Manage database indexes | Moderate - backup recommended |
| [**dbcli-procedure**](dbcli-procedure/) | Manage stored procedures/functions/triggers | Critical - mandatory backup |
| [**dbcli-interactive**](dbcli-interactive/) | Interactive SQL mode (REPL) | Safety prompts enabled |

## Installation

### Quick Install (Recommended)

Use the deployment script as the single automated entrypoint (it can also install `dbcli`):

```powershell
# PowerShell (Windows/Linux/macOS with pwsh)
pwsh .\deploy-skills.ps1 -InstallExe -AddToPath -Target all -Force
```

```bash
# Python (Windows/Linux/macOS)
python3 deploy-skills.py --install-exe --add-to-path --target all --force
```

### For AI Agents Only

If DbCli is already installed:

```bash
# Claude Code
cp -r skills ~/.claude/skills/dbcli

# Generic AI agent
cp -r skills /path/to/agent/skills/dbcli
```

### For Developers

Skills can be referenced directly from this repository or cloned locally:

```bash
git clone https://github.com/yourusername/dbcli.git
cd dbcli/skills
```

## Skill Categories

### Read-Only Operations (Safe)

### Data Modification (Backup Required)

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
SQLite, SQL Server, MySQL, PostgreSQL, Oracle

### Chinese Domestic Databases
- DaMeng (达梦)
- KingbaseES (人大金仓)
- Oscar (神通)
- GaussDB (华为)
- GBase (南大通用)

### Distributed & Cloud
OceanBase, TDengine, ClickHouse, Amazon Aurora, Azure Database, Google Cloud SQL

### Analytics & Enterprise
QuestDB, DuckDB, IBM DB2, SAP HANA, Microsoft Access

### NoSQL
MongoDB

See [CONNECTION_STRINGS.md](CONNECTION_STRINGS.md) for detailed connection examples.

## Quick Start

### 1. Install DbCli + Skills

```powershell
pwsh .\deploy-skills.ps1 -InstallExe -AddToPath -Target all -Force
```

```bash
python3 deploy-skills.py --install-exe --add-to-path --target all --force
```

### 2. Deploy to AI Assistant

**Quick Deploy:**

```powershell
# Windows
.\deploy-skills.ps1 -Target claude    # Claude Code only
.\deploy-skills.ps1 -Target all       # All environments

# Linux/macOS
python3 deploy-skills.py --target claude
python3 deploy-skills.py --target all
```

**Supported AI Assistants:**
- Claude Code
- GitHub Copilot
- Cursor IDE
- Windsurf (Codeium)
- Continue Dev
- And more...

See [INTEGRATION.md](INTEGRATION.md) and [../README.md](../README.md) for details.

### 3. Use Skills

```bash
# SQLite
dbcli -c "Data Source=app.db" query "SELECT * FROM Users"

# SQL Server
dbcli -c "Server=localhost;Database=mydb;Trusted_Connection=True" -t sqlserver query "SELECT TOP 10 * FROM Users"
```

### 2. Safe Data Modification

```bash
# ALWAYS create backup first
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
dbcli -c "Data Source=app.db" export Users > Users_backup_${TIMESTAMP}.sql

# Then modify
dbcli -c "Data Source=app.db" exec "UPDATE Users SET verified = 1 WHERE email_confirmed = 1"
```

### 3. Explore Schema

```bash
# List all tables
dbcli -c "Data Source=app.db" -f table tables

# View table structure
dbcli -c "Data Source=app.db" -f table columns Users
```

### 4. Interactive Mode

```bash
# Start interactive session
dbcli -c "Data Source=app.db" interactive

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
# Method 1: Table copy (fastest)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
dbcli -c "Data Source=mydb.db" query "CREATE TABLE Users_copy_${TIMESTAMP} AS SELECT * FROM Users"

# Method 2: SQL export (portable)
dbcli -c "Data Source=mydb.db" export Users > Users_backup_${TIMESTAMP}.sql

# Method 3: Full database backup (SQLite)
cp mydb.db mydb_backup_${TIMESTAMP}.db
```

## Configuration Methods

### Method 1: Command Line (Direct)

```bash
dbcli -c "Data Source=app.db" -t sqlite query "SELECT * FROM Users"
```

### Method 2: Environment Variables

```bash
# Linux/macOS
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"

# Windows PowerShell
[Environment]::SetEnvironmentVariable("DBCLI_CONNECTION", "Data Source=app.db", "User")
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
dbcli --config appsettings.json query "SELECT * FROM Users"
```

## Common Options Reference

DbCli options are defined per-command (use `dbcli <command> --help` as the source of truth). The following are the most commonly used options across many commands:

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--connection` | `-c` | Database connection string | Required |
| `--db-type` | `-t` | Database type | `sqlite` |
| `--format` | `-f` | Output format (json/table/csv) | `json` |
| `--config` | - | Config file path | - |
| `--file` | `-F` | Read SQL from file (query/exec/ddl only) | - |

## Command Format (ConsoleAppFramework)

DbCli uses ConsoleAppFramework (command-first routing). For compatibility, DbCli also accepts the legacy style where common options appear before the subcommand.

```bash
# ✓ Recommended (command-first)
dbcli query "SELECT * FROM Users" -c "Data Source=app.db" -f table

# ✓ Also supported (legacy, options before command)
dbcli -c "Data Source=app.db" -f table query "SELECT * FROM Users"
```

## Programmatic Usage

### Python Example

```python
import subprocess
import json

# Query database
result = subprocess.run([
    'dbcli', '-c', 'Data Source=app.db',
    'query', 'SELECT * FROM Users'
], capture_output=True, text=True)

users = json.loads(result.stdout)
for user in users:
    print(f"{user['Name']} - {user['Email']}")
```

### Node.js Example

```javascript
const { execSync } = require('child_process');

const result = execSync('dbcli -c "Data Source=app.db" query "SELECT * FROM Users"');
const users = JSON.parse(result.toString());

users.forEach(user => {
    console.log(`${user.Name} - ${user.Email}`);
});
```

### PowerShell Example

```powershell
$result = dbcli -c "Data Source=app.db" query "SELECT * FROM Users" | ConvertFrom-Json
$result | ForEach-Object { Write-Host "$($_.Name) - $($_.Email)" }
```

## Skill Compatibility

These skills are compatible with GitHub Copilot, OpenAI Codex, Claude Code, Gemini CLI, Cline/Roo/Kilo, and any Agent Skills-compliant AI coding assistant.

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

## Technical Information

- **Tool**: DbCli
- **Version**: 1.0.0
- **Runtime**: .NET 10
- **ORM**: SqlSugar 5.1.4.211
- **CLI Framework**: ConsoleAppFramework 5.7.13
- **License**: MIT
- **Platform**: Windows, Linux, macOS

## Contributing

Skills follow the [Agent Skills Specification](https://agentskills.io/specification):

- **name**: lowercase-with-hyphens (max 64 chars)
- **description**: 1-1024 chars, includes use cases
- **SKILL.md**: YAML frontmatter + Markdown body
- **Progressive disclosure**: Metadata → Instructions → Resources

## See Also

- [Agent Skills Specification](https://agentskills.io/specification)
- [Integration Guide](INTEGRATION.md) - How to integrate with AI assistants
- [Connection Strings](CONNECTION_STRINGS.md) - 30+ database examples
- [DbCli Documentation](../README.md)
- [Connection String Reference](CONNECTION_STRINGS.md)

## License

MIT - See [LICENSE](../LICENSE) for details


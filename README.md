# DbCli - Database CLI Tool for AI Agents Support for 30+ Databases

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Universal Database CLI with [Agent Skills Specification](https://agentskills.io) support**

Cross-database command line tool based on .NET 10 and SqlSugar, designed for AI agent integration through Agent Skills Specification.

CLI routing is implemented with ConsoleAppFramework.

## Table of Contents

- [Features](#features)
- [Supported Databases](#supported-databases)
- [AI Agent Integration](#-ai-agent-integration)
- [Quick Setup](#quick-setup)
- [Development(Build-Publish-Deploy)](#developmentbuild-publish-deploy)
- [Backup & Restore](#️-backup--restore)
- [Command Reference](#command-reference)
- [Global Options](#global-options)
- [Command Arguments & Options](#command-arguments--options)
- [Usage Examples](#usage-examples)
- [Connection String Reference](#connection-string-reference)
- [Config File Examples](#config-file-examples)
- [Interactive Mode](#interactive-mode)
- [Using in CI/CD](#using-in-cicd)
- [Documentation](#-documentation)
- [Resources](#-resources)
- [License](#license)

---

## Features

- Supports 30+ databases (see [Supported Databases](#supported-databases))
- Multiple output formats: JSON, Table, CSV
- Interactive SQL mode
- Configurable connection strings (command line, config file, environment variables)
- Single executable deployment (self-contained single-file binaries)
- Agent Skills Specification support

## Supported Databases

Supports 30+ databases including:

- **Relational Databases**: SQLite, Microsoft SQL Server, MySQL, MySQL Connector, MariaDB, TiDB, PostgreSQL, Oracle, DaMeng (DM), KingbaseES (Kdbndp), Oscar, HighGo (HG), GaussDB, GBase, IBM DB2, SAP HANA, Microsoft Access
- **Distributed Databases**: OceanBase, PolarDB, TDengine, ClickHouse, Doris
- **Analytics Databases**: QuestDB, DuckDB
- **NoSQL Databases**: MongoDB
- **MySQL Ecosystem** (MySQL-compatible, use `-t mysql`): Percona Server, Amazon Aurora, Azure Database for MySQL, Google Cloud SQL for MySQL
- **Generic Connectors**: ODBC, Custom database

## 🤖 AI Agent Integration

DbCli follows the **[Agent Skills Specification](https://agentskills.io)** - a universal format for AI assistants to discover and use tools.

**Agent Skills** are standardized tool definitions that AI assistants can:
- ✅ **Discover automatically** - No manual configuration needed
- ✅ **Understand context** - Clear descriptions, examples, and error handling
- ✅ **Execute safely** - Built-in validation and backup recommendations
- ✅ **Share across Platforms and Coding Agents** - Works with Claude Code, GitHub Copilot, OpenAI Codex, Cursor, Gemini Code Assist, Gemini-Cli, Cline/Roo/Kilo, and more on Windows, macOS, Linux

### 🎯 Use Cases & Scenarios

**1. Data Analysis & Reporting**
```
AI Assistant → dbcli-query skill → Database
"Show me top 10 customers by revenue this month"
→ Generates: SELECT query with proper aggregation and filtering
```

**2. Database Management**
```
AI Assistant → dbcli-db-ddl skill → Database
"Create a users table with email validation"
→ Generates: CREATE TABLE with appropriate constraints
```

**3. Automated Backups**
```
AI Assistant → dbcli-export skill → SQL Files
"Export all critical tables before deployment"
→ Generates: Backup scripts with timestamps
```

**4. Cross-Database Operations**
```
Your App → AI Assistant → DbCli Skills → 30+ Databases
Works seamlessly with SQLite, PostgreSQL, MySQL, Oracle, Microsoft SQL Server,DaMeng, KingbaseES, Oscar, HighGo, GaussDB, GBase and more
```

## Quick Setup

### 1) Download & Extract Release Zip

Download the matching zip from GitHub Releases and extract it to a folder.

- Windows: `dbcli-win-x64-vX.Y.Z.zip` / `dbcli-win-arm64-vX.Y.Z.zip`
- Linux: `dbcli-linux-x64-vX.Y.Z.zip` / `dbcli-linux-arm64-vX.Y.Z.zip`
- macOS: `dbcli-macos-x64-vX.Y.Z.zip` / `dbcli-macos-arm64-vX.Y.Z.zip`

### 2) Install + Deploy Skills (recommended)

**PowerShell (Windows / Linux / macOS with pwsh):**

```bash
# Run inside the extracted zip folder
# -InstallScripts installs dbcli + scripts + skills to ~/tools/dbcli and adds it to PATH.
pwsh -NoProfile -ExecutionPolicy Bypass -File .\deploy-skills.ps1 -InstallScripts -Target all -WorkDir <workspace_dir> -Force
```

**Linux / macOS / WSL (Python):**

```bash
# Run inside the extracted zip folder
python3 ./install-dbcli.py --force

# Deploy skills: run from your project root (deploy-skills.py uses current directory for workspace output)
cd <workspace_dir>
python3 <path-to-extracted-zip>/deploy-skills.py --target all --force
```

**Deployment targets:** `claude`, `copilot`, `codex`, `workspace`, `all`  
**Common options:** PowerShell `-Force`, `-WorkDir` (required for non-Codex-global targets), `-CodexGlobalOnly` (Codex user profile only); Python `--force`, `--codex-global-only`  
**Verify:** `dbcli --version` and check your deployed files (`.github/copilot-instructions.md`, `skills/dbcli/`, workspace `.claude/skills/dbcli/skills/`).

**Claude (Web/App) ZIP upload:** `pwsh ./deploy-skills.ps1 -PackageClaudeSkill dbcli-query -PackageOutDir .` (or `python3 ./deploy-skills.py --package-claude-skill dbcli-query --package-out-dir .`), then upload the ZIP in Claude Settings → Capabilities → Skills.

**Rules integration (summary):** deployment appends DbCli execution rules (PATH + safety) into common rule files if present:
`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.vscode/context.md`, `.gemini/skills.yaml`, and `.github/copilot-instructions.md`.
See [`skills/INTEGRATION.md`](skills/INTEGRATION.md) for full details.

---

## Development(Build-Publish-Deploy)

This is the simplest end-to-end workflow when you build DbCli from source and then deploy the skills to an AI assistant.

### 1) Publish

```powershell
# Build self-contained single-file binaries + dist-* folders (recommended)
pwsh ./publish-all.ps1
```

Or publish only your current platform:

```powershell
dotnet publish .\dbcli.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o .\dist-win-x64
```

#### Linux / WSL (Install & Run)

If you're using WSL (or a Linux machine), publish the Linux binary inside WSL/Linux:

```bash
# Build linux-x64 into dist-linux-x64
dotnet publish ./dbcli.csproj -c Release -r linux-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o ./dist-linux-x64
```

Then inside WSL/Linux:

```bash
chmod +x ./dist-linux-x64/dbcli
mkdir -p ~/.local/bin
cp ./dist-linux-x64/dbcli ~/.local/bin/dbcli
export PATH="$HOME/.local/bin:$PATH"

dbcli --version
dbcli --help
```

Tip: for best performance on WSL, prefer working under the Linux filesystem (e.g. `~/src/...`) instead of `/mnt/c/...`.

#### macOS (Install & Run)

If you're on macOS, publish for your CPU:

```bash
# Apple Silicon
dotnet publish ./dbcli.csproj -c Release -r osx-arm64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o ./dist-macos-arm64

# Intel
dotnet publish ./dbcli.csproj -c Release -r osx-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o ./dist-macos-x64
```

Then:

```bash
chmod +x ./dist-macos-*/dbcli
mkdir -p ~/.local/bin
cp ./dist-macos-*/dbcli ~/.local/bin/dbcli
export PATH="$HOME/.local/bin:$PATH"

dbcli --version
dbcli --help
```

Deploy skills using the Python script (recommended on Linux/macOS/WSL):

```bash
# Install dbcli + scripts + skills into ~/tools/dbcli and add it to PATH
python3 ./deploy-skills.py --install-scripts --target copilot --force

# Or deploy to all supported targets
python3 ./deploy-skills.py --install-scripts --target all --force
```

### Global Deploy (Claude) + Later Workspace Deploy (Recommended Flow)

1) **Global deploy (Claude)**: extract the release to `~/tools/dbcli` (or `C:\Users\<you>\tools\dbcli`), then run:
```powershell
pwsh -File "$env:USERPROFILE\tools\dbcli\deploy-skills.ps1" -Target claude -WorkDir <workspace_dir> -Force
```
1) **Global deploy (Codex, recommended)**: use the same install location, then run:
```powershell
pwsh -File "$env:USERPROFILE\tools\dbcli\deploy-skills.ps1" -Target codex -CodexGlobalOnly -Force
```
Note: `-CodexGlobalOnly` deploys to the user profile (`~/.codex`) only. Other global-only targets are not supported.
Or deploy to all supported targets:
```powershell
pwsh -File "$env:USERPROFILE\tools\dbcli\deploy-skills.ps1" -Target all -WorkDir <workspace_dir> -Force
```

1) **Deploy to any workspace later**: reuse the scripts from `tools/dbcli` to copy into the target workspace:
```powershell
pwsh -File "$env:USERPROFILE\tools\dbcli\deploy-skills.ps1" -Target claude -WorkDir "<workspace_dir>" -Force
```
Or deploy to all supported targets:
```powershell
pwsh -File "$env:USERPROFILE\tools\dbcli\deploy-skills.ps1" -Target all -WorkDir "<workspace_dir>" -Force
```

Note: the script prefers `tools/dbcli/skills` as the source when present, and `-WorkDir` is the target workspace.
Note: Claude workspace deploy copies skills only (no exe). Ensure `dbcli` is installed and on PATH.

### 2) Install + Deploy skills

PowerShell deployment works on Windows / Linux / macOS (with `pwsh`):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\deploy-skills.ps1 -InstallScripts -Target copilot -WorkDir <workspace_dir> -Force
```

### 3) Verify

```powershell
dbcli --help

# Set connection via environment variables
$env:DBCLI_CONNECTION = "Data Source=test.db"
$env:DBCLI_DBTYPE = "sqlite"
dbcli query "SELECT 'Hello' AS message"
```

## ⚠️ Backup & Restore

**CRITICAL**: Always create backups before performing DDL (DROP, ALTER) or DML (UPDATE, DELETE) operations!

DbCli provides built-in `backup`, `restore`, and `export-schema` commands for comprehensive backup strategies:

### Schema Backup (Procedures, Functions, Triggers, Views, Indexes)

**Export DDL scripts** before dropping or modifying database objects:

```bash
# Set connection once
export DBCLI_CONNECTION="Server=.;Database=mydb"
export DBCLI_DBTYPE="sqlserver"

# Export all schema objects
dbcli export-schema all -o backup_schema.sql

# Export all schema objects as separate files (per object)
dbcli export-schema all --output-dir ./schema_export

# Export only stored procedures
dbcli export-schema procedure -o backup_procedures.sql

# Export specific procedure by name pattern
dbcli export-schema procedure --name "sp_User*"

# Export indexes for all tables
dbcli export-schema index -o backup_indexes.sql

# Export triggers
dbcli export-schema trigger -o backup_triggers.sql
```

**Supported object types**: `all`, `procedure`, `function`, `trigger`, `view`, `index`

**Supported databases**: Microsoft SQL Server, MySQL-family (incl. OceanBase/TiDB/PolarDB), PostgreSQL (incl. GaussDB/Kingbase), SQLite, Oracle, DB2, DM (coverage varies by database)

### Data Backup Commands

DbCli provides `backup` and `restore` commands powered by SqlSugar Fastest() API with intelligent backup strategies:

### Backup Command

```bash
# Set connection
export DBCLI_CONNECTION="Data Source=mydb.db"
export DBCLI_DBTYPE="sqlite"

# Auto backup (auto-generated timestamp table name)
dbcli backup Users
# Creates: Users_backup_20251227_161149

# Specify custom backup table name
dbcli backup Users -o Users_backup_before_migration

# Table format output for details
dbcli -f table backup Users
```

### Restore Command

```bash
# Set connection
export DBCLI_CONNECTION="Data Source=mydb.db"
export DBCLI_DBTYPE="sqlite"

# Restore from backup (auto-deletes existing data)
dbcli restore Users --from Users_backup_20251227_161149

# Keep existing data, append restore
dbcli restore Users --from Users_backup_20251227_161149 --keep-data

# Table format output for details
dbcli -f table restore Users --from Users_backup_20251227_161149
```

### Intelligent Backup Strategy (Auto-selects fastest method)

| Priority | Method | Use Case | Performance |
|----------|--------|----------|-------------|
| 1 | `CREATE TABLE AS SELECT` | SQLite, MySQL, PostgreSQL etc. | Fastest & compatible |
| 2 | `Fastest().BulkCopy` (DataTable) | Large data (>10k rows) | Extremely fast for big tables |
| 3 | Row-by-row INSERT | Compatibility mode | Slowest but guaranteed |

### Traditional Backup Methods (Still supported)

```bash
# SQL export (portable to other databases)
export DBCLI_CONNECTION="Data Source=mydb.db"
export DBCLI_DBTYPE="sqlite"
dbcli export Users > Users_backup_${TIMESTAMP}.sql

# Full database backup (SQLite file copy)
cp mydb.db mydb_backup_${TIMESTAMP}.db
```

### Complete Backup & Restore Workflow

```bash
# Set connection once
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"

# 1. Backup table
dbcli -f table backup Users
# ✅ Method: CreateTableAsSelect, Rows: 1000

# 2. Execute dangerous operation
dbcli exec "DELETE FROM Users WHERE Age < 18"

# 3. Found mistake, restore immediately
dbcli -f table restore Users --from Users_backup_20251227_161149
# ✅ Method: InsertIntoSelect, Rows: 1000, Deleted: True
```

See [dbcli-export skill](skills/dbcli-export/SKILL.md) for complete backup automation scripts.

## Command Reference

| Command | Alias | Description |
|---------|-------|-------------|
| `query <sql>` | `q` | Execute SELECT query |
| `exec <sql>` | `e` | Execute INSERT/UPDATE/DELETE |
| `ddl <sql>` | - | Execute CREATE/ALTER/DROP (Skill: `dbcli-db-ddl`) |
| `procedure <name>` | `proc`, `sproc` | Execute stored procedure (non-query) |
| `procedure-query <name>` | `proc-query`, `sproc-query` | Execute stored procedure and return result set |
| `tables` | `ls` | List all tables |
| `views` | `view` | List views |
| `columns <table>` | `cols` | Show table structure |
| `export <table>` | - | Export table data as SQL |
| `backup <table>` | - | Backup table (auto-selects fastest method) |
| `restore <table>` | - | Restore table from backup |
| `export-schema <type>` | `schema` | Export schema objects (procedures, functions, triggers, views, indexes) |
| `interactive` | `i` | Interactive mode |

## Global Options

Options can appear either before or after the command. Command-first is recommended, and the legacy "options before command" style is also supported.

Note: options are defined per-command (see `dbcli <command> --help`). The table below lists the most commonly available options across commands.

| Option | Short | Description |
|--------|-------|-------------|
| `--db-type` | `-t` | Database type |
| `--format` | `-f` | Output format (json/table/csv) |
| `--config` | - | Config file path |
| `--file` | `-F` | Read SQL from file (query/exec/ddl only) |

## Command Arguments & Options

This section lists the **complete CLI surface** for the built-in commands.

### `query` / `q`

- Arguments
  - `<sql>`: SQL to execute (SELECT/CTE/etc). You can also use `-F` to read from a file.
- Options
  - `-F, --file <path>`: Read SQL from file
  - `-p, --params <json>`: SQL parameters as JSON object (use `@Param` in SQL)
  - `-P, --params-file <path>`: Read JSON parameters from file
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `exec` / `e`

- Arguments
  - `<sql>`: SQL to execute (INSERT/UPDATE/DELETE). You can also use `-F`.
- Options
  - `-F, --file <path>`
  - `-p, --params <json>`: SQL parameters as JSON object (use `@Param` in SQL)
  - `-P, --params-file <path>`: Read JSON parameters from file
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `ddl`

- Arguments
  - `<sql>`: SQL to execute (CREATE/ALTER/DROP). You can also use `-F`.
- Options
  - `-F, --file <path>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `procedure` / `proc` / `sproc`

- Arguments
  - `<name>`: Stored procedure name
- Options
  - `-p, --params <json>`: Parameters as JSON object (use `@Param`)
  - `-P, --params-file <path>`: Read JSON parameters from file
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `procedure-query` / `proc-query` / `sproc-query`

- Arguments
  - `<name>`: Stored procedure name
- Options
  - `-p, --params <json>`: Parameters as JSON object (use `@Param`)
  - `-P, --params-file <path>`: Read JSON parameters from file
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `tables` / `ls`

- Options
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `views` / `view`

- Options
  - `-n, --name <pattern>`: filter by view name (LIKE %pattern%)
  - `--owner <schema>`: filter by schema/owner
  - `--scope <user|all|dba>`: listing scope (default: user)
  - `--with-definition`: include view definition text
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `columns` / `cols`

- Arguments
  - `<table>`: table name
- Options
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `export`

- Arguments
  - `<table>`: table name
- Options
  - `-t, --db-type <string>`
  - `--config <path>`

### `backup`

- Arguments
  - `<table>`: source table name
- Options
  - `-o, --target <name>`: backup table name (default: auto timestamp)
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `restore`

- Arguments
  - `<table>`: target table name to restore
- Options
  - `-s, --from <name>`: backup table name (required)
  - `-k, --keep-data`: keep existing data (append restore)
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `export-schema` / `schema`

- Arguments
  - `<type>`: `all`, `procedure`, `function`, `trigger`, `view`, `index`
- Options
  - `-n, --name <pattern>`: filter by object name
  - `-o, --output <path>`: save to file
  - `-t, --db-type <string>`
  - `--config <path>`

### `interactive` / `i`

- Options
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

## Parameterized SQL Notes (SqlSugar ADO)

- Use `@Param` placeholders for cross-database parameterization.
- `IN (...)` supports JSON arrays (DbCli expands `@Ids`).
- SQLite providers may require `DisableClearParameters: true` in config (maps to SqlSugar `IsClearParameters=false`).
- SQL Server supports `GO` batch separators for `ddl` and non-parameterized `exec` (use `-F` for scripts). `GO` is not supported with `-p/-P`.
- DbCli returns a single result set. SqlSugar supports multiple result sets/output parameters, but DbCli does not surface them yet. Use explicit `SELECT` in procedures when you need to return data.

Examples:

```bash
# IN (...) with array
dbcli query "SELECT * FROM Users WHERE Id IN (@Ids)" -p '{"Ids":[1,2,3]}'

# SQL Server GO batches (non-parameter)
dbcli -t sqlserver exec -F script_with_go.sql
```

## Usage Examples

### Basic Operations
```bash
# Set connection once
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"

# Create table
dbcli ddl "CREATE TABLE Users (Id INTEGER PRIMARY KEY, Name TEXT, Email TEXT)"

# Insert data
dbcli exec "INSERT INTO Users (Name, Email) VALUES ('John', 'john@example.com')"

# Query data
dbcli query "SELECT * FROM Users" -f table

# List tables
dbcli tables

# Show table structure
dbcli -f table columns Users

# List views (different database)
export DBCLI_CONNECTION="Server=localhost;Database=mydb;User Id=SYSDBA;Password=xxxxxxxxxx"
export DBCLI_DBTYPE="dm"
dbcli views --scope all --owner DOC -f table

# Export data (back to SQLite)
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"
dbcli export Users > backup.sql
```

### Execute SQL from File
```bash
# Set connection
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"

# Execute DDL script
dbcli ddl -F schema.sql

# Execute data script
dbcli exec -F seed.sql
```

### Different Databases
```bash
# SQLite
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"
dbcli query "SELECT * FROM Users"

# Microsoft SQL Server
export DBCLI_CONNECTION="Server=localhost;Database=mydb;Trusted_Connection=True"
export DBCLI_DBTYPE="sqlserver"
dbcli query "SELECT TOP 10 * FROM Users"

# MySQL
export DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx"
export DBCLI_DBTYPE="mysql"
dbcli query "SELECT * FROM Users LIMIT 10"

# PostgreSQL
export DBCLI_CONNECTION="Host=localhost;Database=mydb;Username=postgres;Password=xxxxxxxxxx"
export DBCLI_DBTYPE="postgresql"
dbcli query "SELECT * FROM Users LIMIT 10"
```

## Connection String Reference

### Relational Databases

#### SQLite
```
Data Source=app.db
```

#### Microsoft SQL Server

```
Server=.;Database=mydb;Trusted_Connection=True;
```
Or with username/password:
```
Server=localhost;Database=mydb;User Id=sa;Password=xxxxxxxxxx;
```

#### MySQL
```
Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;AllowLoadLocalInfile=true;
```

#### MySQL Connector
```
Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;
```

#### PostgreSQL
```
Host=localhost;Port=5432;Database=mydb;Username=postgres;Password=xxxxxxxxxx;
```

#### Oracle
```
Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)));User Id=system;Password=xxxxxxxxxx;
```
Or simplified:
```
Data Source=localhost:1521/orcl;User Id=system;Password=xxxxxxxxxx;
```

#### MariaDB
```
Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;
```

#### TiDB
```
Server=localhost;Port=4000;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;
```

#### DaMeng
```
Server=localhost;User Id=SYSDBA;PWD=xxxxxxxxxx;DATABASE=mydb;
```

#### KingbaseES
```
Server=localhost;Port=54321;UID=system;PWD=xxxxxxxxxx;database=mydb;
```

#### Oscar
```
Data Source=localhost;User Id=SYSDBA;Password=xxxxxxxxxx;Database=mydb;
```

#### HighGo
```
Host=localhost;Port=5866;Database=mydb;Username=highgo;Password=xxxxxxxxxx;
```

#### GaussDB
```
Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=xxxxxxxxxx;
```

#### GBase
```
Server=localhost;Port=9088;Database=mydb;Uid=gbasedbt;Pwd=xxxxxxxxxx;
```

### Distributed Databases

#### OceanBase
```
Server=localhost;Port=2883;Database=mydb;User Id=root;Password=xxxxxxxxxx;
```

#### PolarDB
```
Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;Pooling=false;
```

#### TDengine
```
Host=localhost;Port=6030;Database=mydb;Username=root;Password=xxxxxxxxxx;
```

#### ClickHouse
```
Host=localhost;Port=8123;Database=default;User=default;Password=xxxxxxxxxx;Compress=True;
```

#### Doris
```
Server=localhost;Port=9030;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;Pooling=false;
```

### Analytics Databases

#### QuestDB
```
host=localhost;port=8812;username=admin;password=xxxxxxxxxx;database=qdb;ServerCompatibilityMode=NoTypeLoading;
```

#### DuckDB
```
Data Source=analytics.db
```

### Enterprise Databases

#### IBM DB2
```
Server=localhost:50000;Database=mydb;UID=db2admin;PWD=xxxxxxxxxx;
```

#### SAP HANA
```
Server=localhost:30015;UserName=SYSTEM;Password=xxxxxxxxxx;Database=HDB;
```

#### Microsoft Access
```
Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\mydb.accdb;
```

### NoSQL Databases

#### MongoDB
```
mongodb://localhost:27017/mydb
```
Or with authentication:
```
mongodb://user:xxxxxxxxxx@localhost:27017/mydb?authSource=admin
```

### Cloud Provider Databases

#### Amazon Aurora (MySQL)
```
Server=mydb.cluster-xxx.us-east-1.rds.amazonaws.com;Database=mydb;Uid=admin;Pwd=xxxxxxxxxx;
```

#### Azure Database for MySQL
```
Server=mydb.mysql.database.azure.com;Database=mydb;Uid=admin@mydb;Pwd=xxxxxxxxxx;SslMode=Required;
```

#### Google Cloud SQL for MySQL
```
Server=1.2.3.4;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;SslMode=Required;
```

#### Percona Server
```
Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;
```

### Generic Connectors

#### ODBC
```
Driver={SQL Server};Server=localhost;Database=mydb;Uid=sa;Pwd=xxxxxxxxxx;
```

#### Custom
```
Custom connection string based on your driver
```

## Config File Examples

### appsettings.json (SQLite)
```json
{
  "ConnectionString": "Data Source=app.db",
  "DbType": "sqlite",
  "DisableClearParameters": true
}
```
Use `DisableClearParameters` if parameterized queries fail on some SQLite providers.

### appsettings.json (Microsoft SQL Server)

```json
{
  "ConnectionString": "Server=.;Database=MyApp;Trusted_Connection=True;",
  "DbType": "sqlserver"
}
```

### appsettings.json (MySQL)
```json
{
  "ConnectionString": "Server=localhost;Database=myapp;Uid=root;Pwd=xxxxxxxxxx;",
  "DbType": "mysql"
}
```

### appsettings.json (PostgreSQL)
```json
{
  "ConnectionString": "Host=localhost;Port=5432;Database=myapp;Username=postgres;Password=xxxxxxxxxx;",
  "DbType": "postgresql"
}
```

## Interactive Mode

```bash
# Set connection via environment variables
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"
dbcli interactive

# Interactive commands:
# .tables                   - List all tables
# .views                    - List views
# .columns <table>          - Show table structure
# .format <type>            - Switch output format
# .help                     - Show help
# .query <sql>              - Execute SQL as query and show results
# .exec <sql>               - Execute SQL as non-query
# .ddl <sql>                - Execute DDL (CREATE/ALTER/DROP)
# .export <table> [output]  - Export table data as INSERT SQL
# .export-schema <type>     - Export schema objects
#   Options: -n <pattern> -o <file> --output-dir <dir>
# .exit/.quit               - Exit
# End SQL with ';' or blank line to execute
```

## Using in CI/CD

### 🔒 Secure Connection Setup (Recommended)

**For AI integration and production use, avoid `-c` parameter to prevent passwords in logs:**

```yaml
# GitHub Actions
- name: Run migrations securely
  env:
    DBCLI_CONNECTION: ${{ secrets.DB_CONNECTION }}
    DBCLI_DBTYPE: sqlserver
  run: |
    ./dbcli ddl -F migrations/001_init.sql
```

```powershell
# PowerShell Script
$env:DBCLI_CONNECTION = "Data Source=app.db"
$env:DBCLI_DBTYPE = "sqlite"
$result = dbcli query "SELECT COUNT(*) as Count FROM Users" | ConvertFrom-Json
Write-Host "User count: $($result[0].Count)"
```

```bash
# Bash Script
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE=sqlite
count=$(dbcli query "SELECT COUNT(*) as Count FROM Users" | jq '.[0].Count')
echo "User count: $count"
```

**Why avoid `-c` parameter:**
- ✅ Environment variables not visible in command line or logs
- ✅ Prevents passwords from appearing in AI conversation history
- ✅ Better security for CI/CD and production environments

### Traditional Mode (Connection string in command)

```yaml
# Secure - connection string from secret
- name: Run migrations
  run: |
    export DBCLI_CONNECTION="${{ secrets.DB_CONNECTION }}"
    export DBCLI_DBTYPE="${{ secrets.DB_TYPE }}"
    ./dbcli ddl -F migrations/001_init.sql
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | This file - Project overview and quick reference |
| [skills/README.md](skills/README.md) | Skills overview and usage guide |
| [skills/INTEGRATION.md](skills/INTEGRATION.md) | AI assistant integration for 10+ coding agents |
| [skills/CONNECTION_STRINGS.md](skills/CONNECTION_STRINGS.md) | Connection string examples for 30+ databases |

---

## 🔗 Resources

- **Agent Skills Specification**: https://agentskills.io
- **OpenAI Codex Skills**: https://developers.openai.com/codex/skills
- **Claude Skills**: https://support.claude.com/en/articles/12512180-using-skills-in-claude
- **SqlSugar**: https://github.com/DotNetNext/SqlSugar
- **ConsoleAppFramework (CLI Framework)**: https://github.com/Cysharp/ConsoleAppFramework
---

## License

MIT - See [LICENSE](LICENSE) for details

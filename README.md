# DbCli - Database CLI Tool for AI Agents

**Universal Database CLI with Agent Skills Specification support**

Cross-database command line tool based on .NET 10 and SqlSugar, designed for AI agent integration through Agent Skills format.

CLI routing is implemented with ConsoleAppFramework.

[Simplified Chinese](README_CN.md)

## Table of Contents

- [AI Agent Integration](#-ai-agent-integration)
- [Getting Started (Publish → Deploy)](#getting-started-publish--deploy)
- [Supported Databases](#supported-databases)
- [Features](#features)
- [Backup & Restore](#️-backup--restore)
- [Installation for Development](#installation-for-development)
- [Command Reference](#command-reference)
- [Global Options](#global-options)
- [Command Arguments & Options](#command-arguments--options)
- [Usage Examples](#usage-examples)
- [Connection String Reference (SqlSugar Official Format)](#connection-string-reference-sqlsugar-official-format)
- [Config File Examples](#config-file-examples)
- [Interactive Mode](#interactive-mode)
- [Using in CI/CD](#using-in-cicd)
- [Project Structure](#project-structure)
- [Documentation](#-documentation)
- [Resources](#-resources)
- [License](#license)

---

## 🤖 AI Agent Integration

DbCli follows the **[Agent Skills Specification](https://agentskills.io)** - a universal format for AI assistants to discover and use tools.

**Agent Skills** are standardized tool definitions that AI assistants can:
- ✅ **Discover automatically** - No manual configuration needed
- ✅ **Understand context** - Clear descriptions, examples, and error handling
- ✅ **Execute safely** - Built-in validation and backup recommendations
- ✅ **Share across platforms** - Works with Claude Code, GitHub Copilot, OpenAI Codex, Cursor, Windsurf, and more

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
Works seamlessly with SQLite, PostgreSQL, MySQL, Oracle, SQL Server,
Chinese domestic databases (DaMeng, KingbaseES), and more
```

### 🚀 Quick Setup

**For AI Assistant Users:**
```bash
# 1. Deploy (also installs dbcli when -InstallExe is used)
pwsh .\deploy-skills.ps1 -InstallExe -AddToPath -Target all -Force

# 2. Start using
Ask your AI: "Query my database for all active users"
```

**Deployment targets:** `claude`, `copilot`, `codex`, `workspace`, `all`  
**Common options:** PowerShell `-Force`, `-GlobalClaudeDir`; Python `--force`, `--claude-dir`  
**Verify:** `dbcli --version` and check your deployed files (`.github/copilot-instructions.md`, `skills/dbcli/`, `.claude/skills/dbcli/` (repo) or `~/.claude/skills/dbcli/` (global)).

---

## Getting Started (Publish → Deploy)

This is the simplest end-to-end workflow when you build DbCli from source and then deploy the skills to an AI assistant.

### 1) Publish

```powershell
# Build self-contained single-file binaries + dist-* folders (recommended)
pwsh .\publish-all.ps1
```

Or publish only your current platform:

```powershell
dotnet publish .\dbcli.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o .\dist-win-x64
```

### 2) Install + Deploy skills

```powershell
pwsh .\deploy-skills.ps1 -InstallExe -AddToPath -Target copilot -Force
```

### 3) Verify

```powershell
dbcli --help
dbcli -c "Data Source=test.db" query "SELECT 'Hello' AS message"
```

## Supported Databases

Supports 30+ databases including:
- **Relational Databases**: SQLite, SQL Server, MySQL, PostgreSQL, Oracle, IBM DB2, Microsoft Access
- **Chinese Domestic Databases**: DaMeng (Dm), KingbaseES (Kdbndp), Oscar, HighGo (HG), GaussDB, GBase
- **Distributed Databases**: OceanBase, TDengine, ClickHouse, TiDB
- **Analytics Databases**: QuestDB, DuckDB
- **Enterprise Databases**: SAP HANA
- **NoSQL Databases**: MongoDB
- **MySQL Ecosystem** (use `-t mysql`): MySqlConnector, MariaDB, Percona Server, Amazon Aurora, Azure Database for MySQL, Google Cloud SQL for MySQL
- **Generic Connectors**: ODBC, Custom database

## Features

- Supports 30+ databases (see list above)
- Multiple output formats: JSON, Table, CSV
- Interactive SQL mode
- Configurable connection strings (command line, config file, environment variables)
- Single-file deployment
- Claude Code Skills support

## ⚠️ Backup & Restore

**CRITICAL**: Always create backups before performing DDL (DROP, ALTER) or DML (UPDATE, DELETE) operations!

DbCli provides built-in `backup`, `restore`, and `export-schema` commands for comprehensive backup strategies:

### Schema Backup (Procedures, Functions, Triggers, Views, Indexes)

**Export DDL scripts** before dropping or modifying database objects:

```bash
# Export all schema objects
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema all -o backup_schema.sql

# Export all schema objects as separate files (per object)
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema all --output-dir ./schema_export

# Export only stored procedures
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema procedure -o backup_procedures.sql

# Export specific procedure by name pattern
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema procedure --name "sp_User*"

# Export indexes for all tables
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema index -o backup_indexes.sql

# Export triggers
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema trigger -o backup_triggers.sql
```

**Supported object types**: `all`, `procedure`, `function`, `trigger`, `view`, `index`

**Supported databases**: SQL Server, MySQL, PostgreSQL, SQLite (coverage varies by database)

### Data Backup Commands

DbCli provides `backup` and `restore` commands powered by SqlSugar Fastest() API with intelligent backup strategies:

### Backup Command

```bash
# Auto backup (auto-generated timestamp table name)
dbcli -c "Data Source=mydb.db" backup Users
# Creates: Users_backup_20251227_161149

# Specify custom backup table name
dbcli -c "Data Source=mydb.db" backup Users -o Users_backup_before_migration

# Table format output for details
dbcli -c "Data Source=mydb.db" -f table backup Users
```

### Restore Command

```bash
# Restore from backup (auto-deletes existing data)
dbcli -c "Data Source=mydb.db" restore Users --from Users_backup_20251227_161149

# Keep existing data, append restore
dbcli -c "Data Source=mydb.db" restore Users --from Users_backup_20251227_161149 --keep-data

# Table format output for details
dbcli -c "Data Source=mydb.db" -f table restore Users --from Users_backup_20251227_161149
```

### Intelligent Backup Strategy (Auto-selects fastest method)

| Priority | Method | Use Case | Performance |
|----------|--------|----------|-------------|
| 1 | `CREATE TABLE AS SELECT` | SQLite, MySQL, PostgreSQL | Fastest & compatible |
| 2 | `Fastest().BulkCopy` (DataTable) | Large data (>10k rows) | Extremely fast for big tables |
| 3 | Row-by-row INSERT | Compatibility mode | Slowest but guaranteed |

### Traditional Backup Methods (Still supported)

```bash
# SQL export (portable to other databases)
dbcli -c "Data Source=mydb.db" export Users > Users_backup_${TIMESTAMP}.sql

# Full database backup (SQLite file copy)
cp mydb.db mydb_backup_${TIMESTAMP}.db
```

### Complete Backup & Restore Workflow

```bash
# 1. Backup table
dbcli -c "Data Source=app.db" -f table backup Users
# ✅ Method: CreateTableAsSelect, Rows: 1000

# 2. Execute dangerous operation
dbcli -c "Data Source=app.db" exec "DELETE FROM Users WHERE Age < 18"

# 3. Found mistake, restore immediately
dbcli -c "Data Source=app.db" -f table restore Users --from Users_backup_20251227_161149
# ✅ Method: InsertIntoSelect, Rows: 1000, Deleted: True
```

See [dbcli-export skill](skills/dbcli-export/SKILL.md) for complete backup automation scripts.

## Installation for Development

### Option 1: Add to System PATH

1. Publish the project:
```bash
cd <project-directory>
dotnet publish -c Release -r win-x64
```

2. Add publish directory to PATH:
```powershell
# PowerShell (Administrator)
$publishPath = "<project-directory>\bin\Release\net10.0\win-x64\publish"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$publishPath", "User")
```

3. Verify after restarting terminal:
```bash
dbcli --help
```

### Option 2: Copy to Project Directory

Copy published files to project `tools` directory:
```bash
mkdir tools
cp bin/Release/net10.0/win-x64/publish/dbcli.exe tools/
cp bin/Release/net10.0/win-x64/publish/e_sqlite3.dll tools/
cp bin/Release/net10.0/win-x64/publish/Microsoft.Data.SqlClient.SNI.dll tools/
```

### Option 3: Configure Environment Variables

Set default database connection to avoid repeated input:
```powershell
# PowerShell
$env:DBCLI_CONNECTION = "Data Source=myproject.db"
$env:DBCLI_DBTYPE = "sqlite"

# Or set permanently
[Environment]::SetEnvironmentVariable("DBCLI_CONNECTION", "Data Source=myproject.db", "User")
[Environment]::SetEnvironmentVariable("DBCLI_DBTYPE", "sqlite", "User")
```

```bash
# Bash
export DBCLI_CONNECTION="Data Source=myproject.db"
export DBCLI_DBTYPE="sqlite"
```

### Option 4: Use Config File

Create `appsettings.json` in project root:
```json
{
  "ConnectionString": "Data Source=myproject.db",
  "DbType": "sqlite"
}
```

Usage:
```bash
dbcli --config appsettings.json query "SELECT * FROM Users"
```

## Command Reference

| Command | Alias | Description |
|---------|-------|-------------|
| `query <sql>` | `q` | Execute SELECT query |
| `exec <sql>` | `e` | Execute INSERT/UPDATE/DELETE |
| `ddl <sql>` | - | Execute CREATE/ALTER/DROP |
| `tables` | `ls` | List all tables |
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
| `--connection` | `-c` | Database connection string |
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
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `exec` / `e`

- Arguments
  - `<sql>`: SQL to execute (INSERT/UPDATE/DELETE). You can also use `-F`.
- Options
  - `-F, --file <path>`
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `ddl`

- Arguments
  - `<sql>`: SQL to execute (CREATE/ALTER/DROP). You can also use `-F`.
- Options
  - `-F, --file <path>`
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `tables` / `ls`

- Options
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `columns` / `cols`

- Arguments
  - `<table>`: table name
- Options
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `export`

- Arguments
  - `<table>`: table name
- Options
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `--config <path>`

### `backup`

- Arguments
  - `<table>`: source table name
- Options
  - `-o, --target <name>`: backup table name (default: auto timestamp)
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `restore`

- Arguments
  - `<table>`: target table name to restore
- Options
  - `-s, --from <name>`: backup table name (required)
  - `-k, --keep-data`: keep existing data (append restore)
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `export-schema` / `schema`

- Arguments
  - `<type>`: `all`, `procedure`, `function`, `trigger`, `view`, `index`
- Options
  - `-n, --name <pattern>`: filter by object name
  - `-o, --output <path>`: save to file
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `--config <path>`

### `interactive` / `i`

- Options
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

## Usage Examples

### Basic Operations
```bash
# Create table
dbcli -c "Data Source=app.db" ddl "CREATE TABLE Users (Id INTEGER PRIMARY KEY, Name TEXT, Email TEXT)"

# Insert data
dbcli -c "Data Source=app.db" exec "INSERT INTO Users (Name, Email) VALUES ('John', 'john@example.com')"

# Query data
dbcli -c "Data Source=app.db" query "SELECT * FROM Users" -f table

# List tables
dbcli -c "Data Source=app.db" tables

# Show table structure
dbcli -c "Data Source=app.db" -f table columns Users

# Export data
dbcli -c "Data Source=app.db" export Users > backup.sql
```

### Execute SQL from File
```bash
# Execute DDL script
dbcli ddl -F schema.sql -c "Data Source=app.db"

# Execute data script
dbcli exec -F seed.sql -c "Data Source=app.db"
```

### Different Databases
```bash
# SQLite
dbcli -c "Data Source=app.db" query "SELECT * FROM Users" -t sqlite

# SQL Server
dbcli -c "Server=localhost;Database=mydb;Trusted_Connection=True" query "SELECT TOP 10 * FROM Users" -t sqlserver

# MySQL
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass" query "SELECT * FROM Users LIMIT 10" -t mysql

# PostgreSQL
dbcli -c "Host=localhost;Database=mydb;Username=postgres;Password=pass" query "SELECT * FROM Users LIMIT 10" -t postgresql
```

## Connection String Reference (SqlSugar Official Format)

### Relational Databases

#### SQLite
```
Data Source=app.db
```

#### SQL Server
```
Server=.;Database=mydb;Trusted_Connection=True;
```
Or with username/password:
```
Server=localhost;Database=mydb;User Id=sa;Password=Pass123;
```

#### MySQL
```
Server=localhost;Database=mydb;Uid=root;Pwd=pass123;AllowLoadLocalInfile=true;
```

#### MySQL Connector
```
Server=localhost;Database=mydb;Uid=root;Pwd=pass123;
```

#### PostgreSQL
```
Host=localhost;Port=5432;Database=mydb;Username=postgres;Password=pass123;
```

#### Oracle
```
Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)));User Id=system;Password=oracle;
```
Or simplified:
```
Data Source=localhost:1521/orcl;User Id=system;Password=oracle;
```

#### MariaDB
```
Server=localhost;Database=mydb;Uid=root;Pwd=pass123;
```

#### TiDB
```
Server=localhost;Port=4000;Database=mydb;Uid=root;Pwd=pass123;
```

### Chinese Domestic Databases

#### DaMeng
```
Server=localhost;User Id=SYSDBA;PWD=SYSDBA;DATABASE=mydb;
```

#### KingbaseES
```
Server=localhost;Port=54321;UID=system;PWD=system;database=mydb;
```

#### Oscar
```
Data Source=localhost;User Id=SYSDBA;Password=pass;Database=mydb;
```

#### HighGo
```
Host=localhost;Port=5866;Database=mydb;Username=highgo;Password=pass;
```

#### Huawei GaussDB
```
Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=pass;
```

#### GBase
```
Server=localhost;Port=9088;Database=mydb;Uid=gbasedbt;Pwd=pass;
```

### Distributed Databases

#### OceanBase
```
Server=localhost;Port=2883;Database=mydb;User Id=root;Password=pass;
```

#### TDengine
```
Host=localhost;Port=6030;Database=mydb;Username=root;Password=taosdata;
```

#### ClickHouse
```
Host=localhost;Port=8123;Database=default;User=default;Password=;Compress=True;
```

### Analytics Databases

#### QuestDB
```
host=localhost;port=8812;username=admin;password=quest;database=qdb;ServerCompatibilityMode=NoTypeLoading;
```

#### DuckDB
```
Data Source=analytics.db
```

### Enterprise Databases

#### IBM DB2
```
Server=localhost:50000;Database=mydb;UID=db2admin;PWD=pass;
```

#### SAP HANA
```
Server=localhost:30015;UserName=SYSTEM;Password=pass;Database=HDB;
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
mongodb://user:pass@localhost:27017/mydb?authSource=admin
```

### Cloud Provider Databases

#### Amazon Aurora (MySQL)
```
Server=mydb.cluster-xxx.us-east-1.rds.amazonaws.com;Database=mydb;Uid=admin;Pwd=pass;
```

#### Azure Database for MySQL
```
Server=mydb.mysql.database.azure.com;Database=mydb;Uid=admin@mydb;Pwd=pass;SslMode=Required;
```

#### Google Cloud SQL for MySQL
```
Server=1.2.3.4;Database=mydb;Uid=root;Pwd=pass;SslMode=Required;
```

#### Percona Server
```
Server=localhost;Database=mydb;Uid=root;Pwd=pass;
```

### Generic Connectors

#### ODBC
```
Driver={SQL Server};Server=localhost;Database=mydb;Uid=sa;Pwd=pass;
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
  "DbType": "sqlite"
}
```

### appsettings.json (SQL Server)
```json
{
  "ConnectionString": "Server=.;Database=MyApp;Trusted_Connection=True;",
  "DbType": "sqlserver"
}
```

### appsettings.json (MySQL)
```json
{
  "ConnectionString": "Server=localhost;Database=myapp;Uid=root;Pwd=123456;",
  "DbType": "mysql"
}
```

### appsettings.json (PostgreSQL)
```json
{
  "ConnectionString": "Host=localhost;Port=5432;Database=myapp;Username=postgres;Password=123456;",
  "DbType": "postgresql"
}
```

## Interactive Mode
```bash
dbcli interactive -c "Data Source=app.db"

# Interactive commands:
# .tables          - List all tables
# .columns <table> - Show table structure
# .format <type>   - Switch output format
# exit/quit        - Exit
```

## Using in CI/CD

### GitHub Actions
```yaml
- name: Setup DbCli
  run: |
    dotnet tool restore
    # Or use published executable

- name: Run migrations
  run: |
    ./dbcli ddl -F migrations/001_init.sql -c "${{ secrets.DB_CONNECTION }}"
```

### PowerShell Script
```powershell
$result = & dbcli -c "Data Source=app.db" query "SELECT COUNT(*) as Count FROM Users" | ConvertFrom-Json
Write-Host "User count: $($result[0].Count)"
```

### Bash Script
```bash
count=$(dbcli -c "Data Source=app.db" query "SELECT COUNT(*) as Count FROM Users" | jq '.[0].Count')
echo "User count: $count"
```

## Project Structure

```
dbcli/
├── Program.cs            # Command definitions
├── DbContext.cs          # Database context
├── OutputFormatter.cs    # Output formatting
├── dbcli.csproj          # Project file
├── appsettings.json      # Default config
├── README.md             # This file
├── deploy-skills.ps1     # Deployment script (PowerShell)
├── deploy-skills.py      # Deployment script (Python)
├── test.ps1              # PowerShell tests
├── test.sh               # Bash tests
├── skills/               # Agent Skills (Universal Format)
│   ├── dbcli-query/      # Query skill (SELECT)
│   ├── dbcli-exec/       # Execute skill (INSERT/UPDATE/DELETE)
│   ├── dbcli-db-ddl/  # DDL skill (CREATE/ALTER/DROP)
│   ├── dbcli-tables/     # List tables skill
│   ├── dbcli-view/       # View management skill
│   ├── dbcli-index/      # Index management skill
│   ├── dbcli-procedure/  # Stored procedure skill
│   ├── dbcli-export/     # Export/backup skill
│   ├── dbcli-interactive/# Interactive mode skill
│   ├── README.md         # Skills overview
│   ├── INTEGRATION.md    # AI assistant integration guide
│   └── CONNECTION_STRINGS.md  # Database connection examples
├── dist/                 # Windows distribution package
└── dist-linux/           # Linux distribution package
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | This file - Project overview and quick reference |
| [skills/README.md](skills/README.md) | Skills overview and usage guide |
| [skills/INTEGRATION.md](skills/INTEGRATION.md) | AI assistant integration for 10+ platforms |
| [skills/CONNECTION_STRINGS.md](skills/CONNECTION_STRINGS.md) | Connection string examples for 30+ databases |

---

## 🔗 Resources

- **Agent Skills Specification**: https://agentskills.io
- **SqlSugar**: https://github.com/DotNetNext/SqlSugar
- **ConsoleAppFramework (CLI Framework)**: https://github.com/Cysharp/ConsoleAppFramework

---

## License

MIT


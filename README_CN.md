# DbCli - 面向 AI Agent 的数据库 CLI 工具

**支持 Agent Skills Specification 的通用数据库 CLI**

基于 .NET 10 与 SqlSugar 的跨数据库命令行工具，面向 AI Agent 集成（Agent Skills 格式）。

CLI 路由由 ConsoleAppFramework 实现。

[English](README.md)

## 目录

- [AI Agent 集成](#-ai-agent-集成)
- [快速上手（Publish → Deploy）](#快速上手publish--deploy)
- [支持的数据库](#支持的数据库)
- [功能特性](#功能特性)
- [备份与恢复](#️-备份与恢复)
- [开发环境安装](#开发环境安装)
- [命令参考](#命令参考)
- [全局选项](#全局选项)
- [命令参数与选项](#命令参数与选项)
- [使用示例](#使用示例)
- [连接字符串参考（SqlSugar 官方格式）](#连接字符串参考sqlsugar-官方格式)
- [配置文件示例](#配置文件示例)
- [交互模式](#交互模式)
- [在 CI/CD 中使用](#在-cicd-中使用)
- [项目结构](#项目结构)
- [文档](#-文档)
- [资源](#-资源)
- [License](#license)

---

## 🤖 AI Agent 集成

DbCli 遵循 **[Agent Skills Specification](https://agentskills.io)** —— 一种让 AI 助手发现与调用工具的通用格式。

**Agent Skills** 是标准化的工具定义，AI 助手可以：
- ✅ **自动发现** - 无需手动配置
- ✅ **理解上下文** - 清晰的描述、示例与错误处理
- ✅ **安全执行** - 内置校验与备份建议
- ✅ **跨平台共享** - 支持 Claude Code、GitHub Copilot、OpenAI Codex、Cursor、Windsurf 等

### 🎯 使用场景

**1. 数据分析与报表**
```
AI Assistant → dbcli-query skill → Database
"Show me top 10 customers by revenue this month"
→ Generates: SELECT query with proper aggregation and filtering
```

**2. 数据库管理**
```
AI Assistant → dbcli-db-ddl skill → Database
"Create a users table with email validation"
→ Generates: CREATE TABLE with appropriate constraints
```

**3. 自动化备份**
```
AI Assistant → dbcli-export skill → SQL Files
"Export all critical tables before deployment"
→ Generates: Backup scripts with timestamps
```

**4. 跨数据库操作**
```
Your App → AI Assistant → DbCli Skills → 30+ Databases
Works seamlessly with SQLite, PostgreSQL, MySQL, Oracle, SQL Server,
Chinese domestic databases (DaMeng, KingbaseES), and more
```

### 🚀 快速开始

**AI 助手用户：**
```bash
# 1. 一键部署（带 -InstallExe 时会同时安装 dbcli）
pwsh .\deploy-skills.ps1 -InstallExe -AddToPath -Target all -Force

# 2. 开始使用
Ask your AI: "Query my database for all active users"
```

**部署目标：** `claude`、`copilot`、`codex`、`workspace`、`all`  
**常用参数：** PowerShell `-Force`、`-GlobalClaudeDir`；Python `--force`、`--claude-dir`  
**验证：** `dbcli --version`，并检查已部署的文件（`.github/copilot-instructions.md`、`skills/dbcli/`、仓库 `.claude/skills/dbcli/` 或全局 `~/.claude/skills/dbcli/`）。

---

## 快速上手（Publish → Deploy）

如果你是从源码构建 DbCli，并希望把 skills 部署到 AI 助手环境，推荐按下面三步走。

### 1）发布（Publish）

```powershell
# 构建多平台单文件产物，并生成 dist-* 目录（推荐）
pwsh .\publish-all.ps1
```

或仅发布当前平台：

```powershell
dotnet publish .\dbcli.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -o .\dist-win-x64
```

### 2）安装并部署 skills

```powershell
pwsh .\deploy-skills.ps1 -InstallExe -AddToPath -Target copilot -Force
```

### 3）验证

```powershell
dbcli --help
dbcli -c "Data Source=test.db" query "SELECT 'Hello' AS message"
```

## 支持的数据库

支持 30+ 种数据库，包括：
- **关系型数据库**：SQLite、SQL Server、MySQL、PostgreSQL、Oracle、IBM DB2、Microsoft Access
- **国产数据库**：DaMeng（达梦）、KingbaseES（人大金仓/Kdbndp）、Oscar（神通）、HighGo（瀚高/HG）、GaussDB（华为）、GBase（南大通用）
- **分布式数据库**：OceanBase、TDengine、ClickHouse、TiDB
- **分析型数据库**：QuestDB、DuckDB
- **企业级数据库**：SAP HANA
- **NoSQL 数据库**：MongoDB
- **MySQL 生态**（使用 `-t mysql`）：MySqlConnector、MariaDB、Percona Server、Amazon Aurora、Azure Database for MySQL、Google Cloud SQL for MySQL
- **通用连接器**：ODBC、Custom database

## 功能特性

- 支持 30+ 种数据库（见上方列表）
- 多种输出格式：JSON、Table、CSV
- 交互式 SQL 模式
- 可配置连接字符串（命令行参数、配置文件、环境变量）
- 单文件发布
- 支持 Claude Code Skills

## ⚠️ 备份与恢复

**关键提示**：执行任何 DDL（DROP、ALTER）或 DML（UPDATE、DELETE）操作前，请务必先备份！

DbCli 提供内置的 `backup`、`restore` 与 `export-schema` 命令，用于完整的备份策略。

### 架构备份（存储过程、函数、触发器、视图、索引）

在删除或修改数据库对象之前，先 **导出 DDL 脚本**：

```bash
# Export all schema objects
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema all -o backup_schema.sql

# 将全部架构对象按“每个对象一个文件”导出到目录
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

**支持的对象类型**：`all`、`procedure`、`function`、`trigger`、`view`、`index`

**支持的数据库**：SQL Server、MySQL、PostgreSQL、SQLite（覆盖范围因数据库而异）

### 数据备份命令

DbCli 的 `backup` 与 `restore` 命令基于 SqlSugar 的 Fastest() API，实现智能备份策略。

### 备份命令

```bash
# Auto backup (auto-generated timestamp table name)
dbcli -c "Data Source=mydb.db" backup Users
# Creates: Users_backup_20251227_161149

# Specify custom backup table name
dbcli -c "Data Source=mydb.db" backup Users -o Users_backup_before_migration

# Table format output for details
dbcli -c "Data Source=mydb.db" -f table backup Users
```

### 恢复命令

```bash
# Restore from backup (auto-deletes existing data)
dbcli -c "Data Source=mydb.db" restore Users --from Users_backup_20251227_161149

# Keep existing data, append restore
dbcli -c "Data Source=mydb.db" restore Users --from Users_backup_20251227_161149 --keep-data

# Table format output for details
dbcli -c "Data Source=mydb.db" -f table restore Users --from Users_backup_20251227_161149
```

### 智能备份策略（自动选择最快方法）

| 优先级 | 方法 | 适用场景 | 性能 |
|----------|--------|----------|-------------|
| 1 | `CREATE TABLE AS SELECT` | SQLite, MySQL, PostgreSQL | 最快且兼容 |
| 2 | `Fastest().BulkCopy` (DataTable) | 大数据量 (>10k rows) | 大表极快 |
| 3 | 逐行 INSERT | 兼容模式 | 最慢但最稳 |

### 传统备份方法（仍支持）

```bash
# SQL export (portable to other databases)
dbcli -c "Data Source=mydb.db" export Users > Users_backup_${TIMESTAMP}.sql

# Full database backup (SQLite file copy)
cp mydb.db mydb_backup_${TIMESTAMP}.db
```

### 完整备份与恢复工作流

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

完整的备份自动化脚本请见 [dbcli-export skill](skills/dbcli-export/SKILL.md)。

## 开发环境安装

### 方式 1：添加到系统 PATH

1. 发布项目：
```bash
cd <project-directory>
dotnet publish -c Release -r win-x64
```

2. 将发布目录加入 PATH：
```powershell
# PowerShell (Administrator)
$publishPath = "<project-directory>\bin\Release\net10.0\win-x64\publish"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$publishPath", "User")
```

3. 重启终端后验证：
```bash
dbcli --help
```

### 方式 2：复制到项目目录

将发布文件复制到项目的 `tools` 目录：
```bash
mkdir tools
cp bin/Release/net10.0/win-x64/publish/dbcli.exe tools/
cp bin/Release/net10.0/win-x64/publish/e_sqlite3.dll tools/
cp bin/Release/net10.0/win-x64/publish/Microsoft.Data.SqlClient.SNI.dll tools/
```

### 方式 3：配置环境变量

设置默认连接，避免重复输入：
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

### 方式 4：使用配置文件

在项目根目录创建 `appsettings.json`：
```json
{
  "ConnectionString": "Data Source=myproject.db",
  "DbType": "sqlite"
}
```

用法：
```bash
dbcli --config appsettings.json query "SELECT * FROM Users"
```

## 命令参考

| 命令 | 别名 | 描述 |
|---------|-------|-------------|
| `query <sql>` | `q` | 执行 SELECT 查询 |
| `exec <sql>` | `e` | 执行 INSERT/UPDATE/DELETE |
| `ddl <sql>` | - | 执行 CREATE/ALTER/DROP |
| `tables` | `ls` | 列出所有表 |
| `columns <table>` | `cols` | 显示表结构 |
| `export <table>` | - | 导出表数据为 SQL |
| `backup <table>` | - | 备份表（自动选择最快方法） |
| `restore <table>` | - | 从备份恢复表 |
| `export-schema <type>` | `schema` | 导出架构对象（存储过程、函数、触发器、视图、索引） |
| `interactive` | `i` | 交互式模式 |

## 全局选项

选项可以放在命令前或命令后。推荐“命令在前”的写法，同时也兼容历史的“选项在命令前”的写法。

注意：选项是按命令定义的（以 `dbcli <命令> --help` 为准）。下表列出的是大多数命令都会用到的常见选项。

| 选项 | 简写 | 描述 |
|--------|-------|-------------|
| `--connection` | `-c` | 数据库连接字符串 |
| `--db-type` | `-t` | 数据库类型 |
| `--format` | `-f` | 输出格式（json/table/csv） |
| `--config` | - | 配置文件路径 |
| `--file` | `-F` | 从文件读取 SQL（仅 query/exec/ddl） |

## 命令参数与选项

本节列出内置命令的 **完整 CLI 参数**。

### `query` / `q`

- 参数
  - `<sql>`：要执行的 SQL（SELECT/CTE 等）。也可以用 `-F` 从文件读取。
- 选项
  - `-F, --file <path>`：从文件读取 SQL
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `exec` / `e`

- 参数
  - `<sql>`：要执行的 SQL（INSERT/UPDATE/DELETE）。也可以用 `-F`。
- 选项
  - `-F, --file <path>`
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `ddl`

- 参数
  - `<sql>`：要执行的 SQL（CREATE/ALTER/DROP）。也可以用 `-F`。
- 选项
  - `-F, --file <path>`
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `tables` / `ls`

- 选项
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `columns` / `cols`

- 参数
  - `<table>`：表名
- 选项
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `export`

- 参数
  - `<table>`：表名
- 选项
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `--config <path>`

### `backup`

- 参数
  - `<table>`：源表名
- 选项
  - `-o, --target <name>`：备份表名（默认自动带时间戳）
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `restore`

- 参数
  - `<table>`：目标表名
- 选项
  - `-s, --from <name>`：要从哪个备份表恢复（必填）
  - `-k, --keep-data`：保留目标表现有数据（追加恢复）
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

### `export-schema` / `schema`

- 参数
  - `<type>`：`all`、`procedure`、`function`、`trigger`、`view`、`index`
- 选项
  - `-n, --name <pattern>`：按名称过滤
  - `-o, --output <path>`：保存到文件
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `--config <path>`

### `interactive` / `i`

- 选项
  - `-c, --connection <string>`
  - `-t, --db-type <string>`
  - `-f, --format <json|table|csv>`
  - `--config <path>`

## 使用示例

### 基础操作
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

### 从文件执行 SQL
```bash
# Execute DDL script
dbcli ddl -F schema.sql -c "Data Source=app.db"

# Execute data script
dbcli exec -F seed.sql -c "Data Source=app.db"
```

### 不同数据库
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

## 连接字符串参考（SqlSugar 官方格式）

### 关系型数据库

#### SQLite
```
Data Source=app.db
```

#### SQL Server
```
Server=.;Database=mydb;Trusted_Connection=True;
```
或使用用户名密码：
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
或简写：
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

### 国产数据库

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

### 分布式数据库

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

### 分析型数据库

#### QuestDB
```
host=localhost;port=8812;username=admin;password=quest;database=qdb;ServerCompatibilityMode=NoTypeLoading;
```

#### DuckDB
```
Data Source=analytics.db
```

### 企业级数据库

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

### NoSQL 数据库

#### MongoDB
```
mongodb://localhost:27017/mydb
```
或带身份验证：
```
mongodb://user:pass@localhost:27017/mydb?authSource=admin
```

### 云服务商数据库

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

### 通用连接器

#### ODBC
```
Driver={SQL Server};Server=localhost;Database=mydb;Uid=sa;Pwd=pass;
```

#### Custom
```
Custom connection string based on your driver
```

## 配置文件示例

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

## 交互模式
```bash
dbcli interactive -c "Data Source=app.db"

# Interactive commands:
# .tables          - List all tables
# .columns <table> - Show table structure
# .format <type>   - Switch output format
# exit/quit        - Exit
```

## 在 CI/CD 中使用

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

### PowerShell 脚本
```powershell
$result = & dbcli -c "Data Source=app.db" query "SELECT COUNT(*) as Count FROM Users" | ConvertFrom-Json
Write-Host "User count: $($result[0].Count)"
```

### Bash 脚本
```bash
count=$(dbcli -c "Data Source=app.db" query "SELECT COUNT(*) as Count FROM Users" | jq '.[0].Count')
echo "User count: $count"
```

## 项目结构

```
dbcli/
├── Program.cs            # 命令定义
├── DbContext.cs          # 数据库上下文
├── OutputFormatter.cs    # 输出格式化
├── dbcli.csproj          # 项目文件
├── appsettings.json      # 默认配置
├── README.md             # 英文说明
├── deploy-skills.ps1     # 部署脚本（PowerShell）
├── deploy-skills.py      # 部署脚本（Python）
├── test.ps1              # PowerShell 测试
├── test.sh               # Bash 测试
├── skills/               # Agent Skills（通用格式）
│   ├── dbcli-query/      # 查询 skill（SELECT）
│   ├── dbcli-exec/       # 执行 skill（INSERT/UPDATE/DELETE）
│   ├── dbcli-db-ddl/  # DDL skill（CREATE/ALTER/DROP）
│   ├── dbcli-tables/     # 列表 tables skill
│   ├── dbcli-view/       # 视图管理 skill
│   ├── dbcli-index/      # 索引管理 skill
│   ├── dbcli-procedure/  # 存储过程 skill
│   ├── dbcli-export/     # 导出/备份 skill
│   ├── dbcli-interactive/# 交互模式 skill
│   ├── README.md         # Skills 总览
│   ├── INTEGRATION.md    # 10+ 平台 AI 集成指南
│   └── CONNECTION_STRINGS.md  # 30+ 数据库连接字符串示例
├── dist/                 # Windows 发行包
└── dist-linux/           # Linux 发行包
```

---

## 📚 文档

| 文档 | 说明 |
|----------|-------------|
| [README.md](README.md) | 英文说明 - 项目概览与快速参考 |
| [skills/README.md](skills/README.md) | Skills 总览与使用指南 |
| [skills/INTEGRATION.md](skills/INTEGRATION.md) | 10+ 平台 AI 集成指南 |
| [skills/CONNECTION_STRINGS.md](skills/CONNECTION_STRINGS.md) | 30+ 数据库连接字符串示例 |

---

## 🔗 资源

- **Agent Skills Specification**: https://agentskills.io
- **SqlSugar**: https://github.com/DotNetNext/SqlSugar
- **ConsoleAppFramework (CLI Framework)**: https://github.com/Cysharp/ConsoleAppFramework

---

## License

MIT

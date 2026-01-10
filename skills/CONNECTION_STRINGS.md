# Database Connection Strings Reference

Quick reference for connecting to 30+ supported databases using DbCli.

## 🔒 Secure Mode (Recommended for AI Integration)

Enable secure mode to prevent passwords from appearing in AI conversations:

```bash
# PowerShell
$env:DBCLI_SECURE_MODE = "true"
$env:DBCLI_CONNECTION = "Server=localhost;Database=mydb;User=sa;Password=secret"
$env:DBCLI_DBTYPE = "sqlserver"

# Bash/Zsh
export DBCLI_SECURE_MODE=true
export DBCLI_CONNECTION="Server=localhost;Database=mydb;User=sa;Password=secret"
export DBCLI_DBTYPE=sqlserver

# Now use dbcli without -c parameter
dbcli query "SELECT * FROM Users"
```

**When `DBCLI_SECURE_MODE` is enabled:**
- ✅ Environment variables work
- ✅ Config files work (auto-loads `appsettings.json` in current directory, or use `--config <path>`)
- ❌ `-c` parameter is blocked with error message

## Format

```bash
# Recommended (environment variables)
DBCLI_CONNECTION="CONNECTION_STRING" DBCLI_DBTYPE="DATABASE_TYPE" dbcli [command]

# Secure mode (requires env vars or config file)
export DBCLI_SECURE_MODE=true
dbcli [command]  # Uses DBCLI_CONNECTION and DBCLI_DBTYPE
```

## Relational Databases

### SQLite

```bash
# Local file
DBCLI_CONNECTION="Data Source=app.db" dbcli query "SELECT * FROM Users"

# Absolute path
DBCLI_CONNECTION="Data Source=C:\databases\myapp.db" dbcli query "SELECT * FROM Users"

# In-memory (temporary)
DBCLI_CONNECTION="Data Source=:memory:" dbcli query "SELECT 1"
```

### SQL Server

```bash
# Windows Authentication
DBCLI_CONNECTION="Server=.;Database=mydb;Trusted_Connection=True" DBCLI_DBTYPE="sqlserver" dbcli query "SELECT @@VERSION"

# SQL Authentication
DBCLI_CONNECTION="Server=localhost;Database=mydb;User Id=sa;Password=xxxxxxxxxx" DBCLI_DBTYPE="sqlserver" dbcli query "SELECT @@VERSION"

# Named instance
DBCLI_CONNECTION="Server=.\\SQLEXPRESS;Database=mydb;Trusted_Connection=True" DBCLI_DBTYPE="sqlserver" dbcli query "SELECT @@VERSION"

# Remote server
DBCLI_CONNECTION="Server=192.168.1.100;Database=mydb;User Id=sa;Password=xxxxxxxxxx" DBCLI_DBTYPE="sqlserver" dbcli query "SELECT @@VERSION"
```

### MySQL

```bash
# Standard connection
DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"

# With port
DBCLI_CONNECTION="Server=localhost;Port=3306;Database=mydb;Uid=root;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"

# With SSL
DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;SslMode=Required" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"

# UTF-8 charset
DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;CharSet=utf8mb4" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"
```

### MySQL Connector

```bash
# Alternative MySQL driver
DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="mysqlconnector" dbcli query "SELECT VERSION()"
```

### PostgreSQL

```bash
# Standard connection
DBCLI_CONNECTION="Host=localhost;Port=5432;Database=mydb;Username=postgres;Password=xxxxxxxxxx" DBCLI_DBTYPE="postgresql" dbcli query "SELECT version()"

# With SSL
DBCLI_CONNECTION="Host=localhost;Database=mydb;Username=postgres;Password=xxxxxxxxxx;SSL Mode=Require" DBCLI_DBTYPE="postgresql" dbcli query "SELECT version()"

# Unix socket (Linux)
DBCLI_CONNECTION="Host=/var/run/postgresql;Database=mydb;Username=postgres" DBCLI_DBTYPE="postgresql" dbcli query "SELECT version()"
```

### Oracle

```bash
# TNS Names
DBCLI_CONNECTION="Data Source=ORCL;User Id=system;Password=xxxxxxxxxx" DBCLI_DBTYPE="oracle" dbcli query "SELECT * FROM v\$version"

# Easy Connect
DBCLI_CONNECTION="Data Source=localhost:1521/ORCL;User Id=system;Password=xxxxxxxxxx" DBCLI_DBTYPE="oracle" dbcli query "SELECT * FROM v\$version"

# Full descriptor
DBCLI_CONNECTION="Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)));User Id=system;Password=xxxxxxxxxx" DBCLI_DBTYPE="oracle" dbcli query "SELECT * FROM v\$version"
```

### MariaDB

```bash
# Same as MySQL
DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="mariadb" dbcli query "SELECT VERSION()"
```

### TiDB

```bash
# MySQL-compatible syntax
DBCLI_CONNECTION="Server=localhost;Port=4000;Database=mydb;Uid=root;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="tidb" dbcli query "SELECT version()"
```

### DaMeng

```bash
# Standard connection
DBCLI_CONNECTION="Server=localhost;User Id=SYSDBA;PWD=xxxxxxxxxx;DATABASE=mydb" DBCLI_DBTYPE="dm" dbcli query "SELECT * FROM v\$version"

# With port
DBCLI_CONNECTION="Server=localhost;Port=5236;User Id=SYSDBA;PWD=xxxxxxxxxx;DATABASE=mydb" DBCLI_DBTYPE="dm" dbcli query "SELECT * FROM v\$version"

# Remote server
DBCLI_CONNECTION="Server=192.168.1.100;User Id=SYSDBA;PWD=xxxxxxxxxx;DATABASE=mydb" DBCLI_DBTYPE="dm" dbcli query "SELECT * FROM v\$version"
```

**Aliases**: `dm`, `dameng`

### KingbaseES

```bash
# Standard connection
DBCLI_CONNECTION="Server=localhost;Port=54321;UID=system;PWD=xxxxxxxxxx;database=mydb" DBCLI_DBTYPE="kdbndp" dbcli query "SELECT version()"

# With schema
DBCLI_CONNECTION="Server=localhost;Port=54321;UID=system;PWD=xxxxxxxxxx;database=mydb;SearchPath=public" DBCLI_DBTYPE="kdbndp" dbcli query "SELECT version()"
```

**Aliases**: `kdbndp`, `kingbase`

### Oscar

```bash
# Standard connection
DBCLI_CONNECTION="Data Source=localhost;User Id=SYSDBA;Password=xxxxxxxxxx;Database=mydb" DBCLI_DBTYPE="oscar" dbcli query "SELECT version()"

# With port
DBCLI_CONNECTION="Data Source=localhost:2003;User Id=SYSDBA;Password=xxxxxxxxxx;Database=mydb" DBCLI_DBTYPE="oscar" dbcli query "SELECT version()"
```

**Aliases**: `oscar`, `shentong`

### HighGo
```bash
# Standard connection
DBCLI_CONNECTION="Host=localhost;Port=5866;Database=mydb;Username=highgo;Password=xxxxxxxxxx" DBCLI_DBTYPE="highgo" dbcli query "SELECT version()"

# PostgreSQL-compatible
DBCLI_CONNECTION="Host=localhost;Port=5866;Database=mydb;Username=highgo;Password=xxxxxxxxxx;SSL Mode=Prefer" DBCLI_DBTYPE="highgo" dbcli query "SELECT version()"
```

**Aliases**: `highgo`, `hg`

### GaussDB

```bash
# Standard connection
DBCLI_CONNECTION="Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=xxxxxxxxxx" DBCLI_DBTYPE="gaussdb" dbcli query "SELECT version()"

# With SSL
DBCLI_CONNECTION="Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=xxxxxxxxxx;SSL Mode=Require" DBCLI_DBTYPE="gaussdb" dbcli query "SELECT version()"

# Remote server
DBCLI_CONNECTION="Host=192.168.1.100;Port=8000;Database=mydb;Username=gaussdb;Password=xxxxxxxxxx" DBCLI_DBTYPE="gaussdb" dbcli query "SELECT version()"
```

**Aliases**: `gaussdb`, `gauss`

### GBase (南大通用)

```bash
# Standard connection
DBCLI_CONNECTION="Server=localhost;Port=9088;Database=mydb;Uid=gbasedbt;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="gbase" dbcli query "SELECT version()"
```

**Alias**: `gbase`

## Distributed & Cloud Databases

### OceanBase

```bash
# MySQL-compatible mode
DBCLI_CONNECTION="Server=localhost;Port=2883;Database=mydb;User Id=root;Password=xxxxxxxxxx" DBCLI_DBTYPE="oceanbase" dbcli query "SELECT version()"

# If you see write errors in some environments, try disabling pooling
DBCLI_CONNECTION="Server=localhost;Port=2883;Database=mydb;User Id=root;Password=xxxxxxxxxx;Pooling=false" DBCLI_DBTYPE="oceanbase" dbcli query "SELECT 1"
```

**Notes (common gotchas):**

- If you see errors when doing consecutive writes in some server / proxy environments, try `Pooling=false` in the connection string.
- Some environments may require disabling NVARCHAR-style literals. DbCli supports this via config: set `DisableNvarchar: true` in `appsettings.json` (DbCli also accepts `DisableNarvchar` for compatibility).

**Alias**: `oceanbase`

### PolarDB

```bash
# MySQL-compatible
DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;Pooling=false" DBCLI_DBTYPE="polardb" dbcli query "SELECT 1"
```

**Notes (common gotchas):**

- If you see errors like `Unsupported command` in some network / proxy environments, try `Pooling=false` in the connection string.
- Some environments may require disabling NVARCHAR-style literals. DbCli supports this via config: set `DisableNvarchar: true` in `appsettings.json`.

**Alias**: `polardb`

### TDengine

```bash
# Standard connection
DBCLI_CONNECTION="Host=localhost;Port=6030;Database=mydb;Username=root;Password=xxxxxxxxxx" DBCLI_DBTYPE="tdengine" dbcli query "SHOW DATABASES"

# With connection pool
DBCLI_CONNECTION="Host=localhost;Port=6030;Database=mydb;Username=root;Password=xxxxxxxxxx;PoolSize=10" DBCLI_DBTYPE="tdengine" dbcli query "SHOW DATABASES"
```

**Aliases**: `tdengine`, `td`

### ClickHouse

```bash
# HTTP interface
DBCLI_CONNECTION="Host=localhost;Port=8123;Database=default;User=default;Password=xxxxxxxxxx" DBCLI_DBTYPE="clickhouse" dbcli query "SELECT version()"

# With compression
DBCLI_CONNECTION="Host=localhost;Port=8123;Database=default;User=default;Password=xxxxxxxxxx;Compress=True" DBCLI_DBTYPE="clickhouse" dbcli query "SELECT version()"

# HTTPS
DBCLI_CONNECTION="Host=localhost;Port=8443;Database=default;User=default;Password=xxxxxxxxxx;UseSSL=True" DBCLI_DBTYPE="clickhouse" dbcli query "SELECT version()"
```

**Notes (from SqlSugar docs / common gotchas):**

- Case sensitivity: table/column name casing should match the database exactly.
- Transactions: ClickHouse does not support transactions.
- Platform note: some ClickHouse client/provider setups are Linux-only.
- Docker (server): `docker pull yandex/clickhouse-server`
- BulkCopy requires newer SqlSugar packages (see SqlSugar docs): `SqlSugarCore 5.1.3.31-preview11+` and `SqlSugar.ClickHouseCore 5.1.3.31`.

**Alias**: `clickhouse`

### Doris

```bash
# Standard connection (MySQL protocol)
DBCLI_CONNECTION="Server=localhost;Port=9030;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;Pooling=false" DBCLI_DBTYPE="doris" dbcli query "SELECT 1"

# Load balancing (FE list)
DBCLI_CONNECTION="Server=fe1,fe2,fe3;Port=9030;Database=MP;Uid=root;Pwd=xxxxxxxxxx;Pooling=true;LoadBalance=RoundRobin" DBCLI_DBTYPE="doris" dbcli query "SELECT 1"
```

**Notes (common gotchas):**

- If you see errors like `Unsupported command` in some network / proxy environments, try `Pooling=false` in the connection string.
- Some environments may require disabling NVARCHAR-style literals. DbCli supports this via config: set `DisableNvarchar: true` in `appsettings.json`.

**Alias**: `doris`

## Analytics & Time-Series Databases

### QuestDB

```bash
# PostgreSQL wire protocol
DBCLI_CONNECTION="host=localhost;port=8812;username=admin;password=xxxxxxxxxx;database=qdb;ServerCompatibilityMode=NoTypeLoading" DBCLI_DBTYPE="questdb" dbcli query "SELECT * FROM sys.tables"
```

**Aliases**: `questdb`, `quest`

### DuckDB

DuckDB is a lightweight, high-performance **embedded OLAP** database (serverless). It is well-suited for local analytics and working with files like CSV/Parquet.

```bash
# Local file
DBCLI_CONNECTION="Data Source=analytics.db" DBCLI_DBTYPE="duckdb" dbcli query "SELECT version()"

# In-memory
DBCLI_CONNECTION="Data Source=:memory:" DBCLI_DBTYPE="duckdb" dbcli query "SELECT version()"

# Read-only
DBCLI_CONNECTION="Data Source=analytics.db;ReadOnly=True" DBCLI_DBTYPE="duckdb" dbcli query "SELECT version()"
```

**.NET / SqlSugar notes (programmatic usage):**

- NuGet: `SqlSugarCore`, `SqlSugar.DuckDBCore`
- If you hit missing-provider issues in single-file / publish scenarios, register the provider assembly at startup:

```csharp
InstanceFactory.CustomAssemblies = new System.Reflection.Assembly[]
{
  typeof(SqlSugar.DuckDB.DuckDBProvider).Assembly
};
```

**Aliases**: `duckdb`, `duck`

### Enterprise Databases

### IBM DB2

```bash
# Standard connection
DBCLI_CONNECTION="Server=localhost:50000;Database=mydb;UID=db2admin;PWD=xxxxxxxxxx" DBCLI_DBTYPE="db2" dbcli query "SELECT SERVICE_LEVEL FROM TABLE(SYSPROC.ENV_GET_INST_INFO())"

# With schema
DBCLI_CONNECTION="Server=localhost:50000;Database=mydb;UID=db2admin;PWD=xxxxxxxxxx;CurrentSchema=MYSCHEMA" DBCLI_DBTYPE="db2" dbcli query "SELECT * FROM SYSTABLES"
```

**Alias**: `db2`

### SAP HANA

```bash
# Standard connection
DBCLI_CONNECTION="Server=localhost:30015;UserName=SYSTEM;Password=xxxxxxxxxx;Database=HDB" DBCLI_DBTYPE="hana" dbcli query "SELECT VERSION FROM M_DATABASE"

# With encryption
DBCLI_CONNECTION="Server=localhost:30013;UserName=SYSTEM;Password=xxxxxxxxxx;Database=HDB;Encrypt=True" DBCLI_DBTYPE="hana" dbcli query "SELECT VERSION FROM M_DATABASE"
```

**Alias**: `hana`

### Microsoft Access

```bash
# Access Database Engine (requires ACE driver)
DBCLI_CONNECTION="Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\mydb.accdb" DBCLI_DBTYPE="access" dbcli query "SELECT * FROM Users"

# With password
DBCLI_CONNECTION="Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\mydb.accdb;Jet OLEDB:Database Password=xxxxxxxxxx" DBCLI_DBTYPE="access" dbcli query "SELECT * FROM Users"

# Legacy Jet 4.0 (.mdb)
DBCLI_CONNECTION="Provider=Microsoft.Jet.OLEDB.4.0;Data Source=C:\mydb.mdb" DBCLI_DBTYPE="access" dbcli query "SELECT * FROM Users"
```

**Alias**: `access`

## NoSQL Databases

### MongoDB

```bash
# Local connection
DBCLI_CONNECTION="mongodb://localhost:27017/mydb" DBCLI_DBTYPE="mongodb" dbcli query "db.users.find()"

# With authentication
DBCLI_CONNECTION="mongodb://user:pass@localhost:27017/mydb?authSource=admin" DBCLI_DBTYPE="mongodb" dbcli query "db.users.find()"

# Replica set
DBCLI_CONNECTION="mongodb://host1:27017,host2:27017,host3:27017/mydb?replicaSet=rs0" DBCLI_DBTYPE="mongodb" dbcli query "db.users.find()"

# Atlas (MongoDB Cloud)
DBCLI_CONNECTION="mongodb+srv://user:pass@cluster0.xxxxx.mongodb.net/mydb?retryWrites=true&w=majority" DBCLI_DBTYPE="mongodb" dbcli query "db.users.find()"
```

**Aliases**: `mongodb`, `mongo`

## Cloud Provider Databases

### Amazon Aurora (MySQL)

```bash
# Aurora MySQL-compatible
DBCLI_CONNECTION="Server=mydb.cluster-xxxxx.us-east-1.rds.amazonaws.com;Database=mydb;Uid=admin;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"

# With SSL
DBCLI_CONNECTION="Server=mydb.cluster-xxxxx.us-east-1.rds.amazonaws.com;Database=mydb;Uid=admin;Pwd=xxxxxxxxxx;SslMode=Required" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"
```

### Azure Database for MySQL

```bash
# Azure MySQL
DBCLI_CONNECTION="Server=mydb.mysql.database.azure.com;Database=mydb;Uid=admin@mydb;Pwd=xxxxxxxxxx;SslMode=Required" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"
```

### Google Cloud SQL for MySQL

```bash
# Cloud SQL public IP
DBCLI_CONNECTION="Server=1.2.3.4;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;SslMode=Required" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"

# Cloud SQL proxy
DBCLI_CONNECTION="Server=localhost;Port=3307;Database=mydb;Uid=root;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"
```

### Percona Server

```bash
# MySQL-compatible
DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"
```

## Generic Connectors

### ODBC

```bash
# SQL Server via ODBC
DBCLI_CONNECTION="Driver={SQL Server};Server=localhost;Database=mydb;Uid=sa;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="odbc" dbcli query "SELECT @@VERSION"
# MySQL via ODBC
DBCLI_CONNECTION="Driver={MySQL ODBC 8.0 Driver};Server=localhost;Database=mydb;User=root;Password=xxxxxxxxxx" DBCLI_DBTYPE="odbc" dbcli query "SELECT VERSION()"
```

**Alias**: `odbc`

### Custom

```bash
# Use for unsupported databases with compatible drivers
DBCLI_CONNECTION="YOUR_CUSTOM_CONNECTION_STRING" DBCLI_DBTYPE="custom" dbcli query "YOUR_QUERY"
```

**Alias**: `custom`

## Environment Variables

Set default connection to avoid repeating connection strings:

### Linux/macOS

```bash
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"

# Now use without -c flag
dbcli query "SELECT * FROM Users"
```

### Windows PowerShell

```powershell
[Environment]::SetEnvironmentVariable("DBCLI_CONNECTION", "Data Source=app.db", "User")
[Environment]::SetEnvironmentVariable("DBCLI_DBTYPE", "sqlite", "User")

# Restart terminal
dbcli query "SELECT * FROM Users"
```

## Connection String Security

### 1. Environment Variables (Recommended for Production)

```bash
export DBCLI_CONNECTION="Server=prod.db;Database=mydb;User Id=app_user;Password=${DB_PASSWORD}"
```

### 2. Configuration Files (Recommended for Development)

`appsettings.json`:
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

### 3. Avoid Hardcoding in Scripts

```bash
# ❌ Bad - password in script
DBCLI_CONNECTION="Server=prod;User Id=sa;Password=xxxxxxxxxx" dbcli query "..."


# ✓ Good - password from environment
DBCLI_CONNECTION="Server=prod;User Id=sa;Password=${DB_PASSWORD}" dbcli query "..."

# ✓ Better - entire connection from config (auto-loads appsettings.json in current directory)
dbcli query "..."
```

## Testing Connections

```bash
# Test with simple query
DBCLI_CONNECTION="Data Source=app.db" dbcli query "SELECT 1"

# SQL Server
DBCLI_CONNECTION="Server=.;Database=master;Trusted_Connection=True" DBCLI_DBTYPE="sqlserver" dbcli query "SELECT @@VERSION"

# MySQL
DBCLI_CONNECTION="Server=localhost;Database=mysql;Uid=root;Pwd=xxxxxxxxxx" DBCLI_DBTYPE="mysql" dbcli query "SELECT VERSION()"

# PostgreSQL
DBCLI_CONNECTION="Host=localhost;Database=postgres;Username=postgres;Password=xxxxxxxxxx" DBCLI_DBTYPE="postgresql" dbcli query "SELECT version()"
```

## Troubleshooting

### Connection Timeout

```bash
# Add timeout parameter
DBCLI_CONNECTION="Server=slow-server;Database=mydb;User Id=sa;Password=xxxxxxxxxx;Connection Timeout=60" DBCLI_DBTYPE="sqlserver" dbcli query "..."
```

### SSL/TLS Issues

```bash
# MySQL - Disable SSL verification (development only)
DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;SslMode=None" DBCLI_DBTYPE="mysql" dbcli query "..."

# PostgreSQL - Require SSL
DBCLI_CONNECTION="Host=localhost;Database=mydb;Username=postgres;Password=xxxxxxxxxx;SSL Mode=Require" DBCLI_DBTYPE="postgresql" dbcli query "..."
```

### Character Encoding

```bash
# MySQL - Force UTF-8
DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;CharSet=utf8mb4" DBCLI_DBTYPE="mysql" dbcli query "..."
```

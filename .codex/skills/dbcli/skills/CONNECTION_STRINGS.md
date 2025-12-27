# Database Connection Strings Reference

Quick reference for connecting to 30+ supported databases using DbCli.

## Format

```bash
dbcli -c "CONNECTION_STRING" -t DATABASE_TYPE [command]
```

## Relational Databases

### SQLite

```bash
# Local file
dbcli -c "Data Source=app.db" query "SELECT * FROM Users"

# Absolute path
dbcli -c "Data Source=C:\databases\myapp.db" query "SELECT * FROM Users"

# In-memory (temporary)
dbcli -c "Data Source=:memory:" query "SELECT 1"
```

### SQL Server

```bash
# Windows Authentication
dbcli -c "Server=.;Database=mydb;Trusted_Connection=True" -t sqlserver query "SELECT @@VERSION"

# SQL Authentication
dbcli -c "Server=localhost;Database=mydb;User Id=sa;Password=Pass123" -t sqlserver query "SELECT @@VERSION"

# Named instance
dbcli -c "Server=.\\SQLEXPRESS;Database=mydb;Trusted_Connection=True" -t sqlserver query "SELECT @@VERSION"

# Remote server
dbcli -c "Server=192.168.1.100;Database=mydb;User Id=sa;Password=Pass123" -t sqlserver query "SELECT @@VERSION"
```

### MySQL

```bash
# Standard connection
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass123" -t mysql query "SELECT VERSION()"

# With port
dbcli -c "Server=localhost;Port=3306;Database=mydb;Uid=root;Pwd=pass123" -t mysql query "SELECT VERSION()"

# With SSL
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass123;SslMode=Required" -t mysql query "SELECT VERSION()"

# UTF-8 charset
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass123;CharSet=utf8mb4" -t mysql query "SELECT VERSION()"
```

### MySQL Connector

```bash
# Alternative MySQL driver
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass123" -t mysqlconnector query "SELECT VERSION()"
```

### PostgreSQL

```bash
# Standard connection
dbcli -c "Host=localhost;Port=5432;Database=mydb;Username=postgres;Password=pass123" -t postgresql query "SELECT version()"

# With SSL
dbcli -c "Host=localhost;Database=mydb;Username=postgres;Password=pass123;SSL Mode=Require" -t postgresql query "SELECT version()"

# Unix socket (Linux)
dbcli -c "Host=/var/run/postgresql;Database=mydb;Username=postgres" -t postgresql query "SELECT version()"
```

### Oracle

```bash
# TNS Names
dbcli -c "Data Source=ORCL;User Id=system;Password=oracle" -t oracle query "SELECT * FROM v\$version"

# Easy Connect
dbcli -c "Data Source=localhost:1521/ORCL;User Id=system;Password=oracle" -t oracle query "SELECT * FROM v\$version"

# Full descriptor
dbcli -c "Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)));User Id=system;Password=oracle" -t oracle query "SELECT * FROM v\$version"
```

### MariaDB

```bash
# Same as MySQL
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass123" -t mariadb query "SELECT VERSION()"
```

### TiDB

```bash
# MySQL-compatible syntax
dbcli -c "Server=localhost;Port=4000;Database=mydb;Uid=root;Pwd=pass123" -t tidb query "SELECT version()"
```

## Chinese Domestic Databases

### DaMeng (达梦)

```bash
# Standard connection
dbcli -c "Server=localhost;User Id=SYSDBA;PWD=SYSDBA;DATABASE=mydb" -t dm query "SELECT * FROM v\$version"

# With port
dbcli -c "Server=localhost;Port=5236;User Id=SYSDBA;PWD=SYSDBA;DATABASE=mydb" -t dm query "SELECT * FROM v\$version"

# Remote server
dbcli -c "Server=192.168.1.100;User Id=SYSDBA;PWD=SYSDBA;DATABASE=mydb" -t dm query "SELECT * FROM v\$version"
```

**Aliases**: `dm`, `dameng`

### KingbaseES (人大金仓)

```bash
# Standard connection
dbcli -c "Server=localhost;Port=54321;UID=system;PWD=system;database=mydb" -t kdbndp query "SELECT version()"

# With schema
dbcli -c "Server=localhost;Port=54321;UID=system;PWD=system;database=mydb;SearchPath=public" -t kdbndp query "SELECT version()"
```

**Aliases**: `kdbndp`, `kingbase`

### Oscar (神通)

```bash
# Standard connection
dbcli -c "Data Source=localhost;User Id=SYSDBA;Password=pass;Database=mydb" -t oscar query "SELECT version()"

# With port
dbcli -c "Data Source=localhost:2003;User Id=SYSDBA;Password=pass;Database=mydb" -t oscar query "SELECT version()"
```

**Aliases**: `oscar`, `shentong`

### HighGo (瀚高)

```bash
# Standard connection
dbcli -c "Host=localhost;Port=5866;Database=mydb;Username=highgo;Password=pass" -t highgo query "SELECT version()"

# PostgreSQL-compatible
dbcli -c "Host=localhost;Port=5866;Database=mydb;Username=highgo;Password=pass;SSL Mode=Prefer" -t highgo query "SELECT version()"
```

**Aliases**: `highgo`, `hg`

### GaussDB (华为)

```bash
# Standard connection
dbcli -c "Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=pass" -t gaussdb query "SELECT version()"

# With SSL
dbcli -c "Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=pass;SSL Mode=Require" -t gaussdb query "SELECT version()"

# Remote server
dbcli -c "Host=192.168.1.100;Port=8000;Database=mydb;Username=gaussdb;Password=pass" -t gaussdb query "SELECT version()"
```

**Aliases**: `gaussdb`, `gauss`

### GBase (南大通用)

```bash
# Standard connection
dbcli -c "Server=localhost;Port=9088;Database=mydb;Uid=gbasedbt;Pwd=pass" -t gbase query "SELECT version()"
```

**Alias**: `gbase`

## Distributed & Cloud Databases

### OceanBase

```bash
# MySQL-compatible mode
dbcli -c "Server=localhost;Port=2883;Database=mydb;User Id=root;Password=pass" -t oceanbase query "SELECT version()"

# Oracle-compatible mode
dbcli -c "Server=localhost;Port=2881;Database=mydb;User Id=sys;Password=pass" -t oceanbase query "SELECT * FROM v\$version"
```

**Alias**: `oceanbase`

### TDengine

```bash
# Standard connection
dbcli -c "Host=localhost;Port=6030;Database=mydb;Username=root;Password=taosdata" -t tdengine query "SHOW DATABASES"

# With connection pool
dbcli -c "Host=localhost;Port=6030;Database=mydb;Username=root;Password=taosdata;PoolSize=10" -t tdengine query "SHOW DATABASES"
```

**Aliases**: `tdengine`, `td`

### ClickHouse

```bash
# HTTP interface
dbcli -c "Host=localhost;Port=8123;Database=default;User=default;Password=" -t clickhouse query "SELECT version()"

# With compression
dbcli -c "Host=localhost;Port=8123;Database=default;User=default;Password=;Compress=True" -t clickhouse query "SELECT version()"

# HTTPS
dbcli -c "Host=localhost;Port=8443;Database=default;User=default;Password=;UseSSL=True" -t clickhouse query "SELECT version()"
```

**Alias**: `clickhouse`

## Analytics & Time-Series Databases

### QuestDB

```bash
# PostgreSQL wire protocol
dbcli -c "host=localhost;port=8812;username=admin;password=quest;database=qdb;ServerCompatibilityMode=NoTypeLoading" -t questdb query "SELECT * FROM sys.tables"
```

**Aliases**: `questdb`, `quest`

### DuckDB

```bash
# Local file
dbcli -c "Data Source=analytics.db" -t duckdb query "SELECT version()"

# In-memory
dbcli -c "Data Source=:memory:" -t duckdb query "SELECT version()"

# Read-only
dbcli -c "Data Source=analytics.db;ReadOnly=True" -t duckdb query "SELECT version()"
```

**Aliases**: `duckdb`, `duck`

## Enterprise Databases

### IBM DB2

```bash
# Standard connection
dbcli -c "Server=localhost:50000;Database=mydb;UID=db2admin;PWD=pass" -t db2 query "SELECT SERVICE_LEVEL FROM TABLE(SYSPROC.ENV_GET_INST_INFO())"

# With schema
dbcli -c "Server=localhost:50000;Database=mydb;UID=db2admin;PWD=pass;CurrentSchema=MYSCHEMA" -t db2 query "SELECT * FROM SYSTABLES"
```

**Alias**: `db2`

### SAP HANA

```bash
# Standard connection
dbcli -c "Server=localhost:30015;UserName=SYSTEM;Password=pass;Database=HDB" -t hana query "SELECT VERSION FROM M_DATABASE"

# With encryption
dbcli -c "Server=localhost:30013;UserName=SYSTEM;Password=pass;Database=HDB;Encrypt=True" -t hana query "SELECT VERSION FROM M_DATABASE"
```

**Alias**: `hana`

### Microsoft Access

```bash
# Access Database Engine (requires ACE driver)
dbcli -c "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\mydb.accdb" -t access query "SELECT * FROM Users"

# With password
dbcli -c "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=C:\mydb.accdb;Jet OLEDB:Database Password=pass" -t access query "SELECT * FROM Users"

# Legacy Jet 4.0 (.mdb)
dbcli -c "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=C:\mydb.mdb" -t access query "SELECT * FROM Users"
```

**Alias**: `access`

## NoSQL Databases

### MongoDB

```bash
# Local connection
dbcli -c "mongodb://localhost:27017/mydb" -t mongodb query "db.users.find()"

# With authentication
dbcli -c "mongodb://user:pass@localhost:27017/mydb?authSource=admin" -t mongodb query "db.users.find()"

# Replica set
dbcli -c "mongodb://host1:27017,host2:27017,host3:27017/mydb?replicaSet=rs0" -t mongodb query "db.users.find()"

# Atlas (MongoDB Cloud)
dbcli -c "mongodb+srv://user:pass@cluster0.xxxxx.mongodb.net/mydb?retryWrites=true&w=majority" -t mongodb query "db.users.find()"
```

**Aliases**: `mongodb`, `mongo`

## Cloud Provider Databases

### Amazon Aurora (MySQL)

```bash
# Aurora MySQL-compatible
dbcli -c "Server=mydb.cluster-xxxxx.us-east-1.rds.amazonaws.com;Database=mydb;Uid=admin;Pwd=pass" -t mysql query "SELECT VERSION()"

# With SSL
dbcli -c "Server=mydb.cluster-xxxxx.us-east-1.rds.amazonaws.com;Database=mydb;Uid=admin;Pwd=pass;SslMode=Required" -t mysql query "SELECT VERSION()"
```

### Azure Database for MySQL

```bash
# Azure MySQL
dbcli -c "Server=mydb.mysql.database.azure.com;Database=mydb;Uid=admin@mydb;Pwd=pass;SslMode=Required" -t mysql query "SELECT VERSION()"
```

### Google Cloud SQL for MySQL

```bash
# Cloud SQL public IP
dbcli -c "Server=1.2.3.4;Database=mydb;Uid=root;Pwd=pass;SslMode=Required" -t mysql query "SELECT VERSION()"

# Cloud SQL proxy
dbcli -c "Server=localhost;Port=3307;Database=mydb;Uid=root;Pwd=pass" -t mysql query "SELECT VERSION()"
```

### Percona Server

```bash
# MySQL-compatible
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass" -t mysql query "SELECT VERSION()"
```

## Generic Connectors

### ODBC

```bash
# SQL Server via ODBC
dbcli -c "Driver={SQL Server};Server=localhost;Database=mydb;Uid=sa;Pwd=pass" -t odbc query "SELECT @@VERSION"

# MySQL via ODBC
dbcli -c "Driver={MySQL ODBC 8.0 Driver};Server=localhost;Database=mydb;User=root;Password=pass" -t odbc query "SELECT VERSION()"
```

**Alias**: `odbc`

### Custom

```bash
# Use for unsupported databases with compatible drivers
dbcli -c "YOUR_CUSTOM_CONNECTION_STRING" -t custom query "YOUR_QUERY"
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
dbcli --config appsettings.json query "SELECT * FROM Users"
```

### 3. Avoid Hardcoding in Scripts

```bash
# ❌ Bad - password in script
dbcli -c "Server=prod;User Id=sa;Password=MyPassword123" query "..."

# ✓ Good - password from environment
dbcli -c "Server=prod;User Id=sa;Password=${DB_PASSWORD}" query "..."

# ✓ Better - entire connection from config
dbcli --config appsettings.json query "..."
```

## Testing Connections

```bash
# Test with simple query
dbcli -c "Data Source=app.db" query "SELECT 1"

# SQL Server
dbcli -c "Server=.;Database=master;Trusted_Connection=True" -t sqlserver query "SELECT @@VERSION"

# MySQL
dbcli -c "Server=localhost;Database=mysql;Uid=root;Pwd=pass" -t mysql query "SELECT VERSION()"

# PostgreSQL
dbcli -c "Host=localhost;Database=postgres;Username=postgres;Password=pass" -t postgresql query "SELECT version()"
```

## Troubleshooting

### Connection Timeout

```bash
# Add timeout parameter
dbcli -c "Server=slow-server;Database=mydb;User Id=sa;Password=pass;Connection Timeout=60" -t sqlserver query "..."
```

### SSL/TLS Issues

```bash
# MySQL - Disable SSL verification (development only)
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass;SslMode=None" -t mysql query "..."

# PostgreSQL - Require SSL
dbcli -c "Host=localhost;Database=mydb;Username=postgres;Password=pass;SSL Mode=Require" -t postgresql query "..."
```

### Character Encoding

```bash
# MySQL - Force UTF-8
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass;CharSet=utf8mb4" -t mysql query "..."
```

## See Also

- [Skills README](README.md) - Main skills documentation
- [DbCli README](../README.md) - Tool documentation
- [Installation Guide](../dist/INSTALL.md) - Setup instructions

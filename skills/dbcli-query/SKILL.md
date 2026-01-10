---
name: dbcli-query
description: Execute SELECT queries on 30+ databases (SQLite, SQL Server, MySQL, PostgreSQL, Oracle, etc.) using DbCli. Returns data in JSON, table, or CSV format. Use when user needs to query databases, read data, or execute SELECT statements.
license: MIT
compatibility: Requires DbCli CLI tool (based on .NET 10 and SqlSugar). Supports Windows, Linux, macOS.
metadata:
  tool: dbcli
  version: "1.0.0"
  category: database
  supported-databases: "30+"
allowed-tools: dbcli
---

## Command Style (Use PATH)

All examples use the plain command name `dbcli` (no directory prefix).
Ensure `dbcli` is on PATH instead of hardcoding paths like `.\.claude\skills\dbcli\dbcli.exe`.

# DbCli Query Skill

Execute SELECT queries on 30+ databases using the DbCli command-line tool.

## Connection Configuration

Set environment variables before using dbcli:

```bash
# PowerShell
$env:DBCLI_CONNECTION = "your-connection-string"
$env:DBCLI_DBTYPE = "database-type"

# Bash
export DBCLI_CONNECTION="your-connection-string"
export DBCLI_DBTYPE=database-type
```

Or use config file:

```bash
# If appsettings.json is in the current working directory, DbCli auto-loads it
dbcli query "..."
```

# DbCli Query Skill

Execute SELECT queries on 30+ databases using the DbCli command-line tool.

## When to Use This Skill

- User wants to query database tables
- User needs to read data from a database
- User mentions SELECT, query, search, filter, or find data
- User wants to retrieve records from any supported database

## Supported Databases

DbCli is built on SqlSugar and supports 30+ databases. Examples:

SQLite, SQL Server, MySQL, PostgreSQL, Oracle, MongoDB, ClickHouse, Doris, OceanBase, TDengine, DuckDB, etc.

## Command Syntax

**Environment variables or config file required (no `-c` parameter):**

```bash
# Set environment variables first:
# DBCLI_CONNECTION="connection-string"
# DBCLI_DBTYPE=database-type

dbcli query "SQL_QUERY" [-f FORMAT] [-p JSON] [-P params.json]

# Or use an explicit config path:
dbcli query "SQL_QUERY" --config <path> [-f FORMAT]
```

### Options

Options can appear either before or after the subcommand. Command-first is recommended.

- Environment variables:
  - `DBCLI_CONNECTION`: Database connection string
  - `DBCLI_DBTYPE`: Database type (alternative to -t)
- `-t, --db-type`: Database type (default: sqlite)
- `-f, --format`: Output format: `json` (default), `table`, `csv`
- `-p, --params`: JSON parameters object (use `@Param` placeholders)
- `-P, --params-file`: Read JSON parameters from file

### Subcommand Options

- `-F, --file`: Read SQL from file instead of command line
- `--config`: Path to configuration file

## Usage Examples

### Basic Query

```bash
# SQLite - Query all users
export DBCLI_CONNECTION="Data Source=app.db"
dbcli query "SELECT * FROM Users"

# SQL Server - Query with TOP
export DBCLI_CONNECTION="Server=localhost;Database=mydb;Trusted_Connection=True"
export DBCLI_DBTYPE="sqlserver"
dbcli query "SELECT TOP 10 * FROM Users"

# MySQL - Query with LIMIT
export DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx"
export DBCLI_DBTYPE="mysql"
dbcli query "SELECT * FROM Users LIMIT 10"

# PostgreSQL - Query with WHERE clause
export DBCLI_CONNECTION="Host=localhost;Database=mydb;Username=postgres;Password=xxxxxxxxxx"
export DBCLI_DBTYPE="postgresql"
dbcli query "SELECT * FROM Users WHERE active = true"
```

### Table Format Output

```bash
# Display results as formatted table
export DBCLI_CONNECTION="Data Source=app.db"
dbcli -f table query "SELECT * FROM Users"

# Output:
# +----+-------+-------------------+
# | Id | Name  | Email             |
# +----+-------+-------------------+
# | 1  | Alice | alice@example.com |
# | 2  | Bob   | bob@example.com   |
# +----+-------+-------------------+
```

### Parameterized Query (RDB)

```bash
export DBCLI_CONNECTION="Data Source=app.db"
dbcli query "SELECT @Id AS Id, @Name AS Name" -p '{"Id":1,"Name":"Alice"}'

# IN (...) with array
dbcli query "SELECT * FROM Users WHERE Id IN (@Ids)" -p '{"Ids":[1,2,3]}'
```

Notes:

- SQLite providers may require `DisableClearParameters: true` in config (maps to SqlSugar `IsClearParameters=false`).
- DbCli returns a single result set. SqlSugar supports multi-result sets/output parameters, but DbCli does not surface them yet.

### CSV Format Output

```bash
# Export query results as CSV
export DBCLI_CONNECTION="Data Source=app.db"
dbcli -f csv query "SELECT * FROM Products" > products.csv
```

### Query from File

```bash
# Complex query stored in file
export DBCLI_CONNECTION="Data Source=app.db"
dbcli query -F complex_query.sql
```

```bash
# DaMeng
export DBCLI_CONNECTION="Server=localhost;User Id=SYSDBA;PWD=xxxxxxxxxx;DATABASE=mydb"
export DBCLI_DBTYPE="dm"
dbcli -f table query "SELECT * FROM dm_test"

# KingbaseES
export DBCLI_CONNECTION="Server=localhost;Port=54321;UID=system;PWD=xxxxxxxxxx;database=mydb"
export DBCLI_DBTYPE="kdbndp"
dbcli -f table query "SELECT * FROM kingbase_test"

# GaussDB
export DBCLI_CONNECTION="Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=xxxxxxxxxx"
export DBCLI_DBTYPE="gaussdb"
dbcli -f table query "SELECT * FROM gauss_test"
```

### Advanced Queries

```bash
export DBCLI_CONNECTION="Data Source=app.db"

# Aggregation
dbcli query "SELECT category, COUNT(*) as count, AVG(price) as avg_price FROM products GROUP BY category"

# Join query
dbcli query "SELECT u.name, o.order_date, o.total FROM users u JOIN orders o ON u.id = o.user_id"

# Subquery
dbcli query "SELECT * FROM products WHERE price > (SELECT AVG(price) FROM products)"
```

## Configuration Methods

### Method 1: Environment Variables (Recommended)

```bash
# Set once per session
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"

# Use without connection string
dbcli query "SELECT * FROM Users"
```

### Method 2: PowerShell Environment Variables

```powershell
# Set once per session
$env:DBCLI_CONNECTION = "Data Source=app.db"
$env:DBCLI_DBTYPE = "sqlite"

# Use without connection string
dbcli query "SELECT * FROM Users"
```

```powershell
# Windows PowerShell
[Environment]::SetEnvironmentVariable("DBCLI_CONNECTION", "Data Source=app.db", "User")
[Environment]::SetEnvironmentVariable("DBCLI_DBTYPE", "sqlite", "User")
```

### Method 3: Configuration File

Create `appsettings.json`:

```json
{
  "ConnectionString": "Data Source=app.db",
  "DbType": "sqlite"
}
```

Use config file:

```bash
# If appsettings.json is in the current working directory, DbCli auto-loads it
dbcli query "SELECT * FROM Users"
```

## Connection String Reference

### SQLite
```
Data Source=app.db
```

### SQL Server
```
Server=localhost;Database=mydb;User Id=sa;Password=xxxxxxxxxx;
```

### MySQL
```
Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;
```

### PostgreSQL
```
Host=localhost;Port=5432;Database=mydb;Username=postgres;Password=xxxxxxxxxx;
```

### Oracle
```
Data Source=localhost:1521/orcl;User Id=system;Password=xxxxxxxxxx;
```

### ClickHouse

```
Host=localhost;Port=8123;Database=default;User=default;Password=xxxxxxxxxx

Notes: identifiers (table/column) may be case-sensitive; ClickHouse does not support transactions.

### MongoDB
```
mongodb://localhost:27017/mydb
```

### Doris

```
Server=localhost;Port=9030;Database=mydb;Uid=root;Pwd=xxxxxxxxxx;Pooling=false
```

If you see errors like `Unsupported command` in some network/proxy environments, try `Pooling=false`.

Some environments may require disabling NVARCHAR-style literals. DbCli supports this via config: set `DisableNvarchar: true` in `appsettings.json`.

See `../CONNECTION_STRINGS.md` for complete reference.

## Programmatic Usage

### Python

```python
import subprocess
import json
import os

# Set environment variables
os.environ['DBCLI_CONNECTION'] = 'Data Source=app.db'

result = subprocess.run([
    'dbcli', 'query', 'SELECT * FROM Users'
], capture_output=True, text=True)

users = json.loads(result.stdout)
for user in users:
    print(f"{user['Name']} - {user['Email']}")
```

### Node.js

```javascript
const { execSync } = require('child_process');

// Set environment variables
process.env.DBCLI_CONNECTION = 'Data Source=app.db';

const result = execSync('dbcli query "SELECT * FROM Users"');
const users = JSON.parse(result.toString());

users.forEach(user => {
    console.log(`${user.Name} - ${user.Email}`);
});
```

### PowerShell

```powershell
$env:DBCLI_CONNECTION = "Data Source=app.db"
$result = dbcli query "SELECT * FROM Users" | ConvertFrom-Json
$result | ForEach-Object { Write-Host "$($_.Name) - $($_.Email)" }
```

## Error Handling

```bash
export DBCLI_CONNECTION="Data Source=app.db"

# Check exit code
dbcli query "SELECT * FROM Users"
if [ $? -eq 0 ]; then
    echo "Query succeeded"
else
    echo "Query failed"
fi
```

## Performance Tips

1. **Use specific columns** instead of `SELECT *` for large tables
2. **Add WHERE clauses** to filter data at the database level
3. **Use LIMIT/TOP** to restrict result set size
4. **Use table format** (`-f table`) for human review, JSON for programmatic processing
5. **Store complex queries** in files using `-F` option

## Common Patterns

### Check Record Count

```bash
export DBCLI_CONNECTION="Data Source=app.db"
dbcli query "SELECT COUNT(*) as total FROM Users"
```

### Verify Table Exists

```bash
export DBCLI_CONNECTION="Data Source=app.db"
dbcli query "SELECT name FROM sqlite_master WHERE type='table' AND name='Users'"
```

### Test Connection

```bash
export DBCLI_CONNECTION="Data Source=app.db"
dbcli query "SELECT 1"
```

### Sample Data

```bash
# Get first 5 records
export DBCLI_CONNECTION="Data Source=app.db"
dbcli -f table query "SELECT * FROM Users LIMIT 5"
```

## Security Considerations

1. **Avoid SQL injection**: Never concatenate user input directly into queries
2. **Use environment variables** for sensitive connection strings
3. **Limit permissions**: Use read-only database users for query operations
4. **Validate input**: Check user-provided table/column names before querying

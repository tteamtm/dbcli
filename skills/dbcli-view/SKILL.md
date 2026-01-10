---
name: dbcli-view
description: Manage database views (CREATE/ALTER/DROP VIEW operations)
license: MIT
compatibility: Requires DbCli CLI tool (based on .NET 10 and SqlSugar). Supports Windows, Linux, macOS.
metadata:
  tool: dbcli
  version: "1.0.0"
  category: database
  supported-databases: "30+"
  safety-level: moderate
  requires-backup: recommended
  tags: [dbcli, sql, views, ddl, database]
  repository: https://github.com/your-repo/dbcli
allowed-tools: dbcli
---


# DbCli View Management Skill

## Command Style (Use PATH)

All examples use the plain command name `dbcli` (no directory prefix).
Ensure `dbcli` is on PATH instead of hardcoding paths like `.\.claude\skills\dbcli\dbcli.exe`.


## Overview

Manage database views using DbCli's DDL command. This skill covers creating, altering, and dropping views across 30+ database systems.

**Safety Level**: Moderate  
**Requires Backup**: Recommended before DROP operations

## Quick Start

```bash
export DBCLI_CONNECTION="Data Source=app.db"

# Create a new view
dbcli ddl "CREATE VIEW ActiveUsers AS SELECT * FROM Users WHERE status='active'"

# Drop a view
dbcli ddl "DROP VIEW OldReport"

# List all views (database-specific queries)
dbcli query "SELECT name FROM sqlite_master WHERE type='view'"
```

---

## Command Syntax

```bash
# Set environment variables first:
# export DBCLI_CONNECTION="connection-string"
# export DBCLI_DBTYPE="database-type"

dbcli ddl "<VIEW_DDL_STATEMENT>"
```

### Options

| Option | Alias | Description | Example |
|--------|-------|-------------|---------||
| Environment | | Database connection string | `export DBCLI_CONNECTION="Server=localhost;Database=mydb"` |
| Environment | | Database type | `export DBCLI_DBTYPE="sqlserver"` |
| `--db-type` | `-t` | Database type | `-t sqlserver`, `-t mysql` |
| `--format` | `-f` | Output format | `-f json`, `-f table` |
| `--file` | `-F` | Read SQL from file | `-F create_view.sql` |
| `--config` | | Use config file | `--config <path>` |

---

## Core Operations

### 1. Create View

#### SQLite
```bash
export DBCLI_CONNECTION="Data Source=app.db"

dbcli ddl "
CREATE VIEW IF NOT EXISTS ActiveUsers AS 
SELECT id, name, email, created_at 
FROM Users 
WHERE status = 'active'"
```

#### SQL Server
```bash
export DBCLI_CONNECTION="Server=.;Database=mydb;Trusted_Connection=True"
export DBCLI_DBTYPE="sqlserver"

dbcli ddl "
CREATE OR ALTER VIEW dbo.CustomerOrders AS
SELECT c.CustomerID, c.Name, COUNT(o.OrderID) as OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Name"
```

#### MySQL
```bash
export DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx"
export DBCLI_DBTYPE="mysql"

dbcli ddl "
CREATE OR REPLACE VIEW ProductSummary AS
SELECT category, COUNT(*) as product_count, AVG(price) as avg_price
FROM Products
GROUP BY category"
```

#### PostgreSQL
```bash
export DBCLI_CONNECTION="Host=localhost;Database=mydb;Username=postgres;Password=xxxxxxxxxx"
export DBCLI_DBTYPE="postgresql"

dbcli ddl "
CREATE OR REPLACE VIEW public.recent_orders AS
SELECT * FROM orders WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'"
```

#### Oracle
```bash
export DBCLI_CONNECTION="Data Source=orcl;User Id=system;Password=xxxxxxxxxx"
export DBCLI_DBTYPE="oracle"

dbcli ddl "
CREATE OR REPLACE VIEW emp_dept_view AS
SELECT e.employee_id, e.name, d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id"
```

#### DaMeng
```bash
export DBCLI_CONNECTION="Server=localhost;User Id=SYSDBA;PWD=xxxxxxxxxx;DATABASE=mydb"
export DBCLI_DBTYPE="dm"

dbcli ddl "
CREATE VIEW sales_summary AS
SELECT region, SUM(amount) as total_sales
FROM sales
GROUP BY region"
```

#### GaussDB
```bash
export DBCLI_CONNECTION="Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=xxxxxxxxxx"
export DBCLI_DBTYPE="gaussdb"

dbcli ddl "
CREATE VIEW active_sessions AS
SELECT * FROM pg_stat_activity WHERE state = 'active'"
```

#### KingbaseES
```bash
export DBCLI_CONNECTION="Server=localhost;Port=54321;Database=mydb;UID=system;PWD=xxxxxxxxxx"
export DBCLI_DBTYPE="kdbndp"

dbcli ddl "
CREATE VIEW inventory_status AS
SELECT product_id, product_name, stock_quantity, 
       CASE WHEN stock_quantity < 10 THEN 'Low' ELSE 'OK' END as status
FROM inventory"
```

---

### 2. Alter View (Database-Specific)

#### SQL Server (CREATE OR ALTER)
```bash
export DBCLI_CONNECTION="Server=.;Database=mydb"
export DBCLI_DBTYPE="sqlserver"

dbcli ddl "
CREATE OR ALTER VIEW CustomerSummary AS
SELECT CustomerID, Name, Email, Phone
FROM Customers
WHERE Country = 'USA'"
```

#### MySQL (CREATE OR REPLACE)
```bash
export DBCLI_CONNECTION="Server=localhost;Database=mydb"
export DBCLI_DBTYPE="mysql"

dbcli ddl "
CREATE OR REPLACE VIEW OrderStats AS
SELECT DATE(order_date) as date, COUNT(*) as orders, SUM(total) as revenue
FROM Orders
GROUP BY DATE(order_date)"
```

#### PostgreSQL (CREATE OR REPLACE)
```bash
export DBCLI_CONNECTION="Host=localhost;Database=mydb"
export DBCLI_DBTYPE="postgresql"

dbcli ddl "
CREATE OR REPLACE VIEW user_activity AS
SELECT user_id, COUNT(*) as login_count, MAX(login_time) as last_login
FROM user_logins
WHERE login_time >= NOW() - INTERVAL '7 days'
GROUP BY user_id"
```

#### Oracle (CREATE OR REPLACE)
```bash
export DBCLI_CONNECTION="Data Source=orcl"
export DBCLI_DBTYPE="oracle"

dbcli ddl "
CREATE OR REPLACE VIEW dept_salary AS
SELECT department_id, AVG(salary) as avg_salary, MAX(salary) as max_salary
FROM employees
GROUP BY department_id"
```

---

### 3. Drop View

⚠️ **WARNING**: Dropping a view is irreversible. Export the view definition first!

#### Export View Definition First (Recommended)
```bash
export DBCLI_CONNECTION="Data Source=app.db"

# SQLite - Export view definition
dbcli query "
SELECT sql FROM sqlite_master WHERE type='view' AND name='ActiveUsers'" > view_backup.sql

# SQL Server - Export view definition
export DBCLI_CONNECTION="Server=.;Database=mydb"
export DBCLI_DBTYPE="sqlserver"
dbcli query "
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.CustomerOrders'))" > view_backup.sql

# MySQL - Export view definition
export DBCLI_CONNECTION="Server=localhost;Database=mydb"
export DBCLI_DBTYPE="mysql"
dbcli query "
SHOW CREATE VIEW ProductSummary" > view_backup.sql

# PostgreSQL - Export view definition
export DBCLI_CONNECTION="Host=localhost;Database=mydb"
export DBCLI_DBTYPE="postgresql"
dbcli query "
SELECT definition FROM pg_views WHERE viewname='recent_orders'" > view_backup.sql
```

#### Drop View Commands

##### SQLite
```bash
export DBCLI_CONNECTION="Data Source=app.db"
dbcli ddl "DROP VIEW IF EXISTS OldReport"
```

##### SQL Server
```bash
export DBCLI_CONNECTION="Server=.;Database=mydb"
export DBCLI_DBTYPE="sqlserver"
dbcli ddl "DROP VIEW IF EXISTS dbo.ObsoleteView"
```

##### MySQL
```bash
export DBCLI_CONNECTION="Server=localhost;Database=mydb"
export DBCLI_DBTYPE="mysql"
dbcli ddl "DROP VIEW IF EXISTS TempView"
```

##### PostgreSQL
```bash
export DBCLI_CONNECTION="Host=localhost;Database=mydb"
export DBCLI_DBTYPE="postgresql"
dbcli ddl "DROP VIEW IF EXISTS public.old_stats CASCADE"
```

##### Oracle
```bash
export DBCLI_CONNECTION="Data Source=orcl"
export DBCLI_DBTYPE="oracle"
dbcli ddl "DROP VIEW deprecated_view"
```

---

### 4. List Views

#### DbCli (recommended)
```bash
# DM / Oracle: list all accessible views (ALL_VIEWS)
export DBCLI_CONNECTION="Server=localhost;User Id=SYSDBA;PWD=xxxxxxxxxx;DATABASE=mydb"
export DBCLI_DBTYPE="dm"
dbcli views --scope all --owner DOC -f table

# Current user only (default scope)
export DBCLI_CONNECTION="Data Source=app.db"
dbcli views -f table

# Include definitions
dbcli views --with-definition -f table
```

#### SQLite
```bash
export DBCLI_CONNECTION="Data Source=app.db"
dbcli query "
SELECT name, sql FROM sqlite_master WHERE type='view' ORDER BY name" -f table
```

#### SQL Server
```bash
export DBCLI_CONNECTION="Server=.;Database=mydb"
export DBCLI_DBTYPE="sqlserver"
dbcli query "
SELECT TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_SCHEMA, TABLE_NAME" -f table
```

#### MySQL
```bash
export DBCLI_CONNECTION="Server=localhost;Database=mydb"
export DBCLI_DBTYPE="mysql"
dbcli query "
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'mydb'
ORDER BY TABLE_NAME" -f table
```

#### PostgreSQL
```bash
export DBCLI_CONNECTION="Host=localhost;Database=mydb"
dbcli -t postgresql query "
SELECT schemaname, viewname, definition
FROM pg_views
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, viewname" -f table
```

#### Oracle
```bash
export DBCLI_CONNECTION="Data Source=orcl"
dbcli -t oracle query "
SELECT view_name, text FROM user_views ORDER BY view_name" -f table
```

---

### 5. View Definition Details

#### SQLite
```bash
export DBCLI_CONNECTION="Data Source=app.db"
dbcli query "
SELECT sql FROM sqlite_master WHERE type='view' AND name='ActiveUsers'"
```

#### SQL Server
```bash
export DBCLI_CONNECTION="Server=.;Database=mydb"
dbcli -t sqlserver query "
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.CustomerOrders'))"
```

#### MySQL
```bash
export DBCLI_CONNECTION="Server=localhost;Database=mydb"
dbcli -t mysql query "
SHOW CREATE VIEW ProductSummary"
```

#### PostgreSQL
```bash
export DBCLI_CONNECTION="Host=localhost;Database=mydb"
dbcli -t postgresql query "
SELECT pg_get_viewdef('public.recent_orders'::regclass, true)"
```

#### Oracle
```bash
export DBCLI_CONNECTION="Data Source=orcl"
dbcli -t oracle query "
SELECT text FROM user_views WHERE view_name = 'EMP_DEPT_VIEW'"
```

---

## Code Integration Examples

### Node.js / JavaScript

```javascript
const { execSync } = require('child_process');
const fs = require('fs');

// Set connection
process.env.DBCLI_CONNECTION = 'Data Source=app.db';

// Create a view
function createView(viewName, query) {
  const sql = `CREATE VIEW ${viewName} AS ${query}`;
  execSync(`dbcli ddl "${sql}"`);
  console.log(`✅ View ${viewName} created`);
}

// Drop view with backup
function dropViewSafely(viewName) {
  // 1. Export view definition
  const definition = execSync(
    `dbcli query "SELECT sql FROM sqlite_master WHERE type='view' AND name='${viewName}'"`
  ).toString();
  
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  fs.writeFileSync(`backup_${viewName}_${timestamp}.sql`, definition);
  
  // 2. Drop view
  execSync(`dbcli ddl "DROP VIEW IF EXISTS ${viewName}"`);
  console.log(`✅ View ${viewName} dropped (backup saved)`);
}

// List all views
function listViews() {
  const result = JSON.parse(
    execSync('dbcli query "SELECT name FROM sqlite_master WHERE type=\'view\'"').toString()
  );
  return result;
}

// Usage
createView('ActiveUsers', 'SELECT * FROM Users WHERE status="active"');
console.log('Views:', listViews());
dropViewSafely('OldReport');
```

---

### Python

```python
import subprocess
import json
import os
from datetime import datetime

# Set connection
os.environ['DBCLI_CONNECTION'] = 'Data Source=app.db'

def create_view(view_name: str, query: str):
    """Create a database view"""
    sql = f"CREATE VIEW {view_name} AS {query}"
    subprocess.run(['dbcli', 'ddl', sql], check=True)
    print(f"✅ View {view_name} created")

def drop_view_safely(view_name: str):
    """Drop view with automatic backup"""
    # 1. Export view definition
    result = subprocess.run(
        ['dbcli', 'query', 
         f"SELECT sql FROM sqlite_master WHERE type='view' AND name='{view_name}'"],
        capture_output=True, text=True, check=True
    )
    definition = json.loads(result.stdout)[0]['sql']
    
    # 2. Save backup
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    with open(f'backup_{view_name}_{timestamp}.sql', 'w') as f:
        f.write(definition)
    
    # 3. Drop view
    subprocess.run(['dbcli', 'ddl', 
                    f'DROP VIEW IF EXISTS {view_name}'], check=True)
    print(f"✅ View {view_name} dropped (backup saved)")

def list_views():
    """Get all views in database"""
    result = subprocess.run(
        ['dbcli', 'query',
         "SELECT name FROM sqlite_master WHERE type='view'"],
        capture_output=True, text=True, check=True
    )
    return json.loads(result.stdout)

# Usage
create_view('ActiveUsers', 'SELECT * FROM Users WHERE status="active"')
print('Views:', list_views())
drop_view_safely('OldReport')
```

---

### PowerShell

```powershell
# Set connection
$env:DBCLI_CONNECTION = "Data Source=app.db"

# Create a view
function New-DbView {
    param(
        [string]$ViewName,
        [string]$Query
    )
    
    $sql = "CREATE VIEW $ViewName AS $Query"
    dbcli ddl $sql
    Write-Host "✅ View $ViewName created" -ForegroundColor Green
}

# Drop view with backup
function Remove-DbViewSafely {
    param([string]$ViewName)
    
    # 1. Export view definition
    $definition = dbcli query "SELECT sql FROM sqlite_master WHERE type='view' AND name='$ViewName'"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $definition | Out-File "backup_${ViewName}_${timestamp}.sql"
    
    # 2. Drop view
    dbcli ddl "DROP VIEW IF EXISTS $ViewName"
    Write-Host "✅ View $ViewName dropped (backup saved)" -ForegroundColor Green
}

# List all views
function Get-DbViews {
    $result = dbcli query "SELECT name FROM sqlite_master WHERE type='view'" | ConvertFrom-Json
    return $result
}

# Usage
New-DbView -ViewName "ActiveUsers" -Query "SELECT * FROM Users WHERE status='active'"
Get-DbViews
Remove-DbViewSafely -ViewName "OldReport"
```

---

## Safety Best Practices

### ⚠️ Before Dropping Views

1. **Export view definition**:
   ```bash
   dbcli query "SELECT sql FROM sqlite_master WHERE type='view' AND name='ViewName'" > backup.sql
   ```

2. **Check for dependencies**:
   - Other views might reference this view
   - Application code might query this view
   - Reports or dashboards might depend on it

3. **Test in development first**:
   ```bash
   # Test environment
   export DBCLI_CONNECTION="Data Source=test.db"
   dbcli ddl "DROP VIEW TestView"
   
   # Then production
   export DBCLI_CONNECTION="Data Source=prod.db"
   dbcli ddl "DROP VIEW TestView"
   ```

### 🛡️ View Management Checklist

- [ ] Export view definition before dropping
- [ ] Check for dependent views or procedures
- [ ] Test view creation in development environment
- [ ] Document view purpose and columns
- [ ] Use naming conventions (e.g., `vw_`, `v_` prefix)
- [ ] Review view performance (explain query plan)

---

## Advanced Patterns

### Materialized Views (Database-Specific)

#### PostgreSQL
```bash
export DBCLI_CONNECTION="Host=localhost;Database=mydb"

# Create materialized view
dbcli -t postgresql ddl "
CREATE MATERIALIZED VIEW monthly_sales AS
SELECT DATE_TRUNC('month', sale_date) as month, SUM(amount) as total
FROM sales
GROUP BY DATE_TRUNC('month', sale_date)"

# Refresh materialized view
dbcli -t postgresql ddl "
REFRESH MATERIALIZED VIEW monthly_sales"
```

#### Oracle
```bash
export DBCLI_CONNECTION="Data Source=orcl"

# Create materialized view
dbcli -t oracle ddl "
CREATE MATERIALIZED VIEW mv_sales_summary
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
AS SELECT region, SUM(amount) FROM sales GROUP BY region"

# Refresh
dbcli -t oracle exec "
BEGIN DBMS_MVIEW.REFRESH('MV_SALES_SUMMARY'); END;"
```

### Indexed Views (SQL Server)

```bash
export DBCLI_CONNECTION="Server=.;Database=mydb"

# Create view with schema binding (required for indexing)
dbcli -t sqlserver ddl "
CREATE VIEW dbo.SalesSummary
WITH SCHEMABINDING
AS
SELECT ProductID, COUNT_BIG(*) as OrderCount, SUM(Quantity) as TotalQuantity
FROM dbo.OrderDetails
GROUP BY ProductID"

# Create unique clustered index on view
dbcli -t sqlserver ddl "
CREATE UNIQUE CLUSTERED INDEX IX_SalesSummary_ProductID 
ON dbo.SalesSummary(ProductID)"
```

---

## Troubleshooting

### Common Errors

#### "View already exists"
```bash
# Use IF NOT EXISTS or OR REPLACE
dbcli ddl "CREATE VIEW IF NOT EXISTS MyView AS SELECT * FROM Users"
dbcli ddl "CREATE OR REPLACE VIEW MyView AS SELECT * FROM Users"
```

#### "Invalid column reference"
```bash
# Check that all referenced tables and columns exist
dbcli query "PRAGMA table_info(Users)"  # SQLite
dbcli query "DESCRIBE Users" -t mysql   # MySQL
```

#### "Insufficient privileges"
```bash
# Ensure user has CREATE VIEW permission
# SQL Server
dbcli query "SELECT HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CREATE VIEW')" -t sqlserver
```

---

## Related Skills

- **[dbcli-query](../dbcli-query/)** - Query views like tables
- **[dbcli-db-ddl](../dbcli-db-ddl/)** - Manage table structures
- **[dbcli-index](../dbcli-index/)** - Manage indexes
- **[dbcli-procedure](../dbcli-procedure/)** - Manage stored procedures

---

## Database-Specific Notes

| Database | CREATE OR REPLACE | Materialized Views | Indexed Views |
|----------|-------------------|--------------------|--------------------|
| SQLite | ❌ (Use DROP + CREATE) | ❌ | ❌ |
| SQL Server | ✅ (2016+) | ❌ | ✅ (Indexed Views) |
| MySQL | ✅ | ❌ | ❌ |
| PostgreSQL | ✅ | ✅ | ❌ |
| Oracle | ✅ | ✅ | ❌ |
| DaMeng | ✅ | ✅ | ❌ |
| GaussDB | ✅ | ✅ | ❌ |
| KingbaseES | ✅ | ✅ | ❌ |

---

## Connection String Reference

See [CONNECTION_STRINGS.md](../CONNECTION_STRINGS.md) for 30+ database connection string examples.

---

## Support

For issues and questions:
- GitHub Issues: https://github.com/your-repo/dbcli/issues
- Documentation: https://github.com/your-repo/dbcli

---

**License**: MIT  
**Version**: 1.0.0

# DbCli Index Management Skill

---
name: dbcli-index
description: Manage database indexes (CREATE/DROP INDEX operations)
version: 1.0.0
category: database
tags: [dbcli, sql, indexes, performance, ddl, database]
safety_level: moderate
requires_backup: recommended
compatible_with:
  - github_copilot
  - openai_codex
  - claude_code
  - gemini_cli
  - cline
  - roo
  - kilo
metadata:
  author: dbcli
  license: MIT
  repository: https://github.com/your-repo/dbcli
---


## Command Style (Use PATH)

All examples use the plain command name `dbcli` (no directory prefix).
Ensure `dbcli` is on PATH instead of hardcoding paths like `.\.claude\skills\dbcli\dbcli.exe`.


## Overview

Manage database indexes using DbCli's DDL command. This skill covers creating, analyzing, and dropping indexes to optimize query performance across 30+ database systems.

**Safety Level**: Moderate  
**Requires Backup**: Recommended before dropping indexes on production

## Quick Start

```bash
# ⚠️ IMPORTANT: Backup indexes before DROP operations
# Backup all indexes
dbcli -c "Data Source=app.db" export-schema index -o backup_indexes.sql

# Create an index
dbcli -c "Data Source=app.db" ddl "CREATE INDEX idx_users_email ON Users(email)"

# Create a unique index
dbcli -c "Data Source=app.db" ddl "CREATE UNIQUE INDEX idx_users_username ON Users(username)"

# Drop an index (with backup)
dbcli -c "Data Source=app.db" ddl "DROP INDEX idx_old_index"

# Restore from backup if needed
# Execute the CREATE INDEX statement from backup_indexes.sql

# List all indexes
dbcli -c "Data Source=app.db" query "SELECT name FROM sqlite_master WHERE type='index'" -f table
```

---

## Command Syntax

```bash
dbcli [options] ddl "<INDEX_DDL_STATEMENT>"
```

### Options

| Option | Alias | Description | Example |
|--------|-------|-------------|---------|
| `--connection` | `-c` | Connection string | `-c "Server=localhost;Database=mydb"` |
| `--db-type` | `-t` | Database type | `-t sqlserver`, `-t mysql` |
| `--format` | `-f` | Output format | `-f json`, `-f table` |
| `--file` | `-F` | Read SQL from file | `-F create_indexes.sql` |
| `--config` | | Use config file | `--config appsettings.json` |

---

## Core Operations

### 1. Create Single-Column Index

#### SQLite
```bash
# Simple index
dbcli -c "Data Source=app.db" ddl "CREATE INDEX idx_users_email ON Users(email)"

# Unique index
dbcli -c "Data Source=app.db" ddl "CREATE UNIQUE INDEX idx_users_username ON Users(username)"

# Index with IF NOT EXISTS
dbcli -c "Data Source=app.db" ddl "CREATE INDEX IF NOT EXISTS idx_users_status ON Users(status)"
```

#### SQL Server
```bash
# Nonclustered index
dbcli -c "Server=.;Database=mydb;Trusted_Connection=True" -t sqlserver ddl "
CREATE NONCLUSTERED INDEX IX_Customers_Email 
ON dbo.Customers(Email)"

# Unique index
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE UNIQUE INDEX IX_Products_SKU 
ON dbo.Products(SKU)"

# Clustered index
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE CLUSTERED INDEX IX_Orders_OrderDate 
ON dbo.Orders(OrderDate)"
```

#### MySQL
```bash
# Simple index
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx" -t mysql ddl "
CREATE INDEX idx_users_email ON Users(email)"

# Unique index
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
CREATE UNIQUE INDEX idx_users_username ON Users(username)"

# FULLTEXT index (MyISAM/InnoDB)
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
CREATE FULLTEXT INDEX idx_articles_content ON Articles(content)"
```

#### PostgreSQL
```bash
# B-tree index (default)
dbcli -c "Host=localhost;Database=mydb;Username=postgres;Password=xxxxxxxxxx" -t postgresql ddl "
CREATE INDEX idx_users_email ON users(email)"

# Unique index
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE UNIQUE INDEX idx_users_username ON users(username)"

# Partial index
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE INDEX idx_active_users ON users(email) WHERE status = 'active'"

# Index with specific method
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE INDEX idx_users_name_gin ON users USING gin(to_tsvector('english', name))"
```

#### Oracle
```bash
# Simple index
dbcli -c "Data Source=orcl;User Id=system;Password=xxxxxxxxxx" -t oracle ddl "
CREATE INDEX idx_employees_email ON employees(email)"

# Unique index
dbcli -c "Data Source=orcl" -t oracle ddl "
CREATE UNIQUE INDEX idx_employees_emp_no ON employees(employee_number)"

# Function-based index
dbcli -c "Data Source=orcl" -t oracle ddl "
CREATE INDEX idx_employees_upper_name ON employees(UPPER(name))"
```

#### DaMeng (达梦)
```bash
dbcli -c "Server=localhost;User Id=SYSDBA;PWD=xxxxxxxxxx;DATABASE=mydb" -t dm ddl "
CREATE INDEX idx_orders_customer ON orders(customer_id)"

# Unique index
dbcli -c "Server=localhost;User Id=SYSDBA;PWD=xxxxxxxxxx" -t dm ddl "
CREATE UNIQUE INDEX idx_products_code ON products(product_code)"
```

#### GaussDB
```bash
dbcli -c "Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=xxxxxxxxxx" -t gaussdb ddl "
CREATE INDEX idx_sales_date ON sales(sale_date)"

# Partial index
dbcli -c "Host=localhost;Database=mydb" -t gaussdb ddl "
CREATE INDEX idx_high_value_sales ON sales(amount) WHERE amount > 1000"
```

#### KingbaseES (人大金仓)
```bash
dbcli -c "Server=localhost;Port=54321;Database=mydb;UID=system;PWD=xxxxxxxxxx" -t kdbndp ddl "
CREATE INDEX idx_inventory_product ON inventory(product_id)"

# Unique index
dbcli -c "Server=localhost;Database=mydb" -t kdbndp ddl "
CREATE UNIQUE INDEX idx_inventory_sku ON inventory(sku)"
```

---

### 2. Create Composite Index (Multiple Columns)

#### SQLite
```bash
dbcli -c "Data Source=app.db" ddl "
CREATE INDEX idx_users_status_created ON Users(status, created_at)"
```

#### SQL Server
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE INDEX IX_Orders_CustomerDate 
ON dbo.Orders(CustomerID, OrderDate) 
INCLUDE (TotalAmount)"
```

#### MySQL
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
CREATE INDEX idx_orders_customer_date ON Orders(customer_id, order_date)"
```

#### PostgreSQL
```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date DESC)"
```

#### Oracle
```bash
dbcli -c "Data Source=orcl" -t oracle ddl "
CREATE INDEX idx_orders_comp ON orders(customer_id, order_date, status)"
```

---

### 3. Create Filtered/Partial Index

#### SQL Server (Filtered Index)
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE INDEX IX_Orders_Active 
ON dbo.Orders(OrderDate) 
WHERE Status = 'Active'"
```

#### PostgreSQL (Partial Index)
```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE INDEX idx_pending_orders 
ON orders(created_at) 
WHERE status = 'pending'"
```

#### Oracle (Function-Based Index)
```bash
dbcli -c "Data Source=orcl" -t oracle ddl "
CREATE INDEX idx_active_orders 
ON orders(order_date) 
WHERE status = 'ACTIVE'"
```

---

### 4. Create Full-Text Index

#### SQL Server
```bash
# Create full-text catalog (required first)
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT"

# Create full-text index
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE FULLTEXT INDEX ON dbo.Articles(content) 
KEY INDEX PK_Articles"
```

#### MySQL
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
CREATE FULLTEXT INDEX idx_articles_fulltext 
ON Articles(title, content)"
```

#### PostgreSQL (GIN Index for Full-Text)
```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE INDEX idx_documents_fulltext 
ON documents 
USING gin(to_tsvector('english', content))"
```

---

### 5. Drop Index

⚠️ **WARNING**: Dropping indexes can severely impact query performance. Analyze queries first!

#### SQLite
```bash
dbcli -c "Data Source=app.db" ddl "DROP INDEX IF EXISTS idx_old_index"
```

#### SQL Server
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
DROP INDEX IF EXISTS IX_OldIndex ON dbo.TableName"
```

#### MySQL
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
DROP INDEX idx_old_index ON TableName"
```

#### PostgreSQL
```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
DROP INDEX IF EXISTS idx_old_index CASCADE"
```

#### Oracle
```bash
dbcli -c "Data Source=orcl" -t oracle ddl "
DROP INDEX idx_old_index"
```

---

### 6. List Indexes

#### SQLite
```bash
# All indexes
dbcli -c "Data Source=app.db" query "
SELECT name, tbl_name, sql 
FROM sqlite_master 
WHERE type='index' 
ORDER BY tbl_name, name" -f table

# Indexes for specific table
dbcli -c "Data Source=app.db" query "
PRAGMA index_list('Users')" -f table

# Index details
dbcli -c "Data Source=app.db" query "
PRAGMA index_info('idx_users_email')" -f table
```

#### SQL Server
```bash
# All indexes in database
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT 
    OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key
FROM sys.indexes i
WHERE i.object_id > 100
ORDER BY schema_name, table_name, index_name" -f table

# Indexes for specific table
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT 
    i.name AS index_name,
    COL_NAME(ic.object_id, ic.column_id) AS column_name,
    ic.index_column_id,
    ic.is_included_column
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('dbo.Users')
ORDER BY i.name, ic.index_column_id" -f table

# Index usage statistics
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT 
    OBJECT_NAME(s.object_id) AS table_name,
    i.name AS index_name,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE database_id = DB_ID()
ORDER BY s.user_seeks DESC" -f table
```

#### MySQL
```bash
# All indexes in database
dbcli -c "Server=localhost;Database=mydb" -t mysql query "
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'mydb'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX" -f table

# Indexes for specific table
dbcli -c "Server=localhost;Database=mydb" -t mysql query "
SHOW INDEX FROM Users" -f table
```

#### PostgreSQL
```bash
# All indexes in schema
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname" -f table

# Indexes for specific table
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "
SELECT
    i.relname AS index_name,
    a.attname AS column_name,
    am.amname AS index_type,
    ix.indisunique AS is_unique,
    ix.indisprimary AS is_primary
FROM pg_class t
JOIN pg_index ix ON t.oid = ix.indrelid
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_attribute a ON a.attrelid = t.oid
JOIN pg_am am ON i.relam = am.oid
WHERE t.relname = 'users'
    AND a.attnum = ANY(ix.indkey)
ORDER BY i.relname, a.attnum" -f table

# Index size
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC" -f table
```

#### Oracle
```bash
# All indexes for user
dbcli -c "Data Source=orcl" -t oracle query "
SELECT index_name, table_name, uniqueness, status
FROM user_indexes
ORDER BY table_name, index_name" -f table

# Index columns
dbcli -c "Data Source=orcl" -t oracle query "
SELECT index_name, column_name, column_position
FROM user_ind_columns
WHERE table_name = 'EMPLOYEES'
ORDER BY index_name, column_position" -f table
```

---

### 7. Analyze Index Performance

#### SQL Server (Missing Index Suggestions)
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT 
    CONVERT(decimal(28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS improvement_measure,
    'CREATE INDEX idx_' + CONVERT(varchar, mig.index_group_handle) + '_' + 
    CONVERT(varchar, mid.index_handle) + ' ON ' + mid.statement + ' (' + 
    ISNULL(mid.equality_columns,'') + 
    CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END + 
    ISNULL(mid.inequality_columns, '') + ')' + 
    ISNULL(' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) > 10
ORDER BY improvement_measure DESC" -f table
```

#### PostgreSQL (Unused Indexes)
```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
    AND indexrelname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC" -f table
```

#### MySQL (Index Cardinality)
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql query "
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    CARDINALITY,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'mydb'
    AND CARDINALITY IS NOT NULL
ORDER BY TABLE_NAME, INDEX_NAME" -f table
```

---

## Code Integration Examples

### Node.js / JavaScript

```javascript
const { execSync } = require('child_process');

// Create index
function createIndex(table, column, indexName = null) {
  const name = indexName || `idx_${table}_${column}`;
  execSync(`dbcli -c "Data Source=app.db" ddl "CREATE INDEX ${name} ON ${table}(${column})"`);
  console.log(`✅ Index ${name} created`);
}

// Create composite index
function createCompositeIndex(table, columns, indexName = null) {
  const columnList = columns.join(', ');
  const name = indexName || `idx_${table}_${columns.join('_')}`;
  execSync(`dbcli -c "Data Source=app.db" ddl "CREATE INDEX ${name} ON ${table}(${columnList})"`);
  console.log(`✅ Composite index ${name} created`);
}

// Drop index
function dropIndex(indexName) {
  execSync(`dbcli -c "Data Source=app.db" ddl "DROP INDEX IF EXISTS ${indexName}"`);
  console.log(`✅ Index ${indexName} dropped`);
}

// List all indexes
function listIndexes() {
  const result = JSON.parse(
    execSync('dbcli -c "Data Source=app.db" query "SELECT name, tbl_name FROM sqlite_master WHERE type=\'index\'"').toString()
  );
  return result;
}

// Get indexes for specific table
function getTableIndexes(tableName) {
  const result = JSON.parse(
    execSync(`dbcli -c "Data Source=app.db" query "PRAGMA index_list('${tableName}')"`).toString()
  );
  return result;
}

// Usage
createIndex('Users', 'email');
createCompositeIndex('Orders', ['customer_id', 'order_date']);
console.log('All indexes:', listIndexes());
console.log('Users indexes:', getTableIndexes('Users'));
dropIndex('idx_old_index');
```

---

### Python

```python
import subprocess
import json

def create_index(table: str, column: str, index_name: str = None, unique: bool = False):
    """Create a database index"""
    name = index_name or f"idx_{table}_{column}"
    unique_clause = "UNIQUE " if unique else ""
    sql = f"CREATE {unique_clause}INDEX {name} ON {table}({column})"
    subprocess.run(['dbcli', '-c', 'Data Source=app.db', 'ddl', sql], check=True)
    print(f"✅ Index {name} created")

def create_composite_index(table: str, columns: list, index_name: str = None):
    """Create a composite index"""
    column_list = ', '.join(columns)
    name = index_name or f"idx_{table}_{'_'.join(columns)}"
    sql = f"CREATE INDEX {name} ON {table}({column_list})"
    subprocess.run(['dbcli', '-c', 'Data Source=app.db', 'ddl', sql], check=True)
    print(f"✅ Composite index {name} created")

def drop_index(index_name: str):
    """Drop an index"""
    sql = f"DROP INDEX IF EXISTS {index_name}"
    subprocess.run(['dbcli', '-c', 'Data Source=app.db', 'ddl', sql], check=True)
    print(f"✅ Index {index_name} dropped")

def list_indexes():
    """Get all indexes in database"""
    result = subprocess.run(
        ['dbcli', '-c', 'Data Source=app.db', 'query',
         "SELECT name, tbl_name FROM sqlite_master WHERE type='index'"],
        capture_output=True, text=True, check=True
    )
    return json.loads(result.stdout)

def get_table_indexes(table_name: str):
    """Get indexes for specific table"""
    result = subprocess.run(
        ['dbcli', '-c', 'Data Source=app.db', 'query',
         f"PRAGMA index_list('{table_name}')"],
        capture_output=True, text=True, check=True
    )
    return json.loads(result.stdout)

# Usage
create_index('Users', 'email', unique=True)
create_composite_index('Orders', ['customer_id', 'order_date'])
print('All indexes:', list_indexes())
print('Users indexes:', get_table_indexes('Users'))
drop_index('idx_old_index')
```

---

### PowerShell

```powershell
# Create index
function New-DbIndex {
    param(
        [string]$Table,
        [string]$Column,
        [string]$IndexName = $null,
        [switch]$Unique
    )
    
    $name = if ($IndexName) { $IndexName } else { "idx_${Table}_${Column}" }
    $uniqueClause = if ($Unique) { "UNIQUE " } else { "" }
    $sql = "CREATE ${uniqueClause}INDEX $name ON $Table($Column)"
    
    dbcli -c "Data Source=app.db" ddl $sql
    Write-Host "✅ Index $name created" -ForegroundColor Green
}

# Create composite index
function New-DbCompositeIndex {
    param(
        [string]$Table,
        [string[]]$Columns,
        [string]$IndexName = $null
    )
    
    $columnList = $Columns -join ', '
    $name = if ($IndexName) { $IndexName } else { "idx_${Table}_$($Columns -join '_')" }
    $sql = "CREATE INDEX $name ON $Table($columnList)"
    
    dbcli -c "Data Source=app.db" ddl $sql
    Write-Host "✅ Composite index $name created" -ForegroundColor Green
}

# Drop index
function Remove-DbIndex {
    param([string]$IndexName)
    
    dbcli -c "Data Source=app.db" ddl "DROP INDEX IF EXISTS $IndexName"
    Write-Host "✅ Index $IndexName dropped" -ForegroundColor Green
}

# List all indexes
function Get-DbIndexes {
    $result = dbcli -c "Data Source=app.db" query "SELECT name, tbl_name FROM sqlite_master WHERE type='index'" | ConvertFrom-Json
    return $result
}

# Get table indexes
function Get-DbTableIndexes {
    param([string]$TableName)
    
    $result = dbcli -c "Data Source=app.db" query "PRAGMA index_list('$TableName')" | ConvertFrom-Json
    return $result
}

# Usage
New-DbIndex -Table "Users" -Column "email" -Unique
New-DbCompositeIndex -Table "Orders" -Columns @("customer_id", "order_date")
Get-DbIndexes
Get-DbTableIndexes -TableName "Users"
Remove-DbIndex -IndexName "idx_old_index"
```

---

## Best Practices

### ✅ When to Create Indexes

1. **Columns in WHERE clauses**:
   ```sql
   SELECT * FROM Orders WHERE customer_id = 123  -- Index customer_id
   ```

2. **Columns in JOIN conditions**:
   ```sql
   SELECT * FROM Orders o JOIN Customers c ON o.customer_id = c.id  -- Index customer_id
   ```

3. **Columns in ORDER BY**:
   ```sql
   SELECT * FROM Orders ORDER BY order_date DESC  -- Index order_date
   ```

4. **Foreign key columns**:
   ```sql
   CREATE INDEX idx_orders_customer ON Orders(customer_id)
   ```

5. **Columns used in GROUP BY**:
   ```sql
   SELECT customer_id, COUNT(*) FROM Orders GROUP BY customer_id  -- Index customer_id
   ```

### ⚠️ When NOT to Create Indexes

1. **Small tables** (< 1000 rows) - full table scan is faster
2. **Frequently updated columns** - index maintenance overhead
3. **Low cardinality columns** - columns with few distinct values
4. **Wide columns** - large text or binary data

### 🎯 Index Naming Conventions

```
idx_<table>_<column1>[_<column2>]       # General index
pk_<table>                               # Primary key
uk_<table>_<column>                      # Unique constraint
fk_<table1>_<table2>                     # Foreign key
```

### 📊 Monitor Index Usage

Before dropping an index, check if it's being used:

```bash
# SQL Server - Check index usage
dbcli query "
SELECT 
    i.name,
    s.user_seeks + s.user_scans + s.user_lookups AS reads,
    s.user_updates AS writes
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE OBJECT_NAME(i.object_id) = 'YourTable'" -t sqlserver

# PostgreSQL - Check index usage
dbcli query "
SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'" -t postgresql
```

---

## Advanced Patterns

### Covering Indexes (SQL Server)

```bash
# Index with INCLUDE columns (non-key columns)
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE INDEX IX_Orders_Customer 
ON Orders(customer_id, order_date) 
INCLUDE (total_amount, status)"
```

### Filtered Indexes

```bash
# SQL Server - Index only active records
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE INDEX IX_Active_Orders 
ON Orders(order_date) 
WHERE status = 'active'"

# PostgreSQL - Partial index
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE INDEX idx_pending_orders 
ON orders(created_at) 
WHERE status = 'pending'"
```

### Index Maintenance

#### SQL Server - Rebuild Index
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
ALTER INDEX IX_Orders_Customer ON Orders REBUILD"
```

#### SQL Server - Reorganize Index
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
ALTER INDEX IX_Orders_Customer ON Orders REORGANIZE"
```

#### PostgreSQL - Rebuild Index
```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
REINDEX INDEX idx_orders_customer"
```

#### MySQL - Rebuild Table Indexes
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
OPTIMIZE TABLE Orders"
```

---

## Troubleshooting

### Common Errors

#### "Index already exists"
```bash
# Use IF NOT EXISTS
dbcli ddl "CREATE INDEX IF NOT EXISTS idx_name ON table(column)"
```

#### "Cannot create index on this column type"
```bash
# Some databases don't support indexing TEXT/BLOB columns directly
# Use a computed column or full-text index instead
```

#### "Unique constraint violation"
```bash
# Check for duplicate values before creating unique index
dbcli query "SELECT column, COUNT(*) FROM table GROUP BY column HAVING COUNT(*) > 1"
```

---

## Performance Tips

1. **Create indexes during off-peak hours** - index creation locks tables
2. **Use composite indexes wisely** - column order matters!
3. **Monitor index fragmentation** - rebuild fragmented indexes
4. **Remove unused indexes** - they slow down INSERT/UPDATE/DELETE
5. **Use covering indexes** - include SELECT columns in index
6. **Consider partitioning** - for very large tables

---

## Related Skills

- **[dbcli-query](../dbcli-query/)** - Analyze query performance
- **[dbcli-db-ddl](../dbcli-db-ddl/)** - Create tables with indexes
- **[dbcli-view](../dbcli-view/)** - Manage views
- **[dbcli-procedure](../dbcli-procedure/)** - Optimize stored procedures

---

## Database-Specific Index Types

| Database | B-Tree | Hash | GiST | GIN | BRIN | Full-Text |
|----------|--------|------|------|-----|------|-----------|
| SQLite | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| SQL Server | ✅ (Clustered/Nonclustered) | ✅ | ❌ | ❌ | ❌ | ✅ |
| MySQL | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ |
| PostgreSQL | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (GIN) |
| Oracle | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ (Oracle Text) |

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

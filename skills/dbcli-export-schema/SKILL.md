---
name: dbcli-export-schema
description: Export database schema objects (procedures, functions, triggers, views, indexes) as SQL scripts for backup
license: MIT
compatibility: Requires DbCli CLI tool (based on .NET 10 and SqlSugar). Supports Windows, Linux, macOS.
metadata:
  tool: dbcli
  version: "1.0.0"
  category: database
  supported-databases: "30+"
  operation-type: backup-export-schema
  safety-level: safe
  requires-backup: no
  tags: [dbcli, sql, backup, schema, ddl, export, procedures, functions, triggers, views, indexes]
  repository: https://github.com/your-repo/dbcli
allowed-tools: dbcli
---


# DbCli Schema Export Skill

## Command Style (Use PATH)

All examples use the plain command name `dbcli` (no directory prefix).
Ensure `dbcli` is on PATH instead of hardcoding paths like `.\.claude\skills\dbcli\dbcli.exe`.


## Overview

Export database schema objects (stored procedures, functions, triggers, views, indexes) as SQL DDL scripts for backup and recovery. This skill is essential for protecting database objects before DROP or ALTER operations.

**Safety Level**: Safe (read-only operation)  
**Requires Backup**: No (this tool creates backups)

## Quick Start

```bash
# Export all schema objects
export DBCLI_CONNECTION="Server=.;Database=mydb"
export DBCLI_DBTYPE="sqlserver"
dbcli export-schema all -o backup_schema.sql

# Export all schema objects as separate files (per object)
dbcli export-schema all --output-dir ./schema_export

# Export only stored procedures
dbcli export-schema procedure -o backup_procedures.sql

# Export only indexes
export DBCLI_CONNECTION="Data Source=app.db"
dbcli export-schema index -o backup_indexes.sql

# Export only triggers
dbcli export-schema trigger -o backup_triggers.sql

# Filter by name pattern
export DBCLI_CONNECTION="Server=.;Database=mydb"
export DBCLI_DBTYPE="sqlserver"
dbcli export-schema procedure --name "sp_User*"
```

---

## Command Syntax

### Basic Usage
```bash
# Set environment variables first:
# export DBCLI_CONNECTION="connection-string"
# export DBCLI_DBTYPE="database-type"

dbcli export-schema <type> [options]
```

### Arguments
- `<type>` - Object type to export:
  - `all` - All schema objects (default)
  - `procedure` - Stored procedures
  - `function` - User-defined functions
  - `trigger` - Triggers
  - `view` - Views
  - `index` - Indexes

### Options
- `-n, --name <pattern>` - Filter objects by name (supports wildcards)
- `-o, --output <file>` - Save to file (default: console output)
- `--output-dir <dir>` - Save as separate files under a directory (one file per object)

### Connection Options
- Environment variables:
  - `DBCLI_CONNECTION`: Database connection string
  - `DBCLI_DBTYPE`: Database type
- `-t, --db-type <type>` - Database type (sqlite, sqlserver, mysql, postgresql, etc.)
- `--config <path>` - Configuration file path

---

## Examples

### SQLite

```bash
export DBCLI_CONNECTION="Data Source=app.db"

# Export all triggers
dbcli export-schema trigger

# Export all indexes to file
dbcli export-schema index -o backup_indexes.sql

# Export all schema objects
dbcli export-schema all -o backup_all.sql
```

### SQL Server

```bash
export DBCLI_CONNECTION="Server=.;Database=mydb;Trusted_Connection=True"
export DBCLI_DBTYPE="sqlserver"

# Export all stored procedures
dbcli export-schema procedure -o procedures_backup.sql

# Export specific procedures
dbcli export-schema procedure --name "sp_User*" -o user_procedures.sql

# Export all functions
dbcli export-schema function -o functions_backup.sql

# Export all triggers
dbcli export-schema trigger -o triggers_backup.sql
```

### MySQL

```bash
export DBCLI_CONNECTION="Server=localhost;Database=mydb;Uid=root;Pwd=xxxxxxxxxx"
export DBCLI_DBTYPE="mysql"

# Export all procedures
dbcli export-schema procedure -o procedures.sql

# Export all triggers
dbcli export-schema trigger -o triggers.sql

# Export all indexes
dbcli export-schema index -o indexes.sql
```

### PostgreSQL

```bash
export DBCLI_CONNECTION="Host=localhost;Database=mydb;Username=postgres;Password=xxxxxxxxxx"
export DBCLI_DBTYPE="postgresql"

# Export all functions
dbcli export-schema function -o functions.sql

# Export all triggers
dbcli export-schema trigger -o triggers.sql

# Export all views
dbcli export-schema view -o views.sql
```

---

## Use Cases

### 1. Pre-deployment Backup

```bash
# Backup all schema objects before deployment
# If appsettings.json is in the current working directory, DbCli auto-loads it
dbcli export-schema all -o "backup_$(date +%Y%m%d_%H%M%S).sql"
```

### 2. Procedure Refactoring

```bash
export DBCLI_CONNECTION="Server=.;Database=mydb"
export DBCLI_DBTYPE="sqlserver"

# 1. Backup existing procedures
dbcli export-schema procedure -o old_procedures.sql

# 2. Drop and recreate procedures
dbcli ddl "DROP PROCEDURE sp_OldProc"
dbcli ddl "CREATE PROCEDURE sp_NewProc..."

# 3. Rollback if needed (execute old_procedures.sql)
```

### 3. Index Optimization

```bash
export DBCLI_CONNECTION="Data Source=app.db"

# 1. Backup current indexes
dbcli export-schema index -o indexes_before.sql

# 2. Drop inefficient indexes
dbcli ddl "DROP INDEX idx_slow"

# 3. Create optimized indexes
dbcli ddl "CREATE INDEX idx_fast ON Table(col1, col2)"

# 4. Export new indexes
dbcli export-schema index -o indexes_after.sql
```

### 4. Database Migration

```bash
# Export all schema from source database
export DBCLI_CONNECTION="Server=source;Database=db"
export DBCLI_DBTYPE="sqlserver"
dbcli export-schema all -o schema_export.sql

# Review and edit schema_export.sql if needed

# Apply to target database
# Execute the SQL scripts manually or via dbcli ddl command
```

### 5. Continuous Backup Script

```bash
#!/bin/bash
# backup_schema.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./schema_backups"

mkdir -p $BACKUP_DIR

# Backup all schema objects
dbcli --config production.json \
  export-schema all \
  -o "$BACKUP_DIR/schema_${TIMESTAMP}.sql"

echo "Schema backed up to: $BACKUP_DIR/schema_${TIMESTAMP}.sql"

# Keep only last 30 days of backups
find $BACKUP_DIR -name "schema_*.sql" -mtime +30 -delete
```

---

## Complete Backup & Restore Workflow

### Backup Before DROP

```bash
# Step 1: Export schema object
export DBCLI_CONNECTION="Data Source=app.db"
dbcli export-schema trigger -o backup_triggers.sql

# Step 2: Review backup file
cat backup_triggers.sql

# Step 3: Perform dangerous operation
dbcli ddl "DROP TRIGGER update_timestamp"

# Step 4: Verify deletion
dbcli export-schema trigger
# (should show no triggers)
```

### Restore from Backup

```bash
# Method 1: Extract and execute CREATE statement
TRIGGER_SQL=$(grep -A 10 "CREATE TRIGGER" backup_triggers.sql | sed '/^GO$/q')
dbcli ddl "$TRIGGER_SQL"

# Method 2: Execute entire backup file (if single object)
dbcli ddl -F backup_triggers.sql

# Verify restoration
dbcli export-schema trigger
```

---

## Output Format

The exported SQL script includes:

```sql
-- Schema Export for <DatabaseType>
-- Generated: YYYY-MM-DD HH:MM:SS
-- Object Type: <type>

-- ========================================
-- Stored Procedures
-- ========================================

-- Procedure: ProcedureName
CREATE PROCEDURE ProcedureName...
GO

-- ========================================
-- User Functions
-- ========================================

-- Function: FunctionName
CREATE FUNCTION FunctionName...
GO

-- ========================================
-- Triggers
-- ========================================

-- Trigger: TriggerName
CREATE TRIGGER TriggerName...
GO

-- ========================================
-- Views
-- ========================================

-- View: ViewName
CREATE VIEW ViewName...
GO

-- ========================================
-- Indexes
-- ========================================

-- Indexes for table: TableName
CREATE INDEX IndexName ON TableName(Column);
```

---

## Database Support

| Database | Procedures | Functions | Triggers | Views | Indexes |
|----------|------------|-----------|----------|-------|---------|
| SQL Server | ✅ | ✅ | ✅ | ✅ | ✅ |
| MySQL | ✅ | ✅ | ✅ | ✅ | ✅ |
| PostgreSQL | ✅ | ✅ | ✅ | ✅ | ✅ |
| SQLite | ❌ | ❌ | ✅ | ✅ | ✅ |
| Oracle | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Others | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |

Legend:
- ✅ Fully supported
- ⚠️ Partial support (may vary)
- ❌ Not supported

---

## Best Practices

### 1. Always Backup Before DROP

```bash
# ❌ BAD: Drop without backup
dbcli ddl "DROP PROCEDURE sp_ImportantLogic"

# ✅ GOOD: Backup first
export DBCLI_CONNECTION="..."
dbcli export-schema procedure --name "sp_ImportantLogic" -o backup.sql
dbcli ddl "DROP PROCEDURE sp_ImportantLogic"
```

### 2. Use Timestamped Backups

```bash
# Create timestamped backup files
export DBCLI_CONNECTION="..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
dbcli export-schema all -o "schema_backup_${TIMESTAMP}.sql"
```

### 3. Store Backups in Version Control

```bash
# Export to version-controlled directory
export DBCLI_CONNECTION="..."
dbcli export-schema all -o "database/schema/procedures.sql"
git add database/schema/procedures.sql
git commit -m "Backup procedures before refactoring"
```

### 4. Automate Daily Backups

```bash
# Add to crontab (Linux) or Task Scheduler (Windows)
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/dbcli --config /etc/dbcli.json export-schema all -o /backups/schema_$(date +\%Y\%m\%d).sql
```

### 5. Test Restore Procedures

```bash
# Periodically test that backups can be restored
export DBCLI_CONNECTION="..."
dbcli export-schema trigger -o test_backup.sql
dbcli ddl "DROP TRIGGER test_trigger"
# Restore from backup...
# Verify restoration works
```

---

## Error Handling

### Common Errors

1. **Connection Failed**
   ```
   Error: Unable to connect to database
   ```
   - Check connection string
   - Verify database type (`-t` option)
   - Ensure database server is running

2. **No Objects Found**
   ```
   -- Stored Procedures
   -- (empty)
   ```
   - Normal if no objects exist
   - Check database type compatibility
   - Verify name filter pattern

3. **Permission Denied**
   ```
   Error: Permission denied to read schema
   ```
   - Ensure database user has SELECT permissions on system tables
   - SQL Server: SELECT on sys.procedures, sys.sql_modules
   - MySQL: SELECT on INFORMATION_SCHEMA.ROUTINES
   - PostgreSQL: SELECT on pg_proc, pg_trigger

---

## Integration with Other Skills

### With dbcli-procedure

```bash
# Backup before procedure changes
export DBCLI_CONNECTION="..."
dbcli export-schema procedure -o backup.sql
# Use dbcli-procedure skill to modify
dbcli ddl "ALTER PROCEDURE..."
```

### With dbcli-index

```bash
# Backup before index changes
export DBCLI_CONNECTION="..."
dbcli export-schema index -o backup.sql
# Use dbcli-index skill to drop/create
dbcli ddl "DROP INDEX..."
```

### With dbcli-exec

```bash
# Backup triggers before DML that might affect them
export DBCLI_CONNECTION="..."
dbcli export-schema trigger -o backup.sql
# Use dbcli-exec for data operations
dbcli exec "DELETE FROM..."
```

---

## Configuration

### Using Config File

```json
{
  "ConnectionString": "Server=.;Database=mydb;Trusted_Connection=True",
  "DbType": "sqlserver"
}
```

```bash
# Export using config
# If appsettings.json is in the current working directory, DbCli auto-loads it
dbcli export-schema all -o backup.sql
```

### Environment Variables

```bash
export DBCLI_CONNECTION="Server=.;Database=mydb;Trusted_Connection=True"
export DBCLI_DBTYPE="sqlserver"

dbcli export-schema all
```

---

## Database DDL Extraction Capabilities

Different databases have varying levels of built-in support for extracting DDL (Data Definition Language):

| Database | Native GET_DDL Support | Common Method |
|----------|----------------------|---------------|
| Oracle | ✅ Yes | `DBMS_METADATA.GET_DDL` |
| DaMeng | ✅ Yes | `DBMS_METADATA.GET_DDL` |
| Snowflake | ✅ Yes | `GET_DDL(...)` |
| MySQL / MariaDB / TiDB | ✅ Yes (different syntax) | `SHOW CREATE TABLE/VIEW/...` |
| PostgreSQL | ❌ No unified function | `pg_get_viewdef`, `pg_dump` |
| Microsoft SQL Server | ❌ No native function | `OBJECT_DEFINITION`, `sp_helptext` |
| SQLite | ❌ No native function | `sqlite_master` table |
| IBM DB2 | ❌ No unified function | `db2look` utility |

**Note**: DbCli abstracts these differences and provides unified `export-schema` command across all supported databases. The implementation internally uses the appropriate method for each database type.

---

## Tips & Tricks

### 1. Compare Schema Changes

```bash
# Before changes
export DBCLI_CONNECTION="..."
dbcli export-schema procedure -o procedures_before.sql

# Make changes...

# After changes
dbcli export-schema procedure -o procedures_after.sql

# Compare
diff procedures_before.sql procedures_after.sql
```

### 2. Export Multiple Types

```bash
# Export each type to separate files
export DBCLI_CONNECTION="..."
for type in procedure function trigger view index; do
  dbcli export-schema $type -o "backup_${type}.sql"
done
```

### 3. Grep for Specific Objects

```bash
# Find all procedures containing "User"
export DBCLI_CONNECTION="..."
dbcli export-schema procedure | grep -i "user"
```

### 4. Create Deployment Package

```bash
#!/bin/bash
# package_schema.sh

export DBCLI_CONNECTION="..."

mkdir -p deployment/schema
dbcli export-schema procedure -o deployment/schema/procedures.sql
dbcli export-schema function -o deployment/schema/functions.sql
dbcli export-schema trigger -o deployment/schema/triggers.sql
dbcli export-schema view -o deployment/schema/views.sql
dbcli export-schema index -o deployment/schema/indexes.sql

tar -czf schema_deployment.tar.gz deployment/
```

---

## License

MIT License - See LICENSE file for details

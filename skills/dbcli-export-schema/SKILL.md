# DbCli Schema Export Skill

---
name: dbcli-export-schema
description: Export database schema objects (procedures, functions, triggers, views, indexes) as SQL scripts for backup
version: 1.0.0
category: database
tags: [dbcli, sql, backup, schema, ddl, export, procedures, functions, triggers, views, indexes]
safety_level: safe
requires_backup: no
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

## Overview

Export database schema objects (stored procedures, functions, triggers, views, indexes) as SQL DDL scripts for backup and recovery. This skill is essential for protecting database objects before DROP or ALTER operations.

**Safety Level**: Safe (read-only operation)  
**Requires Backup**: No (this tool creates backups)

## Quick Start

```bash
# Export all schema objects
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema all -o backup_schema.sql

# Export all schema objects as separate files (per object)
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema all --output-dir ./schema_export

# Export only stored procedures
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema procedure -o backup_procedures.sql

# Export only indexes
dbcli -c "Data Source=app.db" export-schema index -o backup_indexes.sql

# Export only triggers
dbcli -c "Data Source=app.db" export-schema trigger -o backup_triggers.sql

# Filter by name pattern
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema procedure --name "sp_User*"
```

---

## Command Syntax

### Basic Usage
```bash
dbcli [connection options] export-schema <type> [options]
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
- `-c, --connection <string>` - Database connection string
- `-t, --db-type <type>` - Database type (sqlite, sqlserver, mysql, postgresql, etc.)
- `--config <path>` - Configuration file path

---

## Examples

### SQLite

```bash
# Export all triggers
dbcli -c "Data Source=app.db" export-schema trigger

# Export all indexes to file
dbcli -c "Data Source=app.db" export-schema index -o backup_indexes.sql

# Export all schema objects
dbcli -c "Data Source=app.db" export-schema all -o backup_all.sql
```

### SQL Server

```bash
# Export all stored procedures
dbcli -c "Server=.;Database=mydb;Trusted_Connection=True" \
  -t sqlserver export-schema procedure -o procedures_backup.sql

# Export specific procedures
dbcli -c "Server=.;Database=mydb;Trusted_Connection=True" \
  -t sqlserver export-schema procedure --name "sp_User*" -o user_procedures.sql

# Export all functions
dbcli -c "Server=.;Database=mydb;Trusted_Connection=True" \
  -t sqlserver export-schema function -o functions_backup.sql

# Export all triggers
dbcli -c "Server=.;Database=mydb;Trusted_Connection=True" \
  -t sqlserver export-schema trigger -o triggers_backup.sql
```

### MySQL

```bash
# Export all procedures
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=password" \
  -t mysql export-schema procedure -o procedures.sql

# Export all triggers
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=password" \
  -t mysql export-schema trigger -o triggers.sql

# Export all indexes
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=password" \
  -t mysql export-schema index -o indexes.sql
```

### PostgreSQL

```bash
# Export all functions
dbcli -c "Host=localhost;Database=mydb;Username=postgres;Password=pass" \
  -t postgresql export-schema function -o functions.sql

# Export all triggers
dbcli -c "Host=localhost;Database=mydb;Username=postgres;Password=pass" \
  -t postgresql export-schema trigger -o triggers.sql

# Export all views
dbcli -c "Host=localhost;Database=mydb;Username=postgres;Password=pass" \
  -t postgresql export-schema view -o views.sql
```

---

## Use Cases

### 1. Pre-deployment Backup

```bash
# Backup all schema objects before deployment
dbcli --config appsettings.json export-schema all -o "backup_$(date +%Y%m%d_%H%M%S).sql"
```

### 2. Procedure Refactoring

```bash
# 1. Backup existing procedures
dbcli -c "Server=.;Database=mydb" -t sqlserver \
  export-schema procedure -o old_procedures.sql

# 2. Drop and recreate procedures
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "DROP PROCEDURE sp_OldProc"
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "CREATE PROCEDURE sp_NewProc..."

# 3. Rollback if needed (execute old_procedures.sql)
```

### 3. Index Optimization

```bash
# 1. Backup current indexes
dbcli -c "Data Source=app.db" export-schema index -o indexes_before.sql

# 2. Drop inefficient indexes
dbcli -c "Data Source=app.db" ddl "DROP INDEX idx_slow"

# 3. Create optimized indexes
dbcli -c "Data Source=app.db" ddl "CREATE INDEX idx_fast ON Table(col1, col2)"

# 4. Export new indexes
dbcli -c "Data Source=app.db" export-schema index -o indexes_after.sql
```

### 4. Database Migration

```bash
# Export all schema from source database
dbcli -c "Server=source;Database=db" -t sqlserver export-schema all -o schema_export.sql

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
dbcli -c "Data Source=app.db" export-schema trigger -o backup_triggers.sql

# Step 2: Review backup file
cat backup_triggers.sql

# Step 3: Perform dangerous operation
dbcli -c "Data Source=app.db" ddl "DROP TRIGGER update_timestamp"

# Step 4: Verify deletion
dbcli -c "Data Source=app.db" export-schema trigger
# (should show no triggers)
```

### Restore from Backup

```bash
# Method 1: Extract and execute CREATE statement
TRIGGER_SQL=$(grep -A 10 "CREATE TRIGGER" backup_triggers.sql | sed '/^GO$/q')
dbcli -c "Data Source=app.db" ddl "$TRIGGER_SQL"

# Method 2: Execute entire backup file (if single object)
dbcli -c "Data Source=app.db" ddl -F backup_triggers.sql

# Verify restoration
dbcli -c "Data Source=app.db" export-schema trigger
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
dbcli -c "..." ddl "DROP PROCEDURE sp_ImportantLogic"

# ✅ GOOD: Backup first
dbcli -c "..." export-schema procedure --name "sp_ImportantLogic" -o backup.sql
dbcli -c "..." ddl "DROP PROCEDURE sp_ImportantLogic"
```

### 2. Use Timestamped Backups

```bash
# Create timestamped backup files
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
dbcli -c "..." export-schema all -o "schema_backup_${TIMESTAMP}.sql"
```

### 3. Store Backups in Version Control

```bash
# Export to version-controlled directory
dbcli -c "..." export-schema all -o "database/schema/procedures.sql"
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
dbcli -c "..." export-schema trigger -o test_backup.sql
dbcli -c "..." ddl "DROP TRIGGER test_trigger"
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
dbcli -c "..." export-schema procedure -o backup.sql
# Use dbcli-procedure skill to modify
dbcli -c "..." ddl "ALTER PROCEDURE..."
```

### With dbcli-index

```bash
# Backup before index changes
dbcli -c "..." export-schema index -o backup.sql
# Use dbcli-index skill to drop/create
dbcli -c "..." ddl "DROP INDEX..."
```

### With dbcli-exec

```bash
# Backup triggers before DML that might affect them
dbcli -c "..." export-schema trigger -o backup.sql
# Use dbcli-exec for data operations
dbcli -c "..." exec "DELETE FROM..."
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
dbcli --config appsettings.json export-schema all -o backup.sql
```

### Environment Variables

```bash
export DB_CONNECTION="Server=.;Database=mydb;Trusted_Connection=True"
export DB_TYPE="sqlserver"

dbcli -c "$DB_CONNECTION" -t "$DB_TYPE" export-schema all
```

---

## Tips & Tricks

### 1. Compare Schema Changes

```bash
# Before changes
dbcli -c "..." export-schema procedure -o procedures_before.sql

# Make changes...

# After changes
dbcli -c "..." export-schema procedure -o procedures_after.sql

# Compare
diff procedures_before.sql procedures_after.sql
```

### 2. Export Multiple Types

```bash
# Export each type to separate files
for type in procedure function trigger view index; do
  dbcli -c "..." export-schema $type -o "backup_${type}.sql"
done
```

### 3. Grep for Specific Objects

```bash
# Find all procedures containing "User"
dbcli -c "..." export-schema procedure | grep -i "user"
```

### 4. Create Deployment Package

```bash
#!/bin/bash
# package_schema.sh

mkdir -p deployment/schema
dbcli -c "..." export-schema procedure -o deployment/schema/procedures.sql
dbcli -c "..." export-schema function -o deployment/schema/functions.sql
dbcli -c "..." export-schema trigger -o deployment/schema/triggers.sql
dbcli -c "..." export-schema view -o deployment/schema/views.sql
dbcli -c "..." export-schema index -o deployment/schema/indexes.sql

tar -czf schema_deployment.tar.gz deployment/
```

---

## See Also

- [dbcli-procedure](../dbcli-procedure/SKILL.md) - Manage stored procedures, functions, and triggers
- [dbcli-index](../dbcli-index/SKILL.md) - Manage database indexes
- [dbcli-view](../dbcli-view/SKILL.md) - Manage database views
- [dbcli-export](../dbcli-export/SKILL.md) - Export table data
- [dbcli-db-ddl](../dbcli-db-ddl/SKILL.md) - Manage database structures

---


---

## License

MIT License - See LICENSE file for details

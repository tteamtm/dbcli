# DbCli Procedure Management Skill

---
name: dbcli-procedure
description: Manage stored procedures, functions, and triggers (CREATE/ALTER/DROP operations)
version: 1.0.0
category: database
tags: [dbcli, sql, procedures, functions, triggers, ddl, database]
safety_level: critical
requires_backup: mandatory
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

Manage stored procedures, functions, and triggers using DbCli's DDL and EXEC commands. This skill covers creating, altering, executing, and dropping database programmability objects across multiple database systems.

**Safety Level**: Critical  
**Requires Backup**: Mandatory before DROP operations

## Quick Start

```bash
# ⚠️ CRITICAL: Always backup before DROP operations!
# Backup all procedures/functions/triggers
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema all -o backup_schema.sql
# Or backup specific type
dbcli -c "Server=.;Database=mydb" -t sqlserver export-schema procedure -o backup_procedures.sql

# Create a stored procedure (SQL Server)
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE PROCEDURE GetUserById @UserId INT
AS
BEGIN
    SELECT * FROM Users WHERE id = @UserId
END"

# Execute stored procedure
dbcli -c "Server=.;Database=mydb" -t sqlserver exec "EXEC GetUserById @UserId=1"

# Drop procedure (with backup)
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "DROP PROCEDURE IF EXISTS GetUserById"

# Restore from backup if needed
# Extract and execute the CREATE statement from backup_procedures.sql

# List all procedures
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT name, create_date, modify_date 
FROM sys.procedures 
ORDER BY name" -f table
```

---

## Command Syntax

```bash
# Create/Alter/Drop
dbcli [options] ddl "<PROCEDURE_DDL_STATEMENT>"

# Execute procedure
dbcli [options] exec "<EXEC_STATEMENT>"
```

### Options

| Option | Alias | Description | Example |
|--------|-------|-------------|---------|
| `--connection` | `-c` | Connection string | `-c "Server=localhost;Database=mydb"` |
| `--db-type` | `-t` | Database type | `-t sqlserver`, `-t mysql`, `-t postgresql` |
| `--format` | `-f` | Output format | `-f json`, `-f table` |
| `--file` | `-F` | Read SQL from file | `-F create_procedure.sql` |
| `--config` | | Use config file | `--config appsettings.json` |

---

## Core Operations

### 1. Stored Procedures

#### SQL Server

##### Create Procedure
```bash
# Simple procedure
dbcli -c "Server=.;Database=mydb;Trusted_Connection=True" -t sqlserver ddl "
CREATE PROCEDURE dbo.GetActiveUsers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, name, email 
    FROM Users 
    WHERE status = 'active'
END"

# Procedure with parameters
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE PROCEDURE dbo.GetUsersByStatus
    @Status VARCHAR(20),
    @Limit INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Limit) id, name, email, status
    FROM Users
    WHERE status = @Status
    ORDER BY created_at DESC
END"

# Procedure with output parameter
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE PROCEDURE dbo.GetUserCount
    @Status VARCHAR(20),
    @Count INT OUTPUT
AS
BEGIN
    SELECT @Count = COUNT(*) 
    FROM Users 
    WHERE status = @Status
END"
```

##### Execute Procedure
```bash
# Execute without parameters
dbcli -c "Server=.;Database=mydb" -t sqlserver exec "EXEC dbo.GetActiveUsers"

# Execute with parameters
dbcli -c "Server=.;Database=mydb" -t sqlserver exec "EXEC dbo.GetUsersByStatus @Status='active', @Limit=50"

# Execute with output parameter
dbcli -c "Server=.;Database=mydb" -t sqlserver exec "
DECLARE @UserCount INT
EXEC dbo.GetUserCount @Status='active', @Count=@UserCount OUTPUT
SELECT @UserCount AS ActiveUserCount"
```

##### Alter Procedure
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
ALTER PROCEDURE dbo.GetActiveUsers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, name, email, created_at
    FROM Users
    WHERE status = 'active'
    ORDER BY name
END"

# Or use CREATE OR ALTER (SQL Server 2016+)
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE OR ALTER PROCEDURE dbo.GetActiveUsers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, name, email, created_at
    FROM Users
    WHERE status = 'active'
    ORDER BY name
END"
```

##### Drop Procedure
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "DROP PROCEDURE IF EXISTS dbo.GetActiveUsers"
```

##### List Procedures
```bash
# All procedures
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT 
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS procedure_name,
    create_date,
    modify_date
FROM sys.procedures
ORDER BY schema_name, name" -f table

# Get procedure definition
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.GetActiveUsers'))"
```

---

#### MySQL

##### Create Procedure
```bash
# Simple procedure
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass" -t mysql ddl "
DELIMITER //
CREATE PROCEDURE GetActiveUsers()
BEGIN
    SELECT id, name, email 
    FROM Users 
    WHERE status = 'active';
END //
DELIMITER ;"

# Procedure with parameters
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
DELIMITER //
CREATE PROCEDURE GetUsersByStatus(IN status_param VARCHAR(20), IN limit_param INT)
BEGIN
    SELECT id, name, email, status
    FROM Users
    WHERE status = status_param
    ORDER BY created_at DESC
    LIMIT limit_param;
END //
DELIMITER ;"

# Procedure with OUT parameter
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
DELIMITER //
CREATE PROCEDURE GetUserCount(IN status_param VARCHAR(20), OUT count_param INT)
BEGIN
    SELECT COUNT(*) INTO count_param
    FROM Users
    WHERE status = status_param;
END //
DELIMITER ;"
```

##### Execute Procedure
```bash
# Execute without parameters
dbcli -c "Server=localhost;Database=mydb" -t mysql exec "CALL GetActiveUsers()"

# Execute with parameters
dbcli -c "Server=localhost;Database=mydb" -t mysql exec "CALL GetUsersByStatus('active', 50)"

# Execute with OUT parameter
dbcli -c "Server=localhost;Database=mydb" -t mysql exec "
CALL GetUserCount('active', @count);
SELECT @count AS ActiveUserCount;"
```

##### Drop Procedure
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "DROP PROCEDURE IF EXISTS GetActiveUsers"
```

##### List Procedures
```bash
# All procedures
dbcli -c "Server=localhost;Database=mydb" -t mysql query "
SELECT ROUTINE_SCHEMA, ROUTINE_NAME, CREATED, LAST_ALTERED
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_SCHEMA = 'mydb'
ORDER BY ROUTINE_NAME" -f table

# Get procedure definition
dbcli -c "Server=localhost;Database=mydb" -t mysql query "
SHOW CREATE PROCEDURE GetActiveUsers"
```

---

#### PostgreSQL

##### Create Function
```bash
# Simple function
dbcli -c "Host=localhost;Database=mydb;Username=postgres;Password=pass" -t postgresql ddl "
CREATE OR REPLACE FUNCTION get_active_users()
RETURNS TABLE(id INT, name TEXT, email TEXT)
LANGUAGE sql
AS $$
    SELECT id, name, email 
    FROM users 
    WHERE status = 'active';
$$"

# Function with parameters
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE OR REPLACE FUNCTION get_users_by_status(status_param TEXT, limit_param INT)
RETURNS TABLE(id INT, name TEXT, email TEXT)
LANGUAGE sql
AS $$
    SELECT id, name, email
    FROM users
    WHERE status = status_param
    ORDER BY created_at DESC
    LIMIT limit_param;
$$"

# PL/pgSQL function
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE OR REPLACE FUNCTION get_user_count(status_param TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count
    FROM users
    WHERE status = status_param;
    RETURN user_count;
END;
$$"
```

##### Execute Function
```bash
# Execute function that returns table
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "SELECT * FROM get_active_users()"

# Execute with parameters
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "SELECT * FROM get_users_by_status('active', 50)"

# Execute function that returns scalar
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "SELECT get_user_count('active')"
```

##### Drop Function
```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "DROP FUNCTION IF EXISTS get_active_users()"
```

##### List Functions
```bash
# All functions
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "
SELECT 
    n.nspname AS schema,
    p.proname AS function_name,
    pg_get_function_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid) AS result_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schema, function_name" -f table

# Get function definition
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = 'get_active_users'"
```

---

#### Oracle

##### Create Procedure
```bash
# Simple procedure
dbcli -c "Data Source=orcl;User Id=system;Password=pass" -t oracle ddl "
CREATE OR REPLACE PROCEDURE get_active_users(p_cursor OUT SYS_REFCURSOR)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT id, name, email
    FROM users
    WHERE status = 'active';
END;"

# Procedure with parameters
dbcli -c "Data Source=orcl" -t oracle ddl "
CREATE OR REPLACE PROCEDURE get_users_by_status(
    p_status IN VARCHAR2,
    p_limit IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT id, name, email
    FROM users
    WHERE status = p_status
    ORDER BY created_at DESC
    FETCH FIRST p_limit ROWS ONLY;
END;"
```

##### Execute Procedure
```bash
# Execute procedure (requires PL/SQL block)
dbcli -c "Data Source=orcl" -t oracle exec "
DECLARE
    v_cursor SYS_REFCURSOR;
BEGIN
    get_active_users(v_cursor);
END;"
```

##### Drop Procedure
```bash
dbcli -c "Data Source=orcl" -t oracle ddl "DROP PROCEDURE get_active_users"
```

##### List Procedures
```bash
# All procedures
dbcli -c "Data Source=orcl" -t oracle query "
SELECT object_name, created, last_ddl_time, status
FROM user_procedures
ORDER BY object_name" -f table

# Get procedure source
dbcli -c "Data Source=orcl" -t oracle query "
SELECT text
FROM user_source
WHERE name = 'GET_ACTIVE_USERS'
ORDER BY line"
```

---

### 2. User-Defined Functions (UDF)

#### SQL Server

##### Scalar Function
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE FUNCTION dbo.CalculateTax(@Amount DECIMAL(10,2), @TaxRate DECIMAL(5,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @Amount * @TaxRate / 100
END"

# Use function
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT 
    product_name, 
    price, 
    dbo.CalculateTax(price, 7.5) AS tax,
    price + dbo.CalculateTax(price, 7.5) AS total
FROM Products"
```

##### Table-Valued Function
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE FUNCTION dbo.GetUserOrders(@UserId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        order_id,
        order_date,
        total_amount
    FROM Orders
    WHERE user_id = @UserId
)"

# Use function
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT * FROM dbo.GetUserOrders(123)"
```

##### Drop Function
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "DROP FUNCTION IF EXISTS dbo.CalculateTax"
```

---

#### MySQL

##### Function
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
DELIMITER //
CREATE FUNCTION calculate_tax(amount DECIMAL(10,2), tax_rate DECIMAL(5,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN amount * tax_rate / 100;
END //
DELIMITER ;"

# Use function
dbcli -c "Server=localhost;Database=mydb" -t mysql query "
SELECT 
    product_name,
    price,
    calculate_tax(price, 7.5) AS tax,
    price + calculate_tax(price, 7.5) AS total
FROM Products"
```

##### Drop Function
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "DROP FUNCTION IF EXISTS calculate_tax"
```

##### List Functions
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql query "
SELECT ROUTINE_NAME, CREATED, LAST_ALTERED
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_SCHEMA = 'mydb'
ORDER BY ROUTINE_NAME" -f table
```

---

### 3. Triggers

#### SQL Server

##### Create Trigger
```bash
# AFTER INSERT trigger
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE TRIGGER trg_Users_AfterInsert
ON Users
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO UserAudit (user_id, action, action_date)
    SELECT id, 'INSERT', GETDATE()
    FROM inserted;
END"

# INSTEAD OF DELETE trigger
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE TRIGGER trg_Users_InsteadOfDelete
ON Users
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users
    SET status = 'deleted', deleted_at = GETDATE()
    WHERE id IN (SELECT id FROM deleted);
END"
```

##### Drop Trigger
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "DROP TRIGGER IF EXISTS trg_Users_AfterInsert"
```

##### List Triggers
```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver query "
SELECT 
    t.name AS trigger_name,
    OBJECT_NAME(t.parent_id) AS table_name,
    t.create_date,
    t.modify_date
FROM sys.triggers t
WHERE t.parent_class = 1
ORDER BY table_name, trigger_name" -f table
```

---

#### MySQL

##### Create Trigger
```bash
# AFTER INSERT trigger
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
CREATE TRIGGER trg_users_after_insert
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    INSERT INTO UserAudit (user_id, action, action_date)
    VALUES (NEW.id, 'INSERT', NOW());
END"

# BEFORE UPDATE trigger
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "
CREATE TRIGGER trg_users_before_update
BEFORE UPDATE ON Users
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END"
```

##### Drop Trigger
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql ddl "DROP TRIGGER IF EXISTS trg_users_after_insert"
```

##### List Triggers
```bash
dbcli -c "Server=localhost;Database=mydb" -t mysql query "
SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE, ACTION_TIMING
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE TRIGGER_SCHEMA = 'mydb'
ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME" -f table
```

---

#### PostgreSQL

##### Create Trigger
```bash
# Create trigger function
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE OR REPLACE FUNCTION audit_user_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO user_audit (user_id, action, action_date)
        VALUES (NEW.id, 'INSERT', NOW());
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO user_audit (user_id, action, action_date)
        VALUES (NEW.id, 'UPDATE', NOW());
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO user_audit (user_id, action, action_date)
        VALUES (OLD.id, 'DELETE', NOW());
    END IF;
    RETURN NEW;
END;
$$"

# Create trigger
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE TRIGGER trg_users_audit
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION audit_user_changes()"
```

##### Drop Trigger
```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "DROP TRIGGER IF EXISTS trg_users_audit ON users"
```

##### List Triggers
```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql query "
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name" -f table
```

---

## Code Integration Examples

### Node.js / JavaScript

```javascript
const { execSync } = require('child_process');
const fs = require('fs');

// Create stored procedure from file
function createProcedureFromFile(procedureFile) {
  execSync(`dbcli -c "Server=.;Database=mydb" -t sqlserver -F ${procedureFile} ddl`);
  console.log(`✅ Procedure created from ${procedureFile}`);
}

// Execute stored procedure
function executeStoredProcedure(procedureName, params = {}) {
  const paramString = Object.entries(params)
    .map(([key, value]) => `@${key}=${typeof value === 'string' ? `'${value}'` : value}`)
    .join(', ');
  
  const result = JSON.parse(
    execSync(`dbcli -c "Server=.;Database=mydb" -t sqlserver exec "EXEC ${procedureName} ${paramString}"`).toString()
  );
  return result;
}

// Drop procedure with backup
function dropProcedureSafely(procedureName) {
  // 1. Export procedure definition
  const definition = execSync(
    `dbcli -c "Server=.;Database=mydb" -t sqlserver query "SELECT OBJECT_DEFINITION(OBJECT_ID('${procedureName}'))"`
  ).toString();
  
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  fs.writeFileSync(`backup_${procedureName}_${timestamp}.sql`, definition);
  
  // 2. Drop procedure
  execSync(`dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "DROP PROCEDURE IF EXISTS ${procedureName}"`);
  console.log(`✅ Procedure ${procedureName} dropped (backup saved)`);
}

// List all procedures
function listProcedures() {
  const result = JSON.parse(
    execSync(`dbcli -c "Server=.;Database=mydb" -t sqlserver query "SELECT name FROM sys.procedures ORDER BY name"`).toString()
  );
  return result;
}

// Usage
const users = executeStoredProcedure('dbo.GetUsersByStatus', { Status: 'active', Limit: 50 });
console.log('Active users:', users);

console.log('All procedures:', listProcedures());
dropProcedureSafely('dbo.OldProcedure');
```

---

### Python

```python
import subprocess
import json
from datetime import datetime

def create_procedure_from_file(procedure_file: str):
    """Create procedure from SQL file"""
    subprocess.run([
        'dbcli', '-c', 'Server=.;Database=mydb', 
        '-t', 'sqlserver', '-F', procedure_file, 'ddl'
    ], check=True)
    print(f"✅ Procedure created from {procedure_file}")

def execute_stored_procedure(procedure_name: str, params: dict = None):
    """Execute stored procedure with parameters"""
    param_string = ''
    if params:
        param_string = ', '.join([
            f"@{key}={f\"'{value}'\" if isinstance(value, str) else value}"
            for key, value in params.items()
        ])
    
    result = subprocess.run([
        'dbcli', '-c', 'Server=.;Database=mydb',
        '-t', 'sqlserver', 'exec', 
        f"EXEC {procedure_name} {param_string}"
    ], capture_output=True, text=True, check=True)
    
    return json.loads(result.stdout)

def drop_procedure_safely(procedure_name: str):
    """Drop procedure with automatic backup"""
    # 1. Export procedure definition
    result = subprocess.run([
        'dbcli', '-c', 'Server=.;Database=mydb',
        '-t', 'sqlserver', 'query',
        f"SELECT OBJECT_DEFINITION(OBJECT_ID('{procedure_name}'))"
    ], capture_output=True, text=True, check=True)
    
    definition = json.loads(result.stdout)[0]
    
    # 2. Save backup
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    with open(f'backup_{procedure_name}_{timestamp}.sql', 'w') as f:
        f.write(str(definition))
    
    # 3. Drop procedure
    subprocess.run([
        'dbcli', '-c', 'Server=.;Database=mydb',
        '-t', 'sqlserver', 'ddl',
        f'DROP PROCEDURE IF EXISTS {procedure_name}'
    ], check=True)
    
    print(f"✅ Procedure {procedure_name} dropped (backup saved)")

def list_procedures():
    """Get all procedures in database"""
    result = subprocess.run([
        'dbcli', '-c', 'Server=.;Database=mydb',
        '-t', 'sqlserver', 'query',
        "SELECT name FROM sys.procedures ORDER BY name"
    ], capture_output=True, text=True, check=True)
    
    return json.loads(result.stdout)

# Usage
users = execute_stored_procedure('dbo.GetUsersByStatus', {'Status': 'active', 'Limit': 50})
print('Active users:', users)

print('All procedures:', list_procedures())
drop_procedure_safely('dbo.OldProcedure')
```

---

### PowerShell

```powershell
# Create procedure from file
function New-DbProcedureFromFile {
    param([string]$ProcedureFile)
    
    dbcli -c "Server=.;Database=mydb" -t sqlserver -F $ProcedureFile ddl
    Write-Host "✅ Procedure created from $ProcedureFile" -ForegroundColor Green
}

# Execute stored procedure
function Invoke-DbStoredProcedure {
    param(
        [string]$ProcedureName,
        [hashtable]$Parameters = @{}
    )
    
    $paramString = ($Parameters.GetEnumerator() | ForEach-Object {
        $value = if ($_.Value -is [string]) { "'$($_.Value)'" } else { $_.Value }
        "@$($_.Key)=$value"
    }) -join ', '
    
    $result = dbcli -c "Server=.;Database=mydb" -t sqlserver exec "EXEC $ProcedureName $paramString" | ConvertFrom-Json
    return $result
}

# Drop procedure with backup
function Remove-DbProcedureSafely {
    param([string]$ProcedureName)
    
    # 1. Export procedure definition
    $definition = dbcli -c "Server=.;Database=mydb" -t sqlserver query "SELECT OBJECT_DEFINITION(OBJECT_ID('$ProcedureName'))"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $definition | Out-File "backup_${ProcedureName}_${timestamp}.sql"
    
    # 2. Drop procedure
    dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "DROP PROCEDURE IF EXISTS $ProcedureName"
    Write-Host "✅ Procedure $ProcedureName dropped (backup saved)" -ForegroundColor Green
}

# List all procedures
function Get-DbProcedures {
    $result = dbcli -c "Server=.;Database=mydb" -t sqlserver query "SELECT name FROM sys.procedures ORDER BY name" | ConvertFrom-Json
    return $result
}

# Usage
$users = Invoke-DbStoredProcedure -ProcedureName "dbo.GetUsersByStatus" -Parameters @{ Status='active'; Limit=50 }
Write-Host "Active users: $($users.Count)"

Get-DbProcedures
Remove-DbProcedureSafely -ProcedureName "dbo.OldProcedure"
```

---

## Safety Best Practices

### 🛑 Critical: Always Backup Before DROP

```bash
# 1. Export procedure definition
dbcli query "SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.ImportantProc'))" > backup_proc.sql

# 2. Then drop
dbcli ddl "DROP PROCEDURE dbo.ImportantProc"
```

### ⚠️ Test in Development First

```bash
# 1. Test in development
dbcli -c "Server=dev;Database=mydb" -t sqlserver ddl -F new_procedure.sql

# 2. Execute tests
dbcli -c "Server=dev;Database=mydb" -t sqlserver exec "EXEC TestNewProcedure"

# 3. Deploy to production
dbcli -c "Server=prod;Database=mydb" -t sqlserver ddl -F new_procedure.sql
```

### ✅ Procedure Development Checklist

- [ ] Document procedure purpose and parameters
- [ ] Use descriptive naming conventions
- [ ] Add error handling (TRY...CATCH, EXCEPTION blocks)
- [ ] Include transaction management where appropriate
- [ ] Test with various input scenarios
- [ ] Backup existing procedure before ALTER/DROP
- [ ] Review execution plan for performance
- [ ] Grant appropriate execute permissions

---

## Advanced Patterns

### Error Handling (SQL Server)

```bash
dbcli -c "Server=.;Database=mydb" -t sqlserver ddl "
CREATE PROCEDURE dbo.SafeUpdateUser
    @UserId INT,
    @NewEmail VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        UPDATE Users
        SET email = @NewEmail, updated_at = GETDATE()
        WHERE id = @UserId;
        
        IF @@ROWCOUNT = 0
            THROW 50001, 'User not found', 1;
        
        COMMIT TRANSACTION;
        SELECT 'Success' AS Status;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END"
```

### Dynamic SQL (PostgreSQL)

```bash
dbcli -c "Host=localhost;Database=mydb" -t postgresql ddl "
CREATE OR REPLACE FUNCTION dynamic_query(table_name TEXT, column_name TEXT)
RETURNS TABLE(result JSONB)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE format('SELECT row_to_json(t) FROM %I t WHERE %I IS NOT NULL', table_name, column_name);
END;
$$"
```

---

## Troubleshooting

### "Procedure already exists"
```bash
# SQL Server - Use CREATE OR ALTER
dbcli ddl "CREATE OR ALTER PROCEDURE dbo.MyProc AS BEGIN ... END"

# MySQL - Use DROP IF EXISTS first
dbcli ddl "DROP PROCEDURE IF EXISTS MyProc"
dbcli ddl "CREATE PROCEDURE MyProc() BEGIN ... END"
```

### "Insufficient privileges"
```bash
# Grant EXECUTE permission
dbcli exec "GRANT EXECUTE ON dbo.MyProc TO UserName" -t sqlserver
```

---

## Related Skills

- **[dbcli-exec](../dbcli-exec/)** - Execute stored procedures
- **[dbcli-view](../dbcli-view/)** - Manage views
- **[dbcli-db-ddl](../dbcli-db-ddl/)** - Manage tables
- **[dbcli-interactive](../dbcli-interactive/)** - Test procedures interactively

---

## Database Support Matrix

| Feature | SQL Server | MySQL | PostgreSQL | Oracle | SQLite |
|---------|-----------|-------|------------|--------|--------|
| Stored Procedures | ✅ | ✅ | ✅ (Functions) | ✅ | ❌ |
| User Functions | ✅ | ✅ | ✅ | ✅ | ❌ |
| Triggers | ✅ | ✅ | ✅ | ✅ | ✅ |
| OUT Parameters | ✅ | ✅ | ❌ (Use RETURN) | ✅ | ❌ |
| Exception Handling | ✅ | ✅ | ✅ | ✅ | ❌ |

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


---
name: dbcli-compare
description: Compare results of two SQL queries to verify if they produce identical data. Checks structure, record count, and data content using MINUS/EXCEPT operations. Use when user needs to validate query equivalence, compare view logic, verify refactoring, or check data consistency.
license: MIT
compatibility: Requires DbCli CLI tool (based on .NET 10 and SqlSugar). Supports databases with MINUS/EXCEPT operators (DaMeng, Oracle, PostgreSQL, Microsoft SQL Server, SQLite, etc.).
metadata:
  tool: dbcli
  version: "1.0.0"
  category: database
  operation-type: comparison-validation
  supported-databases: "DaMeng, Oracle, PostgreSQL, Microsoft SQL Server, SQLite (EXCEPT)"
allowed-tools: dbcli
---


## Command Style (Use PATH)

All examples use the plain command name `dbcli` (no directory prefix).
Ensure `dbcli` is on PATH instead of hardcoding paths like `.\.claude\skills\dbcli\dbcli.exe`.


# DbCli Compare Skill

Compare results of two SQL queries to verify complete data consistency.

## When to Use This Skill

- User wants to compare results of two SQL queries
- User needs to verify query equivalence (e.g., before/after refactoring)
- User asks to validate if two queries produce identical results
- User needs to check if a view matches a complex query
- User wants to verify query optimization didn't change results
- Comparing query results across different time periods or conditions

## Comparison Process

The comparison performs five checks:

1. **Structure Check** - Verify column names, types, and order match
2. **Record Count** - Compare total number of rows
3. **Data Diff (Direction 1)** - Find records in query1 not in query2
4. **Data Diff (Direction 2)** - Find records in query2 not in query1
5. **Result Summary** - Report complete status

## Command Syntax

```bash
dbcli compare "QUERY1" "QUERY2" [-c CONNECTION] [-t DBTYPE]
```

### Parameters

- First SQL query (required)
- Second SQL query (required)
- `-t, --db-type`: Database type (optional, default: "sqlite")
- Environment variables:
  - `DBCLI_CONNECTION`: Database connection string
  - `DBCLI_DBTYPE`: Database type (alternative to -t)

## Usage Examples

### Basic Comparison

```bash
# Compare two views
dbcli compare "SELECT * FROM V_ORDERS_NEW" "SELECT * FROM V_ORDERS_OLD"

# Compare table with filtered query
dbcli compare "SELECT * FROM Orders WHERE Status='Active'" "SELECT * FROM Orders_Archive WHERE Status='Active'"

# Compare complex queries
dbcli compare "SELECT CustomerID, SUM(Amount) AS Total FROM Orders GROUP BY CustomerID" "SELECT CustomerID, SUM(Amount) AS Total FROM Orders_V2 GROUP BY CustomerID"
```

### With Connection Options

```bash
# SQLite (using environment variables)
export DBCLI_CONNECTION="Data Source=mydb.db"
export DBCLI_DBTYPE="sqlite"
dbcli compare "SELECT * FROM users WHERE active=1" "SELECT * FROM users_v2 WHERE active=1"

# SQL Server
export DBCLI_CONNECTION="Server=localhost;Database=testdb;Trusted_Connection=True"
dbcli -t sqlserver compare "SELECT * FROM Orders" "SELECT * FROM Orders_Backup"

# PostgreSQL
export DBCLI_CONNECTION="Host=localhost;Database=mydb;Username=postgres;Password=pass"
dbcli -t postgresql compare "SELECT * FROM sales WHERE year=2026" "SELECT * FROM sales_archive WHERE year=2026"
```

## Output Format

### Successful Match

```text
[1/3] Comparing record counts...
  Query1: 14547 records
  Query2: 14547 records
  ✓ Record counts match (14547 records)

[2/3] Checking differences (query1 - query2)...
  Unique to query1: 0 records

[3/3] Checking differences (query2 - query1)...
  Unique to query2: 0 records

✓ Query results are identical
```

### Data Mismatch

```text
[1/3] Comparing record counts...
  Query1: 1520 records
  Query2: 1518 records
  ✗ Record counts differ

[2/3] Checking differences (query1 - query2)...
  Unique to query1: 5 records

[3/3] Checking differences (query2 - query1)...
  Unique to query2: 3 records

✗ Query results differ (8 total differences)
```

## Exit Codes

- `0` - Query results are completely identical
- `1` - Data or structure mismatch detected

## Database Compatibility

### MINUS Operator Support

| Database | Operator | Notes |
|----------|----------|-------|
| DaMeng | `MINUS` | Native support |
| Oracle | `MINUS` | Native support |
| PostgreSQL | `EXCEPT` | Use EXCEPT instead of MINUS |
| Microsoft SQL Server | `EXCEPT` | Use EXCEPT instead of MINUS |

### Implementation Note

The `dbcli compare` command automatically detects the database type and uses the appropriate operator:
- SQLite, PostgreSQL, Microsoft SQL Server: `EXCEPT`
- DaMeng, Oracle: `MINUS`

## Common Use Cases

### Validate Query Refactoring

```bash
# Compare original and optimized query
dbcli compare "SELECT * FROM Orders WHERE Status='Active'" "SELECT * FROM Orders WHERE Status IN ('Active')"
```

### Verify View Logic

```bash
# Compare view with underlying query
dbcli compare "SELECT * FROM V_SALES_SUMMARY" "SELECT CustomerID, SUM(Amount) AS Total FROM Sales GROUP BY CustomerID"
```

### Check Data Consistency

```bash
# Compare data across environments
dbcli compare "SELECT * FROM Users WHERE Active=1" "SELECT * FROM Users_Archive WHERE Active=1"
```

## Troubleshooting

### Query Execution Failed

- Verify SQL syntax is correct for the database type
- Check connection string is correct
- Ensure user has SELECT permission on referenced tables
- Test each query individually first: `dbcli query "YOUR_SQL"`

### MINUS Not Supported

- Use EXCEPT for PostgreSQL or SQL Server
- The implementation should handle this automatically based on `-t` flag

### Performance Issues

- For large tables, add WHERE clauses to limit comparison scope
- Use indexed columns in queries for faster comparisons
- Consider comparing aggregated data instead of row-by-row

## Related Skills

- **dbcli-query** - Execute SELECT queries to preview data
- **dbcli-tables** - List available tables/views
- **dbcli-export** - Backup data before making changes
- **dbcli-view** - Manage view definitions

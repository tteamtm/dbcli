# DbCli - AI Assistant Integration (Redirect)

The canonical, up-to-date integration guide is now:

- `skills/INTEGRATION.md`

This file is kept as a stable entrypoint for older links, but the detailed, maintained content lives in `skills/INTEGRATION.md`.

## Quick Start for AI Assistants

### Command Pattern Recognition

DbCli follows a consistent command pattern that AI assistants can easily learn:

```bash
dbcli <command> [arguments] [options]
```

Command-first is recommended. For compatibility, DbCli also accepts the legacy style where common options appear before the subcommand.

**Common commands**: `query`, `exec`, `ddl`, `tables`, `columns`, `export`, `interactive`

**Common options**:
- `-c, --connection`: Connection string
- `-t, --db-type`: Database type (sqlite, sqlserver, mysql, postgresql, oracle, dm, gaussdb, etc.)
- `-f, --format`: Output format (json, table, csv)
- `-F, --file`: SQL file path


## Database-Specific Examples

```bash
# SQLite
dbcli -c "Data Source=app.db" query "SELECT * FROM Users" -t sqlite

# SQL Server
dbcli -c "Server=localhost;Database=mydb;Trusted_Connection=True" query "SELECT TOP 10 * FROM Users" -t sqlserver

# MySQL
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass" query "SELECT * FROM Users LIMIT 10" -t mysql

# PostgreSQL
dbcli -c "Host=localhost;Database=mydb;Username=postgres;Password=pass" query "SELECT * FROM Users LIMIT 10" -t postgresql

# DaMeng (达梦)
dbcli -c "Server=localhost;User Id=SYSDBA;PWD=SYSDBA;DATABASE=mydb" query "SELECT * FROM Users" -t dm

# GaussDB (华为高斯)
dbcli -c "Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=pass" query "SELECT * FROM Users" -t gaussdb
```

### 3. Working with Files

```bash
# Execute SQL from file
dbcli ddl -F schema.sql -c "Data Source=app.db"
dbcli exec -F seed.sql -c "Data Source=app.db"

# Export table to file
dbcli -c "Data Source=app.db" export Users > users_backup.sql
```

### 4. Configuration Files

```json
// appsettings.json
{
  "ConnectionString": "Data Source=app.db",
  "DbType": "sqlite"
}
```

```bash
# Use config file
dbcli query "SELECT * FROM Users" --config appsettings.json
```

### 5. Environment Variables

```bash
# Set environment variables
export DBCLI_CONNECTION="Data Source=app.db"
export DBCLI_DBTYPE="sqlite"

# Use without specifying connection
dbcli query "SELECT * FROM Users"
```

## AI-Friendly Patterns

### Pattern 1: Query and Parse JSON

```javascript
// AI can suggest this pattern
async function getUserById(id) {
  const result = execSync(`dbcli -c "Data Source=app.db" query "SELECT * FROM Users WHERE id = ${id}"`);
  return JSON.parse(result.toString())[0];
}
```

### Pattern 2: Build Dynamic Queries

```python
# AI can suggest safe parameterized approach
def search_users(name_filter):
    # Use SQL file for complex queries
    sql = f"SELECT * FROM Users WHERE name LIKE '%{name_filter}%'"
    with open('temp_query.sql', 'w') as f:
        f.write(sql)

    result = subprocess.run(
        ['dbcli', 'query', '-F', 'temp_query.sql', '-c', 'Data Source=app.db'],
        capture_output=True
    )
    return json.loads(result.stdout)
```

### Pattern 3: Database Migration

```bash
# AI can suggest migration scripts
# migrations/001_create_users.sql
CREATE TABLE Users (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Name TEXT NOT NULL,
    Email TEXT UNIQUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

# Run migration
dbcli ddl -F migrations/001_create_users.sql -c "Data Source=app.db"
```

### Pattern 4: Batch Operations

```javascript
// AI can suggest batch processing
const users = [
  { name: 'Alice', email: 'alice@test.com' },
  { name: 'Bob', email: 'bob@test.com' }
];

// Generate SQL file
const sql = users.map(u =>
  `INSERT INTO Users (name, email) VALUES ('${u.name}', '${u.email}');`
).join('\n');

fs.writeFileSync('batch_insert.sql', sql);

// Execute batch
execSync('dbcli exec -F batch_insert.sql -c "Data Source=app.db"');
```

### Pattern 5: Table Statistics

```bash
# Get table count (AI can suggest this for different databases)

# SQLite
dbcli -c "Data Source=app.db" query "SELECT COUNT(*) as count FROM Users"

# SQL Server
dbcli -c "Server=.;Database=mydb;Trusted_Connection=True" query "SELECT COUNT(*) as count FROM Users WITH (NOLOCK)" -t sqlserver

# MySQL
dbcli -c "Server=localhost;Database=mydb;Uid=root;Pwd=pass" query "SELECT COUNT(*) as count FROM Users" -t mysql
```

## Common Use Cases for AI Assistants

### Use Case 1: Database Initialization Script

```javascript
// AI can suggest complete initialization
const { execSync } = require('child_process');

function initializeDatabase() {
  // Create tables
  execSync('dbcli ddl -F schema.sql -c "Data Source=app.db"');

  // Seed data
  execSync('dbcli exec -F seed.sql -c "Data Source=app.db"');

  // Create indexes
  execSync('dbcli -c "Data Source=app.db" ddl "CREATE INDEX idx_users_email ON Users(Email)"');

  console.log('Database initialized successfully');
}
```

### Use Case 2: Data Export/Import

```python
# AI can suggest export/import workflow
import subprocess

def export_table(table_name, output_file):
    """Export table to SQL file"""
    result = subprocess.run(
        ['dbcli', 'export', table_name, '-c', 'Data Source=app.db'],
        capture_output=True,
        text=True
    )

    with open(output_file, 'w') as f:
        f.write(result.stdout)

def import_table(sql_file):
    """Import from SQL file"""
    subprocess.run([
        'dbcli', 'exec', '-F', sql_file,
        '-c', 'Data Source=app.db'
    ])
```

### Use Case 3: Health Check

```bash
# AI can suggest health check script
#!/bin/bash

# Check database connectivity
if dbcli -c "Data Source=app.db" query "SELECT 1" > /dev/null 2>&1; then
    echo "Database is healthy"
    exit 0
else
    echo "Database connection failed"
    exit 1
fi
```

### Use Case 4: Reporting

```python
# AI can suggest reporting queries
def generate_user_report():
    queries = {
        'total_users': 'SELECT COUNT(*) as count FROM Users',
        'active_users': 'SELECT COUNT(*) as count FROM Users WHERE active = 1',
        'new_users_today': "SELECT COUNT(*) as count FROM Users WHERE DATE(created_at) = DATE('now')"
    }

    report = {}
    for key, query in queries.items():
        result = subprocess.run(
            ['dbcli', 'query', query, '-c', 'Data Source=app.db'],
            capture_output=True,
            text=True
        )
        report[key] = json.loads(result.stdout)[0]['count']

    return report
```

## GitHub Copilot Comments

Add these comments in your code to help Copilot suggest correct DbCli commands:

```javascript
// Query all users from SQLite database
// dbcli -c "Data Source=app.db" query "SELECT * FROM Users"

// Insert new user into database
// dbcli -c "Data Source=app.db" exec "INSERT INTO Users (name, email) VALUES ('John', 'john@test.com')"

// Create users table
// dbcli -c "Data Source=app.db" ddl "CREATE TABLE Users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)"

// Export users table
// dbcli -c "Data Source=app.db" export Users > users.sql

// Get table structure
// dbcli -c "Data Source=app.db" -f table columns Users

// List all tables
// dbcli -c "Data Source=app.db" tables -f table
```

## Integration with Popular Frameworks

### Express.js

```javascript
const express = require('express');
const { execSync } = require('child_process');

const app = express();

app.get('/api/users', (req, res) => {
  const users = JSON.parse(
    execSync('dbcli -c "Data Source=app.db" query "SELECT * FROM Users"').toString()
  );
  res.json(users);
});

app.post('/api/users', (req, res) => {
  const { name, email } = req.body;
  execSync(`dbcli -c "Data Source=app.db" exec "INSERT INTO Users (name, email) VALUES ('${name}', '${email}')"`);
  res.json({ success: true });
});
```

### Flask

```python
from flask import Flask, jsonify, request
import subprocess
import json

app = Flask(__name__)

@app.route('/api/users', methods=['GET'])
def get_users():
    result = subprocess.run(
        ['dbcli', 'query', 'SELECT * FROM Users', '-c', 'Data Source=app.db'],
        capture_output=True,
        text=True
    )
    return jsonify(json.loads(result.stdout))

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.json
    subprocess.run([
        'dbcli', 'exec',
        f"INSERT INTO Users (name, email) VALUES ('{data['name']}', '{data['email']}')",
        '-c', 'Data Source=app.db'
    ])
    return jsonify({'success': True})
```

### ASP.NET Core

```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    [HttpGet]
    public IActionResult GetUsers()
    {
        var process = Process.Start(new ProcessStartInfo
        {
            FileName = "dbcli",
            Arguments = "query \"SELECT * FROM Users\" -c \"Data Source=app.db\"",
            RedirectStandardOutput = true
        });

        var output = process.StandardOutput.ReadToEnd();
        var users = JsonSerializer.Deserialize<List<User>>(output);

        return Ok(users);
    }
}
```

## Tips for AI Assistants

1. **Connection String Format**: Each database has a specific connection string format
2. **SQL Syntax**: Use database-specific SQL syntax (e.g., `TOP` for SQL Server, `LIMIT` for MySQL/PostgreSQL)
3. **Output Format**: Use `-f json` for programmatic parsing, `-f table` for human-readable output
4. **File Operations**: Use `-F` flag for executing SQL from files
5. **Error Handling**: Always check exit codes and stderr for errors

## Supported Databases Reference

| Database | Type Flag | Common Connection String |
|----------|-----------|--------------------------|
| SQLite | `sqlite` | `Data Source=app.db` |
| SQL Server | `sqlserver` | `Server=.;Database=mydb;Trusted_Connection=True` |
| MySQL | `mysql` | `Server=localhost;Database=mydb;Uid=root;Pwd=pass` |
| PostgreSQL | `postgresql` | `Host=localhost;Database=mydb;Username=postgres;Password=pass` |
| Oracle | `oracle` | `Data Source=localhost:1521/orcl;User Id=system;Password=oracle` |
| DaMeng | `dm` | `Server=localhost;User Id=SYSDBA;PWD=SYSDBA;DATABASE=mydb` |
| GaussDB | `gaussdb` | `Host=localhost;Port=8000;Database=mydb;Username=gaussdb;Password=pass` |
| KingbaseES | `kdbndp` | `Server=localhost;Port=54321;UID=system;PWD=system;database=mydb` |
| MongoDB | `mongodb` | `mongodb://localhost:27017/mydb` |

## Best Practices

1. **Use SQL files for complex queries** - Easier to maintain and version control
2. **Use config files for production** - Avoid hardcoding connection strings
3. **Parse JSON output** - Use `-f json` for programmatic access
4. **Handle errors properly** - Check process exit codes
5. **Use environment variables** - For sensitive connection strings

## Learning Resources

- Main README: See project root README.md
- Skills Documentation: See `skills/` directory
- Examples: See test files in project

## AI Prompt Templates

### For GitHub Copilot

```javascript
// Query database using dbcli and return JSON
// Database: SQLite, Table: Users, Connection: Data Source=app.db
```

### For ChatGPT/Codex

```
Write a Node.js function that uses dbcli to:
1. Query all users from SQLite database (Data Source=app.db)
2. Filter users by age > 18
3. Return as JSON array
```

### For Claude

```
Create a Python script using dbcli to:
- Connect to GaussDB database
- Create a table called 'products' with id, name, price columns
- Insert 3 sample products
- Query and print all products
```

This integration guide helps AI assistants understand and generate correct DbCli commands!

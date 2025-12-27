# DbCli Skills - AI Agent Integration Guide

This guide explains how to integrate DbCli skills with various AI coding assistants. DbCli skills follow the [Agent Skills Specification](https://agentskills.io/specification), making them compatible with multiple platforms.

## Supported AI Assistants

- ✅ **Claude Code** (Anthropic)
- ✅ **GitHub Copilot** (OpenAI Codex)
- ✅ **OpenAI Codex** (Direct API)
- ✅ **Cline/Roo/Kilo** (VS Code Extensions)
- ✅ **Cursor** (AI-powered IDE)
- ✅ **Windsurf** (Codeium)
- ✅ **Continue** (VS Code/JetBrains)
- ✅ **Gemini Code Assist** (Google)

---

## Table of Contents

1. [Claude Code Integration](#1-claude-code-integration)
2. [GitHub Copilot Integration](#2-github-copilot-integration)
3. [OpenAI Codex Integration](#3-openai-codex-integration)
4. [OpenAI Codex (Direct API)](#4-openai-codex-direct-api)
5. [VS Code Extensions (Cline/Roo/Kilo)](#5-vs-code-extensions-clinerookilo)
6. [Cursor IDE](#6-cursor-ide)
7. [Windsurf (Codeium)](#7-windsurf-codeium)
8. [Continue Dev](#8-continue-dev)
9. [Gemini Code Assist](#9-gemini-code-assist)
10. [Custom Integration](#10-custom-integration)

---

## 1. Claude Code Integration

### Method 1: Copy to Claude Skills Directory

```bash
# Install + deploy (single entrypoint)
pwsh .\deploy-skills.ps1 -InstallExe -AddToPath -Target claude -Force

# Copy skills to Claude's directory
cp -r skills ~/.claude/skills/dbcli
```

### Method 2: Symlink (for development)

```bash
# Create symlink to skills directory
ln -s "$(pwd)/skills" ~/.claude/skills/dbcli
```

### Verify Installation

```bash
# Check skills are available
ls ~/.claude/skills/dbcli/

# Expected output:
# dbcli-query/  dbcli-exec/  dbcli-db-ddl/  dbcli-tables/
# dbcli-export/  dbcli-view/  dbcli-index/  dbcli-procedure/
# dbcli-interactive/  README.md  CONNECTION_STRINGS.md
```

### Usage in Claude Code

```bash
# Use skills in chat
/use dbcli-query "Show me all users in the database"

# Or let Claude auto-discover skills
"I need to query my SQLite database for all active users"
# Claude will automatically use dbcli-query skill
```

### Configuration

Create `~/.claude/config.json` (optional):

```json
{
  "skills": {
    "dbcli": {
      "enabled": true,
      "default_connection": "Data Source=app.db",
      "default_db_type": "sqlite"
    }
  }
}
```

---

## 2. GitHub Copilot Integration

### Method 1: Workspace Copilot Instructions

Create or update `.github/copilot-instructions.md`:

```markdown
# GitHub Copilot Instructions for DbCli

## Available Skills

This project uses DbCli for database operations. Available skills:

### Query Operations (Read-Only)
- **dbcli-query**: Execute SELECT queries
- **dbcli-tables**: List tables and view structure

### Data Modification (Backup Required)
- **dbcli-exec**: Execute INSERT/UPDATE/DELETE
- **dbcli-export**: Export table data for backup

### Schema Modification (Critical - Backup Mandatory)
- **dbcli-db-ddl**: CREATE/ALTER/DROP tables
- **dbcli-view**: Manage views
- **dbcli-index**: Manage indexes
- **dbcli-procedure**: Manage stored procedures/functions/triggers

### Interactive
- **dbcli-interactive**: Interactive SQL mode

## DbCli Command Pattern

```bash
dbcli [options] <command> "<sql_or_table>"
```

### Common Commands

```bash
# Query
dbcli -c "Data Source=app.db" query "SELECT * FROM Users"

# Execute (with backup!)
dbcli -c "Data Source=app.db" exec "INSERT INTO Users (name, email) VALUES ('John', 'john@example.com')"

# List tables
dbcli -c "Data Source=app.db" tables

# Export for backup
dbcli -c "Data Source=app.db" export Users > backup.sql
```

### Connection Strings

**SQLite**: `Data Source=database.db`
**SQL Server**: `Server=localhost;Database=mydb;Trusted_Connection=True`
**MySQL**: `Server=localhost;Database=mydb;Uid=root;Pwd=pass`
**PostgreSQL**: `Host=localhost;Database=mydb;Username=postgres;Password=pass`

See `skills/CONNECTION_STRINGS.md` for 30+ database examples.

### Code Integration Patterns

#### Node.js
```javascript
const { execSync } = require('child_process');

// Query
const users = JSON.parse(
  execSync('dbcli -c "Data Source=app.db" query "SELECT * FROM Users"').toString()
);

// Execute
execSync('dbcli -c "Data Source=app.db" exec "INSERT INTO Users (name) VALUES (\'John\')"');
```

#### Python
```python
import subprocess
import json

# Query
result = subprocess.run(['dbcli', '-c', 'Data Source=app.db', 'query', 'SELECT * FROM Users'], 
                       capture_output=True, text=True, check=True)
users = json.loads(result.stdout)

# Execute
subprocess.run(['dbcli', '-c', 'Data Source=app.db', 'exec', 
                "INSERT INTO Users (name) VALUES ('John')"], check=True)
```

### Safety Guidelines

⚠️ **ALWAYS CREATE BACKUPS** before UPDATE/DELETE/DROP operations:

```bash
# 1. Create backup FIRST
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
dbcli -c "Data Source=app.db" export Users > Users_backup_${TIMESTAMP}.sql

# 2. Then execute modification
dbcli -c "Data Source=app.db" exec "UPDATE Users SET status='inactive' WHERE last_login < '2024-01-01'"
```

## Skill References

For detailed documentation on each skill, see:
- `skills/dbcli-query/SKILL.md`
- `skills/dbcli-exec/SKILL.md`
- `skills/dbcli-db-ddl/SKILL.md`
- `skills/dbcli-view/SKILL.md`
- `skills/dbcli-index/SKILL.md`
- `skills/dbcli-procedure/SKILL.md`
- And more in `skills/` directory
```

### Method 2: Project-Level Skills Directory

Place skills in your project:

```
your-project/
├── .github/
│   └── copilot-instructions.md    # References skills below
├── skills/
│   └── dbcli/                     # Copy skills here
│       ├── dbcli-query/
│       ├── dbcli-exec/
│       └── ...
└── src/
```

### Method 3: Repository Copilot Configuration

Create `.github/copilot-config.yml`:

```yaml
skills:
  enabled: true
  paths:
    - skills/dbcli
  
dbcli:
  default_connection: "Data Source=app.db"
  safety_mode: true
  require_backup_for:
    - UPDATE
    - DELETE
    - DROP
    - ALTER
```

---

## 3. OpenAI Codex Integration

### Overview
OpenAI Codex uses a hierarchical skill loading system with multiple scopes for flexible deployment.

### Installation

**Automatic (Recommended)**
```bash
# From dbcli repository
.\deploy-skills.ps1 -Target codex     # PowerShell
python3 deploy-skills.py --target codex  # Python
```

**Manual**
```bash
# USER scope (personal skills, applies to all projects)
mkdir -p ~/.codex/skills/dbcli
cp -r skills/dbcli-* ~/.codex/skills/dbcli/
cp skills/{README.md,INTEGRATION.md,CONNECTION_STRINGS.md} ~/.codex/skills/dbcli/

# REPO scope (project-specific, team can commit)
mkdir -p .codex/skills/dbcli
cp -r skills/dbcli-* .codex/skills/dbcli/
# git add .codex/ && git commit -m "Add DbCli skills"
```

### Codex Skill Scopes

| Scope | Location | Priority | Use Case |
|-------|----------|----------|----------|
| REPO | `.codex/skills/` | Highest | Project skills |
| REPO | `../.codex/skills/` | High | Parent folder |
| REPO | `$REPO_ROOT/.codex/skills/` | Medium | Repo root |
| USER | `~/.codex/skills/` | Low | Personal |
| ADMIN | `/etc/codex/skills/` | Lower | System |

**Deployment Strategy:**
- **USER scope** (`~/.codex/`): Install once, use everywhere
- **REPO scope** (`.codex/`): Share with team via git

### Usage

```
# Codex automatically discovers skills
> Query database for users
# Recognizes dbcli-query skill and generates:
dbcli -c "Data Source=app.db" query "SELECT * FROM Users"
```

### Team Sharing

```bash
# 1. Deploy to project
.\deploy-skills.ps1 -Target codex

# 2. Commit to repository
git add .codex/
git commit -m "Add DbCli skills"
git push

# 3. Team pulls and uses immediately
```

### Verification

```bash
ls ~/.codex/skills/dbcli/        # USER
ls .codex/skills/dbcli/          # REPO
# Restart Codex to load skills
```

---

## 4. OpenAI Codex (Direct API)

### Setup Skills Context

When using OpenAI API directly, include skills in system context:

```python
import openai
import json

# Load skill documentation
def load_skill_docs():
    skills = {}
    skill_names = [
        'dbcli-query', 'dbcli-exec', 'dbcli-db-ddl',
        'dbcli-view', 'dbcli-index', 'dbcli-procedure'
    ]
    
    for skill in skill_names:
        with open(f'skills/{skill}/SKILL.md', 'r') as f:
            skills[skill] = f.read()
    
    return skills

skills_docs = load_skill_docs()

# Create system message with skills context
system_message = f"""
You are an AI assistant with access to DbCli skills for database operations.

Available Skills:
{json.dumps(list(skills_docs.keys()), indent=2)}

When the user asks about database operations, reference the appropriate skill documentation.

Example skill usage:
- Query: Use dbcli-query skill
- Modify data: Use dbcli-exec skill (always backup first!)
- Schema changes: Use dbcli-db-ddl, dbcli-view, dbcli-index, or dbcli-procedure

Skill Documentation:
{skills_docs['dbcli-query']}
"""

# Use in API call
response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": system_message},
        {"role": "user", "content": "How do I query all users from my SQLite database?"}
    ]
)

print(response.choices[0].message.content)
```

### Function Calling with Skills

```python
import openai

# Define functions based on skills
functions = [
    {
        "name": "dbcli_query",
        "description": "Execute a SELECT query on a database. Read-only operation, safe to use.",
        "parameters": {
            "type": "object",
            "properties": {
                "connection_string": {
                    "type": "string",
                    "description": "Database connection string, e.g., 'Data Source=app.db'"
                },
                "db_type": {
                    "type": "string",
                    "enum": ["sqlite", "sqlserver", "mysql", "postgresql", "oracle"],
                    "description": "Database type"
                },
                "query": {
                    "type": "string",
                    "description": "SQL SELECT query to execute"
                }
            },
            "required": ["connection_string", "query"]
        }
    },
    {
        "name": "dbcli_exec",
        "description": "Execute INSERT/UPDATE/DELETE. WARNING: Always create backup first!",
        "parameters": {
            "type": "object",
            "properties": {
                "connection_string": {"type": "string"},
                "db_type": {"type": "string"},
                "sql": {"type": "string"},
                "backup_created": {
                    "type": "boolean",
                    "description": "Confirm that backup was created before modification"
                }
            },
            "required": ["connection_string", "sql", "backup_created"]
        }
    }
]

# Use function calling
response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[
        {"role": "user", "content": "Get all active users from app.db"}
    ],
    functions=functions,
    function_call="auto"
)

# Execute the function
if response.choices[0].message.get("function_call"):
    function_call = response.choices[0].message.function_call
    function_name = function_call.name
    function_args = json.loads(function_call.arguments)
    
    if function_name == "dbcli_query":
        # Execute dbcli command
        import subprocess
        result = subprocess.run([
            'dbcli',
            '-c', function_args['connection_string'],
            '-t', function_args.get('db_type', 'sqlite'),
            'query', function_args['query']
        ], capture_output=True, text=True)
        
        print(result.stdout)
```

---

## 5. VS Code Extensions (Cline/Roo/Kilo)

These extensions typically support both skill directories and context files.

### Method 1: Workspace Skills Directory

Create `.vscode/skills/` in your workspace:

```bash
# Copy skills to workspace
mkdir -p .vscode/skills
cp -r skills .vscode/skills/dbcli
```

### Method 2: Global Skills Configuration

For **Cline**:

1. Open VS Code Settings
2. Search for "Cline Skills"
3. Add skills path: `~/.dbcli/skills` or project path

For **Roo**:

Create `~/.roo/config.json`:

```json
{
  "skills": {
    "paths": [
      "~/.dbcli/skills",
      "${workspaceFolder}/skills"
    ]
  }
}
```

For **Kilo**:

Create `.kilo/config.json` in workspace:

```json
{
  "skills": {
    "enabled": true,
    "directories": ["skills/dbcli"]
  }
}
```

### Method 3: Context Files

Create `.vscode/context.md`:

```markdown
# DbCli Skills Available

This workspace has access to DbCli database CLI tool with the following skills:

## Skills
- dbcli-query: Query databases (SELECT)
- dbcli-exec: Execute data modifications (INSERT/UPDATE/DELETE)
- dbcli-db-ddl: Manage table structures
- dbcli-view: Manage views
- dbcli-index: Manage indexes
- dbcli-procedure: Manage stored procedures/functions

## Usage Examples

Query:
```bash
dbcli -c "Data Source=app.db" query "SELECT * FROM Users"
```

Execute (with backup!):
```bash
dbcli -c "Data Source=app.db" export Users > backup.sql
dbcli -c "Data Source=app.db" exec "UPDATE Users SET status='active'"
```

Full documentation in `skills/dbcli/` directory.
```

---

## 6. Cursor IDE

Cursor supports both workspace context and rules files.

### Method 1: .cursorrules File

Create `.cursorrules` in project root:

```
# DbCli Database Skills

This project uses DbCli for database operations. Always use DbCli commands instead of raw SQL execution.

## Available Commands

Query (read-only):
dbcli -c "connection_string" query "SELECT * FROM table"

Execute (requires backup):
dbcli -c "connection_string" exec "INSERT/UPDATE/DELETE ..."

Table operations:
dbcli -c "connection_string" tables
dbcli -c "connection_string" columns TableName

Export (for backup):
dbcli -c "connection_string" export TableName > backup.sql

## Safety Rules

CRITICAL: Before any UPDATE, DELETE, DROP, or ALTER operation:
1. Create backup first: dbcli export TableName > backup_$(date +%Y%m%d_%H%M%S).sql
2. Then execute modification
3. Never skip backups!

## Connection Strings

SQLite: Data Source=database.db
SQL Server: Server=localhost;Database=mydb;Trusted_Connection=True
MySQL: Server=localhost;Database=mydb;Uid=root;Pwd=pass
PostgreSQL: Host=localhost;Database=mydb;Username=postgres;Password=pass

## Code Patterns

Node.js:
const { execSync } = require('child_process');
const result = JSON.parse(execSync('dbcli -c "Data Source=app.db" query "SELECT * FROM Users"').toString());

Python:
import subprocess, json
result = subprocess.run(['dbcli', '-c', 'Data Source=app.db', 'query', 'SELECT * FROM Users'], capture_output=True, text=True)
data = json.loads(result.stdout)

See skills/dbcli/ directory for full documentation.
```

### Method 2: Workspace Context

Create `.cursor/context.json`:

```json
{
  "skills": {
    "dbcli": {
      "enabled": true,
      "path": "skills/dbcli",
      "documentation": [
        "skills/dbcli/README.md",
        "skills/dbcli/CONNECTION_STRINGS.md"
      ]
    }
  }
}
```

---

## 7. Windsurf (Codeium)

### Cascade Configuration

Create `.windsurf/cascade.yaml`:

```yaml
version: 1

skills:
  - name: dbcli
    path: skills/dbcli
    enabled: true
    
context:
  - skills/dbcli/README.md
  - skills/dbcli/CONNECTION_STRINGS.md

commands:
  dbcli-query:
    description: "Query database with DbCli"
    command: "dbcli -c \"${connection}\" query \"${sql}\""
    
  dbcli-exec:
    description: "Execute SQL with DbCli (backup required!)"
    command: "dbcli -c \"${connection}\" exec \"${sql}\""
    requires_backup: true

rules:
  - "Always create backups before UPDATE/DELETE/DROP operations"
  - "Use dbcli commands instead of direct SQL execution"
  - "Reference skills/dbcli/ for detailed documentation"
```

---

## 8. Continue Dev

### Configuration

Create `.continue/config.json`:

```json
{
  "skills": [
    {
      "name": "dbcli",
      "path": "skills/dbcli",
      "enabled": true,
      "skills": [
        "dbcli-query",
        "dbcli-exec",
        "dbcli-db-ddl",
        "dbcli-view",
        "dbcli-index",
        "dbcli-procedure"
      ]
    }
  ],
  
  "contextProviders": [
    {
      "name": "dbcli-docs",
      "type": "file",
      "paths": [
        "skills/dbcli/README.md",
        "skills/dbcli/CONNECTION_STRINGS.md"
      ]
    }
  ],
  
  "slashCommands": [
    {
      "name": "db-query",
      "description": "Query database using DbCli",
      "run": "dbcli -c \"${connection}\" query \"${query}\""
    },
    {
      "name": "db-backup",
      "description": "Create table backup",
      "run": "dbcli -c \"${connection}\" export ${table} > ${table}_backup_$(date +%Y%m%d_%H%M%S).sql"
    }
  ]
}
```

---

## 9. Gemini Code Assist

### Setup for Gemini

Create `.gemini/skills.yaml`:

```yaml
skills:
  dbcli:
    version: "1.0.0"
    path: "skills/dbcli"
    enabled: true
    
    capabilities:
      - query_databases
      - modify_data
      - manage_schema
      - backup_restore
      
    safety:
      require_backup_for:
        - UPDATE
        - DELETE
        - DROP
        - ALTER
      
    documentation:
      readme: "skills/dbcli/README.md"
      connection_strings: "skills/dbcli/CONNECTION_STRINGS.md"
      skills:
        - name: "dbcli-query"
          doc: "skills/dbcli/dbcli-query/SKILL.md"
        - name: "dbcli-exec"
          doc: "skills/dbcli/dbcli-exec/SKILL.md"
        - name: "dbcli-db-ddl"
          doc: "skills/dbcli/dbcli-db-ddl/SKILL.md"
        - name: "dbcli-view"
          doc: "skills/dbcli/dbcli-view/SKILL.md"
        - name: "dbcli-index"
          doc: "skills/dbcli/dbcli-index/SKILL.md"
        - name: "dbcli-procedure"
          doc: "skills/dbcli/dbcli-procedure/SKILL.md"
```

---

## 10. Custom Integration

### For Your Own AI Assistant

#### Step 1: Parse Skills Metadata

```python
import yaml
import os

def load_skills(skills_dir):
    """Load all skills from directory"""
    skills = {}
    
    for skill_name in os.listdir(skills_dir):
        skill_path = os.path.join(skills_dir, skill_name)
        skill_file = os.path.join(skill_path, 'SKILL.md')
        
        if os.path.isfile(skill_file):
            with open(skill_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
                # Extract YAML frontmatter
                if content.startswith('---'):
                    _, frontmatter, body = content.split('---', 2)
                    metadata = yaml.safe_load(frontmatter)
                    
                    skills[skill_name] = {
                        'metadata': metadata,
                        'documentation': body.strip()
                    }
    
    return skills

# Load skills
skills = load_skills('skills/dbcli')

# Example: Get skill by name
query_skill = skills.get('dbcli-query')
print(f"Name: {query_skill['metadata']['name']}")
print(f"Description: {query_skill['metadata']['description']}")
print(f"Safety Level: {query_skill['metadata']['safety_level']}")
```

#### Step 2: Create Skill Context for LLM

```python
def create_skill_context(skills, selected_skills=None):
    """Create context string for LLM"""
    if selected_skills is None:
        selected_skills = skills.keys()
    
    context = "# Available Database Skills\n\n"
    
    for skill_name in selected_skills:
        if skill_name in skills:
            skill = skills[skill_name]
            metadata = skill['metadata']
            
            context += f"## {metadata['name']}\n"
            context += f"**Description**: {metadata['description']}\n"
            context += f"**Safety Level**: {metadata.get('safety_level', 'unknown')}\n"
            context += f"**Requires Backup**: {metadata.get('requires_backup', False)}\n\n"
            
            # Add first 500 chars of documentation
            doc_preview = skill['documentation'][:500] + "..."
            context += f"{doc_preview}\n\n"
            context += "---\n\n"
    
    return context

# Use in your LLM prompt
skill_context = create_skill_context(skills, ['dbcli-query', 'dbcli-exec'])
```

#### Step 3: Execute Skill Commands

```python
import subprocess
import json

def execute_dbcli_command(command, connection, db_type='sqlite', sql_or_table=''):
    """Execute dbcli command safely"""
    
    # Build command
    cmd = ['dbcli', '-c', connection]
    
    if db_type:
        cmd.extend(['-t', db_type])
    
    cmd.append(command)
    
    if sql_or_table:
        cmd.append(sql_or_table)
    
    # Execute
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        
        # Try to parse as JSON
        try:
            return json.loads(result.stdout)
        except:
            return result.stdout
            
    except subprocess.CalledProcessError as e:
        return {"error": e.stderr}

# Example usage
result = execute_dbcli_command(
    command='query',
    connection='Data Source=app.db',
    sql_or_table='SELECT * FROM Users'
)

print(result)
```

#### Step 4: Safety Wrapper

```python
from datetime import datetime

def safe_execute(command, connection, sql, require_backup=False):
    """Safely execute command with backup check"""
    
    # Check if backup is required
    dangerous_keywords = ['UPDATE', 'DELETE', 'DROP', 'ALTER', 'TRUNCATE']
    sql_upper = sql.upper()
    
    needs_backup = any(keyword in sql_upper for keyword in dangerous_keywords)
    
    if needs_backup and not require_backup:
        return {
            "error": "This operation requires a backup. Please create a backup first.",
            "suggestion": "Use execute_dbcli_command('export', ...) to create backup"
        }
    
    # Log the operation
    timestamp = datetime.now().isoformat()
    print(f"[{timestamp}] Executing: {command} - {sql[:50]}...")
    
    # Execute
    return execute_dbcli_command(command, connection, sql_or_table=sql)

# Usage
result = safe_execute(
    command='exec',
    connection='Data Source=app.db',
    sql='UPDATE Users SET status="active"',
    require_backup=True  # Must be explicitly set
)
```

---

## Best Practices

### 1. Always Include Safety Context

When integrating skills, always emphasize safety:

```markdown
⚠️ CRITICAL SAFETY RULES:
1. CREATE BACKUP before UPDATE/DELETE/DROP
2. TEST in development first
3. USE transactions where possible
4. VERIFY backups before operations
```

### 2. Provide Connection String Examples

Include database-specific connection strings:

```markdown
**SQLite**: `Data Source=database.db`
**SQL Server**: `Server=localhost;Database=mydb;Trusted_Connection=True`
**MySQL**: `Server=localhost;Database=mydb;Uid=root;Pwd=pass`
**PostgreSQL**: `Host=localhost;Database=mydb;Username=postgres;Password=pass`

See CONNECTION_STRINGS.md for 30+ examples.
```

### 3. Include Code Integration Patterns

Provide language-specific examples:

- Node.js: `execSync()` with JSON parsing
- Python: `subprocess.run()` with JSON parsing
- PowerShell: Native command execution
- Shell: Direct command execution

### 4. Test Integration

Create test scripts to verify skills work:

```bash
# test-integration.sh
#!/bin/bash

echo "Testing DbCli Skills Integration..."

# Test 1: Query
echo "Test 1: Query"
dbcli -c "Data Source=test.db" query "SELECT 'Integration test' as message"

# Test 2: Export (backup)
echo "Test 2: Export"
dbcli -c "Data Source=test.db" export Users > /tmp/test_backup.sql

echo "✅ Integration tests passed!"
```

---

## Troubleshooting

### Skills Not Recognized

**Problem**: AI assistant doesn't see skills

**Solutions**:
1. Check skills directory path is correct
2. Verify SKILL.md files have YAML frontmatter
3. Restart AI assistant/IDE
4. Check permissions on skills directory

### Command Execution Fails

**Problem**: `dbcli: command not found`

**Solutions**:
1. Ensure DbCli is installed: `dbcli --version`
2. Check PATH: `which dbcli` (Linux) or `where dbcli` (Windows)
3. Use full path: `/usr/local/bin/dbcli` or `C:\tools\dbcli\dbcli.exe`

### Skills Context Too Large

**Problem**: LLM context limit exceeded

**Solutions**:
1. Load only needed skills dynamically
2. Use skill summaries instead of full docs
3. Implement skill caching/pagination
4. Create skill index with descriptions only

---

## Resources

- **Agent Skills Spec**: https://agentskills.io/specification
- **Integration Guide**: https://agentskills.io/integrate-skills
- **OpenAI Codex Skills**: https://developers.openai.com/codex/skills
- **Claude Code**: https://anthropic.com/claude
- **GitHub Copilot**: https://github.com/features/copilot

---

## Support

For integration issues:
- **GitHub Issues**: https://github.com/your-repo/dbcli/issues
- **Discussions**: https://github.com/your-repo/dbcli/discussions
- **Documentation**: [README.md](README.md)

---

**License**: MIT  
**Version**: 1.0.0


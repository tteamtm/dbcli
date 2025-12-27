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

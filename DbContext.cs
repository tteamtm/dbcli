using SqlSugar;
using System.Text.RegularExpressions;
using System.IO;

namespace DbCli;

public enum DatabaseType
{
    SQLite,
    SqlServer,
    MySQL,
    PostgreSQL,
    Oracle,
    Dm,              // 达梦
    MongoDB,         // MongoDB
    Kdbndp,          // 人大金仓 (KingbaseES)
    Oscar,           // 神通 (Oscar)
    HighGo,          // 瀚高 (HighGo)
    Access,          // Access
    DB2,             // IBM DB2
    DuckDb,          // DuckDB
    Hana,            // SAP HANA
    OceanBase,       // OceanBase
    TDengine,        // TDengine
    QuestDb,         // QuestDB
    ClickHouse,      // ClickHouse
    MySqlConnector,  // MySqlConnector
    GaussDB,         // 华为 GaussDB
    GBase,           // 南大通用 GBase
    MariaDB,         // MariaDB
    TiDB,            // TiDB
    Odbc,            // ODBC
    Custom           // Custom
}

public class DbConfig
{
    public string ConnectionString { get; set; } = string.Empty;
    public DatabaseType DbType { get; set; } = DatabaseType.SQLite;
}

public class DbContext : IDisposable
{
    private readonly SqlSugarClient _db;

    public SqlSugarClient Db => _db;

    public DbContext(DbConfig config)
    {
        _db = new SqlSugarClient(new ConnectionConfig
        {
            ConnectionString = config.ConnectionString,
            DbType = ConvertDbType(config.DbType),
            IsAutoCloseConnection = true,
            InitKeyType = InitKeyType.Attribute
        });
    }

    public DbContext(string connectionString, DatabaseType dbType)
        : this(new DbConfig { ConnectionString = connectionString, DbType = dbType })
    {
    }

    private static SqlSugar.DbType ConvertDbType(DatabaseType type) => type switch
    {
        DatabaseType.SQLite => SqlSugar.DbType.Sqlite,
        DatabaseType.SqlServer => SqlSugar.DbType.SqlServer,
        DatabaseType.MySQL => SqlSugar.DbType.MySql,
        DatabaseType.PostgreSQL => SqlSugar.DbType.PostgreSQL,
        DatabaseType.Oracle => SqlSugar.DbType.Oracle,
        DatabaseType.Dm => SqlSugar.DbType.Dm,
        DatabaseType.MongoDB => SqlSugar.DbType.MongoDb,
        DatabaseType.Kdbndp => SqlSugar.DbType.Kdbndp,
        DatabaseType.Oscar => SqlSugar.DbType.Oscar,
        DatabaseType.HighGo => SqlSugar.DbType.HG,
        DatabaseType.Access => SqlSugar.DbType.Access,
        DatabaseType.DB2 => SqlSugar.DbType.DB2,
        DatabaseType.DuckDb => SqlSugar.DbType.DuckDB,
        DatabaseType.Hana => SqlSugar.DbType.HANA,
        DatabaseType.OceanBase => SqlSugar.DbType.OceanBase,
        DatabaseType.TDengine => SqlSugar.DbType.TDengine,
        DatabaseType.QuestDb => SqlSugar.DbType.QuestDB,
        DatabaseType.ClickHouse => SqlSugar.DbType.ClickHouse,
        DatabaseType.MySqlConnector => SqlSugar.DbType.MySqlConnector,
        DatabaseType.GaussDB => SqlSugar.DbType.GaussDB,
        DatabaseType.GBase => SqlSugar.DbType.GBase,
        DatabaseType.MariaDB => SqlSugar.DbType.MySql,
        DatabaseType.TiDB => SqlSugar.DbType.MySql,
        DatabaseType.Odbc => SqlSugar.DbType.Odbc,
        DatabaseType.Custom => SqlSugar.DbType.Custom,
        _ => SqlSugar.DbType.Sqlite
    };

    public static DatabaseType ParseDbType(string type)
    {
        return type.ToLower() switch
        {
            "sqlite" => DatabaseType.SQLite,
            "sqlserver" or "mssql" => DatabaseType.SqlServer,
            "mysql" => DatabaseType.MySQL,
            // MySQL-compatible variants
            "mariadb" => DatabaseType.MariaDB,
            "tidb" => DatabaseType.TiDB,
            "percona" or "perconaserver" or "percona-server" => DatabaseType.MySQL,
            "aurora" or "amazon-aurora" or "amazonaurora" => DatabaseType.MySQL,
            "azure-mysql" or "azuremysql" or "azure database for mysql" => DatabaseType.MySQL,
            "gcloud-mysql" or "google-cloud-sql" or "google cloud sql" or "google cloud sql for mysql" => DatabaseType.MySQL,
            "postgresql" or "postgres" or "pgsql" => DatabaseType.PostgreSQL,
            "oracle" => DatabaseType.Oracle,
            "dm" or "dameng" => DatabaseType.Dm,
            "mongodb" or "mongo" => DatabaseType.MongoDB,
            "kdbndp" or "kingbase" or "kingbasees" => DatabaseType.Kdbndp,
            "oscar" or "shentong" => DatabaseType.Oscar,
            "highgo" or "hg" => DatabaseType.HighGo,
            "access" => DatabaseType.Access,
            "db2" => DatabaseType.DB2,
            "duckdb" or "duck" => DatabaseType.DuckDb,
            "hana" => DatabaseType.Hana,
            "oceanbase" => DatabaseType.OceanBase,
            "tdengine" or "td" => DatabaseType.TDengine,
            "questdb" or "quest" => DatabaseType.QuestDb,
            "clickhouse" => DatabaseType.ClickHouse,
            "mysqlconnector" => DatabaseType.MySqlConnector,
            "gaussdb" or "gauss" => DatabaseType.GaussDB,
            "gbase" => DatabaseType.GBase,
            "odbc" => DatabaseType.Odbc,
            "custom" => DatabaseType.Custom,
            _ => throw new ArgumentException($"Unknown database type: {type}")
        };
    }

    public List<Dictionary<string, object>> Query(string sql)
    {
        var dt = _db.Ado.GetDataTable(sql);
        var result = new List<Dictionary<string, object>>();

        foreach (System.Data.DataRow row in dt.Rows)
        {
            var dict = new Dictionary<string, object>();
            foreach (System.Data.DataColumn col in dt.Columns)
            {
                dict[col.ColumnName] = row[col] == DBNull.Value ? null! : row[col];
            }
            result.Add(dict);
        }

        return result;
    }

    public int Execute(string sql)
    {
        return _db.Ado.ExecuteCommand(sql);
    }

    public void ExecuteDdl(string sql)
    {
        if (string.IsNullOrWhiteSpace(sql)) return;

        // Many SQL Server scripts (including export-schema output) use the batch separator "GO".
        // ADO providers don't understand GO, so we split and execute batch-by-batch.
        // Split only on standalone lines containing GO (case-insensitive).
        var batches = Regex.Split(
            sql,
            @"^\s*GO\s*;?\s*$",
            RegexOptions.Multiline | RegexOptions.IgnoreCase);

        foreach (var batch in batches)
        {
            var text = batch.Trim();
            if (text.Length == 0) continue;
            _db.Ado.ExecuteCommand(text);
        }
    }

    public List<string> GetTables()
    {
        var tables = _db.DbMaintenance.GetTableInfoList();
        return tables.Select(t => t.Name).ToList();
    }

    public List<Dictionary<string, object>> GetTableColumns(string tableName)
    {
        var columns = _db.DbMaintenance.GetColumnInfosByTableName(tableName);
        return columns.Select(c => new Dictionary<string, object>
        {
            ["ColumnName"] = c.DbColumnName,
            ["DataType"] = c.DataType,
            ["Length"] = c.Length,
            ["IsNullable"] = c.IsNullable,
            ["IsPrimaryKey"] = c.IsPrimarykey,
            ["DefaultValue"] = c.DefaultValue ?? ""
        }).ToList();
    }

    public string ExportTableData(string tableName, string format = "insert")
    {
        var data = _db.Queryable<dynamic>().AS(tableName).ToList();
        if (data.Count == 0) return string.Empty;

        var columns = _db.DbMaintenance.GetColumnInfosByTableName(tableName);
        var columnNames = columns.Select(c => c.DbColumnName).ToList();

        var sb = new System.Text.StringBuilder();

        foreach (var row in data)
        {
            var dict = (IDictionary<string, object>)row;
            var values = columnNames.Select(col =>
            {
                var val = dict.ContainsKey(col) ? dict[col] : null;
                if (val == null) return "NULL";
                if (val is string s) return $"'{s.Replace("'", "''")}'";
                if (val is DateTime dt) return $"'{dt:yyyy-MM-dd HH:mm:ss}'";
                if (val is bool b) return b ? "1" : "0";
                return val.ToString();
            });

            sb.AppendLine($"INSERT INTO {tableName} ({string.Join(", ", columnNames)}) VALUES ({string.Join(", ", values)});");
        }

        return sb.ToString();
    }

    /// <summary>
    /// Backup table using SqlSugar Fastest bulk operations (preferred) or fallback to SQL
    /// </summary>
    public (bool Success, string Method, int RowCount, string Message) BackupTable(string tableName, string backupTableName)
    {
        try
        {
            var currentDbType = _db.CurrentConnectionConfig.DbType;

            // Check if table exists
            var tables = GetTables();
            if (!tables.Any(t => t.Equals(tableName, StringComparison.OrdinalIgnoreCase)))
            {
                return (false, "None", 0, $"Table '{tableName}' does not exist");
            }

            // SQL Server: use SELECT INTO (CREATE TABLE AS SELECT is not supported).
            // This also avoids identity-insert issues for backup creation.
            if (currentDbType == SqlSugar.DbType.SqlServer)
            {
                try
                {
                    _db.Ado.ExecuteCommand($"DROP TABLE IF EXISTS {backupTableName}");
                }
                catch
                {
                    // ignore
                }

                try
                {
                    _db.Ado.ExecuteCommand($"SELECT * INTO {backupTableName} FROM {tableName}");
                    var count = _db.Ado.GetInt($"SELECT COUNT(*) FROM {backupTableName}");
                    return (true, "SelectInto", count, "Backup created using SQL Server SELECT INTO");
                }
                catch (Exception ex)
                {
                    return (false, "SelectInto", 0, $"SQL Server backup failed: {ex.Message}");
                }
            }

            // Method 1: Try CREATE TABLE AS SELECT + INSERT INTO SELECT (fast and compatible)
            try
            {
                // Create backup table with data in one step
                var rowCount = _db.Ado.ExecuteCommand($"CREATE TABLE {backupTableName} AS SELECT * FROM {tableName}");
                var count = _db.Ado.GetInt($"SELECT COUNT(*) FROM {backupTableName}");
                return (true, "CreateTableAsSelect", count, "Backup created using CREATE TABLE AS SELECT (fast & compatible)");
            }
            catch (Exception createEx)
            {
                // Method 2: Fallback to DataTable + BulkCopy (for databases not supporting CREATE AS SELECT)
                try
                {
                    // Drop backup table if partially created
                    try { _db.Ado.ExecuteCommand($"DROP TABLE IF EXISTS {backupTableName}"); } catch { }
                    
                    // Get table structure
                    var columns = _db.DbMaintenance.GetColumnInfosByTableName(tableName);
                    
                    // Create empty backup table
                    _db.Ado.ExecuteCommand($"CREATE TABLE {backupTableName} AS SELECT * FROM {tableName} WHERE 1=0");
                    
                    // Get data as DataTable
                    var dt = _db.Ado.GetDataTable($"SELECT * FROM {tableName}");
                    
                    if (dt.Rows.Count > 0)
                    {
                        // Use SqlSugar Fastest().BulkCopy with DataTable
                        _db.Fastest<System.Data.DataTable>().AS(backupTableName).BulkCopy(dt);
                        return (true, "Fastest.BulkCopy", dt.Rows.Count, "Backup created using SqlSugar Fastest().BulkCopy with DataTable (fastest for large data)");
                    }
                    return (true, "Fastest.BulkCopy", 0, "Backup table created (empty source table)");
                }
                catch (Exception bulkEx)
                {
                    // Method 3: Manual create + row by row insert (slowest, most compatible)
                    try
                    {
                        // Drop backup table if partially created
                        try { _db.Ado.ExecuteCommand($"DROP TABLE IF EXISTS {backupTableName}"); } catch { }
                        
                        var columns = _db.DbMaintenance.GetColumnInfosByTableName(tableName);
                        
                        // Create table structure manually
                        var createSql = GenerateCreateTableSql(backupTableName, columns);
                        _db.Ado.ExecuteCommand(createSql);
                        
                        // Insert data row by row
                        var data = _db.Queryable<dynamic>().AS(tableName).ToList();
                        var rowCount = 0;
                        foreach (var row in data)
                        {
                            var dict = (IDictionary<string, object>)row;
                            var cols = string.Join(", ", columns.Select(c => c.DbColumnName));
                            var vals = string.Join(", ", columns.Select(c => FormatValue(dict.ContainsKey(c.DbColumnName) ? dict[c.DbColumnName] : null)));
                            _db.Ado.ExecuteCommand($"INSERT INTO {backupTableName} ({cols}) VALUES ({vals})");
                            rowCount++;
                        }
                        return (true, "ManualInsert", rowCount, "Backup created using manual insert (compatibility mode)");
                    }
                    catch (Exception finalEx)
                    {
                        return (false, "Failed", 0, $"All backup methods failed. Create: {createEx.Message}, Bulk: {bulkEx.Message}, Manual: {finalEx.Message}");
                    }
                }
            }
        }
        catch (Exception ex)
        {
            return (false, "Error", 0, ex.Message);
        }
    }

    /// <summary>
    /// Restore table from backup using SqlSugar Fastest bulk operations (preferred) or fallback
    /// </summary>
    public (bool Success, string Method, int RowCount, string Message) RestoreTable(string tableName, string backupTableName, bool deleteFirst = true)
    {
        try
        {
            var currentDbType = _db.CurrentConnectionConfig.DbType;

            // Check if backup table exists
            var tables = GetTables();
            if (!tables.Any(t => t.Equals(backupTableName, StringComparison.OrdinalIgnoreCase)))
            {
                return (false, "None", 0, $"Backup table '{backupTableName}' does not exist");
            }

            // Delete existing data if requested
            if (deleteFirst)
            {
                _db.Ado.ExecuteCommand($"DELETE FROM {tableName}");
            }

            // SQL Server: use explicit column list and handle identity insert when needed.
            if (currentDbType == SqlSugar.DbType.SqlServer)
            {
                try
                {
                    var columns = _db.DbMaintenance.GetColumnInfosByTableName(tableName);
                    var columnNames = columns.Select(c => c.DbColumnName).ToList();
                    if (columnNames.Count == 0)
                        return (false, "SqlServerRestore", 0, $"No columns found for table '{tableName}'");

                    var columnListSql = string.Join(", ", columnNames.Select(c => $"[{c.Replace("]", "]]")}]"));
                    var selectListSql = string.Join(", ", columnNames.Select(c => $"[{c.Replace("]", "]]")}]"));

                    // Identity handling:
                    // IDENTITY_INSERT is session-scoped, so we must keep the same connection.
                    // SqlSugar keeps a single connection open during a transaction.
                    try
                    {
                        _db.Ado.BeginTran();
                        try
                        {
                            _db.Ado.ExecuteCommand($"SET IDENTITY_INSERT {tableName} ON");
                            var rowCount = _db.Ado.ExecuteCommand($"INSERT INTO {tableName} ({columnListSql}) SELECT {selectListSql} FROM {backupTableName}");
                            _db.Ado.ExecuteCommand($"SET IDENTITY_INSERT {tableName} OFF");
                            _db.Ado.CommitTran();
                            return (true, "IdentityInsert", rowCount, "Restored using IDENTITY_INSERT + INSERT ... SELECT (single session)");
                        }
                        catch
                        {
                            _db.Ado.RollbackTran();
                            throw;
                        }
                    }
                    catch (Exception ex)
                    {
                        // If the table has no identity, fall back to normal insert.
                        var msg = ex.Message ?? string.Empty;
                        if (msg.Contains("does not have the identity property", StringComparison.OrdinalIgnoreCase)
                            || msg.Contains("Cannot set IDENTITY_INSERT", StringComparison.OrdinalIgnoreCase))
                        {
                            var inserted = _db.Ado.ExecuteCommand($"INSERT INTO {tableName} ({columnListSql}) SELECT {selectListSql} FROM {backupTableName}");
                            return (true, "InsertSelectColumns", inserted, "Restored using INSERT(column list) ... SELECT");
                        }
                        throw;
                    }
                }
                catch (Exception ex)
                {
                    return (false, "SqlServerRestore", 0, $"SQL Server restore failed: {ex.Message}");
                }
            }

            // Method 1: Try INSERT INTO SELECT (fast and compatible)
            try
            {
                var rowCount = _db.Ado.ExecuteCommand($"INSERT INTO {tableName} SELECT * FROM {backupTableName}");
                return (true, "InsertIntoSelect", rowCount, "Restored using INSERT INTO SELECT (fast & compatible)");
            }
            catch (Exception insertEx)
            {
                // Method 2: Try Fastest().BulkCopy with DataTable (for large data)
                try
                {
                    var dt = _db.Ado.GetDataTable($"SELECT * FROM {backupTableName}");
                    if (dt.Rows.Count > 0)
                    {
                        _db.Fastest<System.Data.DataTable>().AS(tableName).BulkCopy(dt);
                        return (true, "Fastest.BulkCopy", dt.Rows.Count, "Restored using SqlSugar Fastest().BulkCopy with DataTable (fastest for large data)");
                    }
                    return (true, "Fastest.BulkCopy", 0, "Restore completed (empty backup table)");
                }
                catch (Exception bulkEx)
                {
                    // Method 3: Fallback to row by row insert
                    try
                    {
                        var data = _db.Queryable<dynamic>().AS(backupTableName).ToList();
                        var columns = _db.DbMaintenance.GetColumnInfosByTableName(tableName);
                        var rowCount = 0;
                        
                        foreach (var row in data)
                        {
                            var dict = (IDictionary<string, object>)row;
                            var cols = string.Join(", ", columns.Select(c => c.DbColumnName));
                            var vals = string.Join(", ", columns.Select(c => FormatValue(dict.ContainsKey(c.DbColumnName) ? dict[c.DbColumnName] : null)));
                            _db.Ado.ExecuteCommand($"INSERT INTO {tableName} ({cols}) VALUES ({vals})");
                            rowCount++;
                        }
                        return (true, "ManualInsert", rowCount, "Restored using manual insert (compatibility mode)");
                    }
                    catch (Exception finalEx)
                    {
                        return (false, "Failed", 0, $"All restore methods failed. Insert: {insertEx.Message}, Bulk: {bulkEx.Message}, Manual: {finalEx.Message}");
                    }
                }
            }
        }
        catch (Exception ex)
        {
            return (false, "Error", 0, ex.Message);
        }
    }

    private string GenerateCreateTableSql(string tableName, List<DbColumnInfo> columns)
    {
        var columnDefs = columns.Select(c =>
        {
            var nullable = c.IsNullable ? "" : " NOT NULL";
            var primary = c.IsPrimarykey ? " PRIMARY KEY" : "";
            var def = !string.IsNullOrEmpty(c.DefaultValue) ? $" DEFAULT {c.DefaultValue}" : "";
            return $"{c.DbColumnName} {c.DataType}{nullable}{primary}{def}";
        });
        return $"CREATE TABLE {tableName} ({string.Join(", ", columnDefs)})";
    }

    private string FormatValue(object? val)
    {
        if (val == null || val == DBNull.Value) return "NULL";
        if (val is string s) return $"'{s.Replace("'", "''")}'";
        if (val is DateTime dt) return $"'{dt:yyyy-MM-dd HH:mm:ss}'";
        if (val is bool b) return b ? "1" : "0";
        return val.ToString()!;
    }

    private List<string> GetSqlServerIdentityColumns(string tableName)
    {
        // Best-effort identity detection for SQL Server. Assumes current connection is SQL Server.
        // Supports "dbo.Table" or "Table" (schema omitted). When schema is omitted, we search across schemas.
        var raw = tableName.Trim();

        static string Unwrap(string s)
        {
            s = s.Trim();
            if (s.StartsWith("[") && s.EndsWith("]") && s.Length >= 2)
                return s[1..^1];
            return s;
        }

        string? schema;
        string name;

        if (raw.Contains('.'))
        {
            var parts = raw.Split('.', 2);
            schema = Unwrap(parts[0]);
            name = Unwrap(parts[1]);
        }
        else
        {
            schema = null;
            name = Unwrap(raw);
        }

        // Escape single quotes for string literal usage.
        schema = schema?.Replace("'", "''");
        name = name.Replace("'", "''");

        var schemaFilter = schema == null ? "" : $" AND s.name = '{schema}'";

        var sql = $@"
    SELECT c.name
    FROM sys.columns c
    JOIN sys.tables t ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = '{name}'{schemaFilter} AND c.is_identity = 1
    ORDER BY c.column_id";

        try
        {
            var dt = _db.Ado.GetDataTable(sql);
            var list = new List<string>();
            foreach (System.Data.DataRow row in dt.Rows)
            {
                var v = row[0]?.ToString();
                if (!string.IsNullOrWhiteSpace(v)) list.Add(v);
            }
            return list;
        }
        catch
        {
            return new List<string>();
        }
    }

    /// <summary>
    /// Export database schema objects (stored procedures, functions, triggers, views, indexes) as SQL scripts
    /// </summary>
    public string ExportSchemaObjects(string objectType = "all", string? objectName = null)
    {
        var sb = new System.Text.StringBuilder();
        var dbType = _db.CurrentConnectionConfig.DbType;

        sb.AppendLine($"-- Schema Export for {dbType}");
        sb.AppendLine($"-- Generated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
        sb.AppendLine($"-- Object Type: {objectType}");
        sb.AppendLine();

        try
        {
            // Export Stored Procedures
            if (objectType == "all" || objectType == "procedure" || objectType == "proc")
            {
                sb.AppendLine("-- ========================================");
                sb.AppendLine("-- Stored Procedures");
                sb.AppendLine("-- ========================================");
                sb.AppendLine();

                var procedures = GetProcedures(objectName);
                foreach (var proc in procedures)
                {
                    sb.AppendLine($"-- Procedure: {proc}");
                    var procDef = GetProcedureDefinition(proc);
                    sb.AppendLine(procDef);
                    sb.AppendLine("GO");
                    sb.AppendLine();
                }
            }

            // Export Functions
            if (objectType == "all" || objectType == "function" || objectType == "func")
            {
                sb.AppendLine("-- ========================================");
                sb.AppendLine("-- User Functions");
                sb.AppendLine("-- ========================================");
                sb.AppendLine();

                var functions = GetFunctions(objectName);
                foreach (var func in functions)
                {
                    sb.AppendLine($"-- Function: {func}");
                    var funcDef = GetFunctionDefinition(func);
                    sb.AppendLine(funcDef);
                    sb.AppendLine("GO");
                    sb.AppendLine();
                }
            }

            // Export Triggers
            if (objectType == "all" || objectType == "trigger" || objectType == "trig")
            {
                sb.AppendLine("-- ========================================");
                sb.AppendLine("-- Triggers");
                sb.AppendLine("-- ========================================");
                sb.AppendLine();

                var triggers = GetTriggers(objectName);
                foreach (var trigger in triggers)
                {
                    sb.AppendLine($"-- Trigger: {trigger}");
                    var trigDef = GetTriggerDefinition(trigger);
                    sb.AppendLine(trigDef);
                    sb.AppendLine("GO");
                    sb.AppendLine();
                }
            }

            // Export Views
            if (objectType == "all" || objectType == "view")
            {
                sb.AppendLine("-- ========================================");
                sb.AppendLine("-- Views");
                sb.AppendLine("-- ========================================");
                sb.AppendLine();

                var views = GetViews(objectName);
                foreach (var view in views)
                {
                    sb.AppendLine($"-- View: {view}");
                    var viewDef = GetViewDefinition(view);
                    sb.AppendLine(viewDef);
                    sb.AppendLine("GO");
                    sb.AppendLine();
                }
            }

            // Export Indexes
            if (objectType == "all" || objectType == "index" || objectType == "idx")
            {
                sb.AppendLine("-- ========================================");
                sb.AppendLine("-- Indexes");
                sb.AppendLine("-- ========================================");
                sb.AppendLine();

                var tables = GetTables();
                foreach (var table in tables)
                {
                    var indexes = GetTableIndexes(table);
                    if (indexes.Count > 0)
                    {
                        sb.AppendLine($"-- Indexes for table: {table}");
                        foreach (var index in indexes)
                        {
                            sb.AppendLine(index);
                        }
                        sb.AppendLine();
                    }
                }
            }
        }
        catch (Exception ex)
        {
            sb.AppendLine($"-- Error exporting schema: {ex.Message}");
        }

        return sb.ToString();
    }

    public (int FileCount, string OutputDirectory) ExportSchemaObjectsAsFiles(string objectType, string? objectName, string outputDirectory)
    {
        if (string.IsNullOrWhiteSpace(outputDirectory))
            throw new ArgumentException("Output directory is required", nameof(outputDirectory));

        Directory.CreateDirectory(outputDirectory);

        var written = 0;

        static string SafeFileName(string name)
        {
            if (string.IsNullOrWhiteSpace(name)) return "object";
            var invalid = Path.GetInvalidFileNameChars();
            var cleaned = new string(name.Select(ch => invalid.Contains(ch) ? '_' : ch).ToArray());
            cleaned = cleaned.Replace(' ', '_');
            while (cleaned.Contains("__")) cleaned = cleaned.Replace("__", "_");
            return cleaned.Trim('_');
        }

        void WriteOne(string fileName, string contents)
        {
            var full = Path.Combine(outputDirectory, fileName);
            File.WriteAllText(full, contents);
            written++;
        }

        var dbType = _db.CurrentConnectionConfig.DbType;
        var header = string.Join(Environment.NewLine, new[]
        {
            $"-- Schema Export for {dbType}",
            $"-- Generated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}",
            $"-- Object Type: {objectType}",
            ""
        });

        // Stored Procedures
        if (objectType == "all" || objectType == "procedure" || objectType == "proc")
        {
            var procedures = GetProcedures(objectName);
            foreach (var proc in procedures)
            {
                var body = GetProcedureDefinition(proc);
                var text = header +
                           "-- ========================================" + Environment.NewLine +
                           "-- Stored Procedure" + Environment.NewLine +
                           "-- ========================================" + Environment.NewLine + Environment.NewLine +
                           $"-- Procedure: {proc}" + Environment.NewLine +
                           body + Environment.NewLine +
                           "GO" + Environment.NewLine;
                WriteOne($"procedure__{SafeFileName(proc)}.sql", text);
            }
        }

        // Functions
        if (objectType == "all" || objectType == "function" || objectType == "func")
        {
            var functions = GetFunctions(objectName);
            foreach (var func in functions)
            {
                var body = GetFunctionDefinition(func);
                var text = header +
                           "-- ========================================" + Environment.NewLine +
                           "-- User Function" + Environment.NewLine +
                           "-- ========================================" + Environment.NewLine + Environment.NewLine +
                           $"-- Function: {func}" + Environment.NewLine +
                           body + Environment.NewLine +
                           "GO" + Environment.NewLine;
                WriteOne($"function__{SafeFileName(func)}.sql", text);
            }
        }

        // Triggers
        if (objectType == "all" || objectType == "trigger" || objectType == "trig")
        {
            var triggers = GetTriggers(objectName);
            foreach (var trigger in triggers)
            {
                var body = GetTriggerDefinition(trigger);
                var text = header +
                           "-- ========================================" + Environment.NewLine +
                           "-- Trigger" + Environment.NewLine +
                           "-- ========================================" + Environment.NewLine + Environment.NewLine +
                           $"-- Trigger: {trigger}" + Environment.NewLine +
                           body + Environment.NewLine +
                           "GO" + Environment.NewLine;
                WriteOne($"trigger__{SafeFileName(trigger)}.sql", text);
            }
        }

        // Views
        if (objectType == "all" || objectType == "view")
        {
            var views = GetViews(objectName);
            foreach (var view in views)
            {
                var body = GetViewDefinition(view);
                var text = header +
                           "-- ========================================" + Environment.NewLine +
                           "-- View" + Environment.NewLine +
                           "-- ========================================" + Environment.NewLine + Environment.NewLine +
                           $"-- View: {view}" + Environment.NewLine +
                           body + Environment.NewLine +
                           "GO" + Environment.NewLine;
                WriteOne($"view__{SafeFileName(view)}.sql", text);
            }
        }

        // Indexes (grouped by table)
        if (objectType == "all" || objectType == "index" || objectType == "idx")
        {
            var tables = GetTables();
            foreach (var table in tables)
            {
                var indexes = GetTableIndexes(table);
                if (indexes.Count == 0) continue;

                var text = header +
                           "-- ========================================" + Environment.NewLine +
                           "-- Indexes" + Environment.NewLine +
                           "-- ========================================" + Environment.NewLine + Environment.NewLine +
                           $"-- Table: {table}" + Environment.NewLine +
                           string.Join(Environment.NewLine, indexes) + Environment.NewLine;
                WriteOne($"indexes__{SafeFileName(table)}.sql", text);
            }
        }

        return (written, Path.GetFullPath(outputDirectory));
    }

    private List<string> GetProcedures(string? namePattern = null)
    {
        var dbType = _db.CurrentConnectionConfig.DbType;
        try
        {
            return dbType switch
            {
                SqlSugar.DbType.SqlServer => _db.Ado.SqlQuery<string>(
                    namePattern == null 
                        ? "SELECT name FROM sys.procedures ORDER BY name"
                        : $"SELECT name FROM sys.procedures WHERE name LIKE '%{namePattern}%' ORDER BY name").ToList(),
                SqlSugar.DbType.MySql or SqlSugar.DbType.MySqlConnector => _db.Ado.SqlQuery<string>(
                    $"SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='PROCEDURE' AND ROUTINE_SCHEMA=DATABASE()" +
                    (namePattern != null ? $" AND ROUTINE_NAME LIKE '%{namePattern}%'" : "") + " ORDER BY ROUTINE_NAME").ToList(),
                SqlSugar.DbType.PostgreSQL => _db.Ado.SqlQuery<string>(
                    $"SELECT proname FROM pg_proc WHERE prokind='p'" +
                    (namePattern != null ? $" AND proname LIKE '%{namePattern}%'" : "") + " ORDER BY proname").ToList(),
                _ => new List<string>()
            };
        }
        catch { return new List<string>(); }
    }

    private string GetProcedureDefinition(string procName)
    {
        var dbType = _db.CurrentConnectionConfig.DbType;
        try
        {
            return dbType switch
            {
                SqlSugar.DbType.SqlServer => GetSqlServerHelpText(procName),
                SqlSugar.DbType.MySql or SqlSugar.DbType.MySqlConnector => 
                    _db.Ado.GetString($"SHOW CREATE PROCEDURE `{procName}`"),
                SqlSugar.DbType.PostgreSQL => 
                    _db.Ado.GetString($"SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname='{procName}'"),
                _ => $"-- Procedure definition not supported for {dbType}"
            };
        }
        catch (Exception ex)
        {
            return $"-- Error getting procedure definition: {ex.Message}";
        }
    }

    private List<string> GetFunctions(string? namePattern = null)
    {
        var dbType = _db.CurrentConnectionConfig.DbType;
        try
        {
            return dbType switch
            {
                SqlSugar.DbType.SqlServer => _db.Ado.SqlQuery<string>(
                    namePattern == null
                        ? "SELECT name FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') ORDER BY name"
                        : $"SELECT name FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') AND name LIKE '%{namePattern}%' ORDER BY name").ToList(),
                SqlSugar.DbType.MySql or SqlSugar.DbType.MySqlConnector => _db.Ado.SqlQuery<string>(
                    $"SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA=DATABASE()" +
                    (namePattern != null ? $" AND ROUTINE_NAME LIKE '%{namePattern}%'" : "") + " ORDER BY ROUTINE_NAME").ToList(),
                SqlSugar.DbType.PostgreSQL => _db.Ado.SqlQuery<string>(
                    $"SELECT proname FROM pg_proc WHERE prokind='f'" +
                    (namePattern != null ? $" AND proname LIKE '%{namePattern}%'" : "") + " ORDER BY proname").ToList(),
                _ => new List<string>()
            };
        }
        catch { return new List<string>(); }
    }

    private string GetFunctionDefinition(string funcName)
    {
        var dbType = _db.CurrentConnectionConfig.DbType;
        try
        {
            return dbType switch
            {
                SqlSugar.DbType.SqlServer => GetSqlServerHelpText(funcName),
                SqlSugar.DbType.MySql or SqlSugar.DbType.MySqlConnector => 
                    _db.Ado.GetString($"SHOW CREATE FUNCTION `{funcName}`"),
                SqlSugar.DbType.PostgreSQL => 
                    _db.Ado.GetString($"SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname='{funcName}'"),
                _ => $"-- Function definition not supported for {dbType}"
            };
        }
        catch (Exception ex)
        {
            return $"-- Error getting function definition: {ex.Message}";
        }
    }

    private List<string> GetTriggers(string? namePattern = null)
    {
        var dbType = _db.CurrentConnectionConfig.DbType;
        try
        {
            return dbType switch
            {
                SqlSugar.DbType.SqlServer => _db.Ado.SqlQuery<string>(
                    namePattern == null
                        ? "SELECT name FROM sys.triggers WHERE parent_class = 1 ORDER BY name"
                        : $"SELECT name FROM sys.triggers WHERE parent_class = 1 AND name LIKE '%{namePattern}%' ORDER BY name").ToList(),
                SqlSugar.DbType.MySql or SqlSugar.DbType.MySqlConnector => _db.Ado.SqlQuery<string>(
                    $"SELECT TRIGGER_NAME FROM INFORMATION_SCHEMA.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE()" +
                    (namePattern != null ? $" AND TRIGGER_NAME LIKE '%{namePattern}%'" : "") + " ORDER BY TRIGGER_NAME").ToList(),
                SqlSugar.DbType.PostgreSQL => _db.Ado.SqlQuery<string>(
                    $"SELECT tgname FROM pg_trigger WHERE NOT tgisinternal" +
                    (namePattern != null ? $" AND tgname LIKE '%{namePattern}%'" : "") + " ORDER BY tgname").ToList(),
                SqlSugar.DbType.Sqlite => _db.Ado.SqlQuery<string>(
                    $"SELECT name FROM sqlite_master WHERE type='trigger'" +
                    (namePattern != null ? $" AND name LIKE '%{namePattern}%'" : "") + " ORDER BY name").ToList(),
                _ => new List<string>()
            };
        }
        catch { return new List<string>(); }
    }

    private string GetTriggerDefinition(string triggerName)
    {
        var dbType = _db.CurrentConnectionConfig.DbType;
        try
        {
            return dbType switch
            {
                SqlSugar.DbType.SqlServer => GetSqlServerHelpText(triggerName),
                SqlSugar.DbType.MySql or SqlSugar.DbType.MySqlConnector => 
                    _db.Ado.GetString($"SHOW CREATE TRIGGER `{triggerName}`"),
                SqlSugar.DbType.PostgreSQL => 
                    _db.Ado.GetString($"SELECT pg_get_triggerdef(oid) FROM pg_trigger WHERE tgname='{triggerName}'"),
                SqlSugar.DbType.Sqlite => 
                    _db.Ado.GetString($"SELECT sql FROM sqlite_master WHERE type='trigger' AND name='{triggerName}'"),
                _ => $"-- Trigger definition not supported for {dbType}"
            };
        }
        catch (Exception ex)
        {
            return $"-- Error getting trigger definition: {ex.Message}";
        }
    }

    private List<string> GetViews(string? namePattern = null)
    {
        var dbType = _db.CurrentConnectionConfig.DbType;
        try
        {
            return dbType switch
            {
                SqlSugar.DbType.SqlServer => _db.Ado.SqlQuery<string>(
                    namePattern == null
                        ? "SELECT name FROM sys.views ORDER BY name"
                        : $"SELECT name FROM sys.views WHERE name LIKE '%{namePattern}%' ORDER BY name").ToList(),
                SqlSugar.DbType.MySql or SqlSugar.DbType.MySqlConnector => _db.Ado.SqlQuery<string>(
                    $"SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA=DATABASE()" +
                    (namePattern != null ? $" AND TABLE_NAME LIKE '%{namePattern}%'" : "") + " ORDER BY TABLE_NAME").ToList(),
                SqlSugar.DbType.PostgreSQL => _db.Ado.SqlQuery<string>(
                    $"SELECT viewname FROM pg_views WHERE schemaname='public'" +
                    (namePattern != null ? $" AND viewname LIKE '%{namePattern}%'" : "") + " ORDER BY viewname").ToList(),
                SqlSugar.DbType.Sqlite => _db.Ado.SqlQuery<string>(
                    $"SELECT name FROM sqlite_master WHERE type='view'" +
                    (namePattern != null ? $" AND name LIKE '%{namePattern}%'" : "") + " ORDER BY name").ToList(),
                _ => new List<string>()
            };
        }
        catch { return new List<string>(); }
    }

    private string GetViewDefinition(string viewName)
    {
        var dbType = _db.CurrentConnectionConfig.DbType;
        try
        {
            return dbType switch
            {
                SqlSugar.DbType.SqlServer => GetSqlServerHelpText(viewName),
                SqlSugar.DbType.MySql or SqlSugar.DbType.MySqlConnector => 
                    _db.Ado.GetString($"SHOW CREATE VIEW `{viewName}`"),
                SqlSugar.DbType.PostgreSQL => 
                    _db.Ado.GetString($"SELECT definition FROM pg_views WHERE viewname='{viewName}'"),
                SqlSugar.DbType.Sqlite => 
                    _db.Ado.GetString($"SELECT sql FROM sqlite_master WHERE type='view' AND name='{viewName}'"),
                _ => $"-- View definition not supported for {dbType}"
            };
        }
        catch (Exception ex)
        {
            return $"-- Error getting view definition: {ex.Message}";
        }
    }

    private string GetSqlServerHelpText(string objectName)
    {
        try
        {
            var safe = (objectName ?? string.Empty).Replace("'", "''");
            var lines = _db.Ado.SqlQuery<string>($"EXEC sp_helptext '{safe}'");
            return string.Join(Environment.NewLine, lines);
        }
        catch (Exception ex)
        {
            return $"-- Error getting SQL Server definition via sp_helptext: {ex.Message}";
        }
    }

    private List<string> GetTableIndexes(string tableName)
    {
        var dbType = _db.CurrentConnectionConfig.DbType;
        var indexes = new List<string>();
        
        try
        {
            switch (dbType)
            {
                case SqlSugar.DbType.SqlServer:
                    var sqlServerIndexes = _db.Ado.SqlQuery<dynamic>($@"
                        SELECT i.name, i.is_unique, i.type_desc,
                               STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) as columns
                        FROM sys.indexes i
                        INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
                        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
                        WHERE i.object_id = OBJECT_ID('{tableName}') AND i.is_primary_key = 0
                        GROUP BY i.name, i.is_unique, i.type_desc");
                    foreach (var idx in sqlServerIndexes)
                    {
                        var unique = idx.is_unique ? "UNIQUE " : "";
                        indexes.Add($"CREATE {unique}INDEX [{idx.name}] ON [{tableName}] ({idx.columns});");
                    }
                    break;

                case SqlSugar.DbType.MySql:
                case SqlSugar.DbType.MySqlConnector:
                    var mysqlIndexes = _db.Ado.SqlQuery<dynamic>($"SHOW INDEX FROM `{tableName}` WHERE Key_name != 'PRIMARY'");
                    var groupedIndexes = mysqlIndexes.GroupBy(x => x.Key_name);
                    foreach (var group in groupedIndexes)
                    {
                        var first = group.First();
                        var unique = first.Non_unique == 0 ? "UNIQUE " : "";
                        var columns = string.Join(", ", group.OrderBy(x => x.Seq_in_index).Select(x => $"`{x.Column_name}`"));
                        indexes.Add($"CREATE {unique}INDEX `{first.Key_name}` ON `{tableName}` ({columns});");
                    }
                    break;

                case SqlSugar.DbType.Sqlite:
                    var sqliteIndexes = _db.Ado.SqlQuery<string>($"SELECT sql FROM sqlite_master WHERE type='index' AND tbl_name='{tableName}' AND sql IS NOT NULL");
                    indexes.AddRange(sqliteIndexes.Select(sql => sql + ";"));
                    break;

                case SqlSugar.DbType.PostgreSQL:
                    var pgIndexes = _db.Ado.SqlQuery<string>($@"
                        SELECT indexdef FROM pg_indexes 
                        WHERE tablename = '{tableName}' AND schemaname = 'public'");
                    indexes.AddRange(pgIndexes.Select(sql => sql + ";"));
                    break;
            }
        }
        catch (Exception ex)
        {
            indexes.Add($"-- Error getting indexes for {tableName}: {ex.Message}");
        }

        return indexes;
    }

    public void Dispose()
    {
        _db?.Dispose();
    }
}

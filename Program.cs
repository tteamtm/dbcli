using ConsoleAppFramework;
using System.Text.Json;
using DbCli;

var app = ConsoleApp.Create();
app.Add<Commands>();
app.Run(NormalizeArgs(args));

static string[] NormalizeArgs(string[] args)
{
    if (args.Length == 0) return args;

    // ConsoleAppFramework routes by args[0] (command name).
    // For backward compatibility with the previous CLI (global options before subcommand),
    // rewrite: "-c ... -t ... query ..." -> "query -c ... -t ... ...".
    if (!args[0].StartsWith('-')) return args;

    static bool IsKnownLeadingOption(string s)
        => s is "-c" or "--connection"
            or "-t" or "--db-type"
            or "-f" or "--format"
            or "-F" or "--file"
            or "--config"
            or "-n" or "--name"
            or "-o" or "--output"
            or "--output-dir";

    var leading = new List<string>();
    var i = 0;

    while (i < args.Length)
    {
        var token = args[i];

        if (token == "--") break;
        if (!token.StartsWith('-')) break;
        if (!IsKnownLeadingOption(token)) break;

        // All supported leading options require a value.
        if (i + 1 >= args.Length) return args;
        leading.Add(token);
        leading.Add(args[i + 1]);
        i += 2;
    }

    if (leading.Count == 0) return args;
    if (i >= args.Length) return args;

    var command = args[i];
    var rebuilt = new List<string>(1 + leading.Count + (args.Length - i - 1))
    {
        command
    };
    rebuilt.AddRange(leading);
    for (var j = i + 1; j < args.Length; j++) rebuilt.Add(args[j]);
    return rebuilt.ToArray();
}

internal class Commands
{
    /// <summary>Execute SELECT query and return results</summary>
    /// <param name="sql">SQL statement to execute</param>
    /// <param name="file">-F, Read SQL from file</param>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("query|q")]
    public void Query(
        [Argument] string sql = "",
        string? file = null,
        string? connection = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var sqlText = GetSql(sql, file);
        var outputFormat = OutputFormatter.ParseFormat(format);

        if (string.IsNullOrWhiteSpace(sqlText))
        {
            Console.WriteLine(OutputFormatter.FormatError("SQL statement is required", outputFormat));
            Environment.ExitCode = 1;
            return;
        }

        try
        {
            using var db = CreateContext(connection, dbType, config);
            var result = db.Query(sqlText);
            Console.WriteLine(OutputFormatter.Format(result, outputFormat));
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Execute DML statement (INSERT/UPDATE/DELETE)</summary>
    /// <param name="sql">SQL statement to execute</param>
    /// <param name="file">-F, Read SQL from file</param>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("exec|e")]
    public void Exec(
        [Argument] string sql = "",
        string? file = null,
        string? connection = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var sqlText = GetSql(sql, file);
        var outputFormat = OutputFormatter.ParseFormat(format);

        if (string.IsNullOrWhiteSpace(sqlText))
        {
            Console.WriteLine(OutputFormatter.FormatError("SQL statement is required", outputFormat));
            Environment.ExitCode = 1;
            return;
        }

        try
        {
            using var db = CreateContext(connection, dbType, config);
            var affected = db.Execute(sqlText);
            Console.WriteLine(OutputFormatter.FormatResult(affected, outputFormat));
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Execute DDL statement (CREATE/ALTER/DROP)</summary>
    /// <param name="sql">SQL statement to execute</param>
    /// <param name="file">-F, Read SQL from file</param>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("ddl")]
    public void Ddl(
        [Argument] string sql = "",
        string? file = null,
        string? connection = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var sqlText = GetSql(sql, file);
        var outputFormat = OutputFormatter.ParseFormat(format);

        if (string.IsNullOrWhiteSpace(sqlText))
        {
            Console.WriteLine(OutputFormatter.FormatError("SQL statement is required", outputFormat));
            Environment.ExitCode = 1;
            return;
        }

        try
        {
            using var db = CreateContext(connection, dbType, config);
            db.ExecuteDdl(sqlText);
            Console.WriteLine(outputFormat == OutputFormat.Json
                ? JsonSerializer.Serialize(new { Success = true, Message = "DDL executed successfully" })
                : "DDL executed successfully");
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>List all tables in the database</summary>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("tables|ls")]
    public void Tables(
        string? connection = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var outputFormat = OutputFormatter.ParseFormat(format);

        try
        {
            using var db = CreateContext(connection, dbType, config);
            var tables = db.GetTables();
            var result = tables.Select(t => new Dictionary<string, object> { ["TableName"] = t }).ToList();
            Console.WriteLine(OutputFormatter.Format(result, outputFormat));
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Show columns of a table</summary>
    /// <param name="table">Table name</param>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("columns|cols")]
    public void Columns(
        [Argument] string table,
        string? connection = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var outputFormat = OutputFormatter.ParseFormat(format);

        try
        {
            using var db = CreateContext(connection, dbType, config);
            var columns = db.GetTableColumns(table);
            Console.WriteLine(OutputFormatter.Format(columns, outputFormat));
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Export table data as INSERT statements</summary>
    /// <param name="table">Table name</param>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="config">Path to configuration file</param>
    [Command("export")]
    public void Export(
        [Argument] string table,
        string? connection = null,
        string dbType = "sqlite",
        string? config = null)
    {
        try
        {
            using var db = CreateContext(connection, dbType, config);
            var sql = db.ExportTableData(table);
            Console.WriteLine(sql);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"-- Error: {ex.Message}");
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Backup table using bulk operations (preferred)</summary>
    /// <param name="table">Source table name</param>
    /// <param name="target">-o, Backup table name</param>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("backup")]
    public void Backup(
        [Argument] string table,
        string? target = null,
        string? connection = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var outputFormat = OutputFormatter.ParseFormat(format);
        
        // Generate backup table name if not specified
        if (string.IsNullOrEmpty(target))
        {
            var timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            target = $"{table}_backup_{timestamp}";
        }

        try
        {
            using var db = CreateContext(connection, dbType, config);
            var result = db.BackupTable(table, target);
            
            if (outputFormat == OutputFormat.Json)
            {
                Console.WriteLine(JsonSerializer.Serialize(new
                {
                    result.Success,
                    result.Method,
                    result.RowCount,
                    result.Message,
                    SourceTable = table,
                    BackupTable = target
                }));

                if (!result.Success)
                {
                    Environment.ExitCode = 1;
                }
            }
            else
            {
                if (result.Success)
                {
                    Console.WriteLine($"✅ Backup successful!");
                    Console.WriteLine($"   Source: {table}");
                    Console.WriteLine($"   Backup: {target}");
                    Console.WriteLine($"   Method: {result.Method}");
                    Console.WriteLine($"   Rows:   {result.RowCount}");
                    Console.WriteLine($"   Info:   {result.Message}");
                }
                else
                {
                    Console.WriteLine($"❌ Backup failed: {result.Message}");
                    Environment.ExitCode = 1;
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Restore table from backup using bulk operations</summary>
    /// <param name="table">Target table name to restore</param>
    /// <param name="from">-s, Backup table name to restore from (required)</param>
    /// <param name="keepData">-k, Keep existing data</param>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("restore")]
    public void Restore(
        [Argument] string table,
        string? from = null,
        bool keepData = false,
        string? connection = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var outputFormat = OutputFormatter.ParseFormat(format);

        // Validate required parameter
        if (string.IsNullOrEmpty(from))
        {
            Console.WriteLine(OutputFormatter.FormatError("Option '--from' is required", outputFormat));
            Environment.ExitCode = 1;
            return;
        }

        try
        {
            using var db = CreateContext(connection, dbType, config);
            var result = db.RestoreTable(table, from, !keepData);
            
            if (outputFormat == OutputFormat.Json)
            {
                Console.WriteLine(JsonSerializer.Serialize(new
                {
                    result.Success,
                    result.Method,
                    result.RowCount,
                    result.Message,
                    TargetTable = table,
                    SourceBackup = from,
                    DeletedFirst = !keepData
                }));

                if (!result.Success)
                {
                    Environment.ExitCode = 1;
                }
            }
            else
            {
                if (result.Success)
                {
                    Console.WriteLine($"✅ Restore successful!");
                    Console.WriteLine($"   Target:  {table}");
                    Console.WriteLine($"   Source:  {from}");
                    Console.WriteLine($"   Method:  {result.Method}");
                    Console.WriteLine($"   Rows:    {result.RowCount}");
                    Console.WriteLine($"   Deleted: {!keepData}");
                    Console.WriteLine($"   Info:    {result.Message}");
                }
                else
                {
                    Console.WriteLine($"❌ Restore failed: {result.Message}");
                    Environment.ExitCode = 1;
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Export database schema objects as SQL scripts</summary>
    /// <param name="type">Object type: all, procedure, function, trigger, view, index</param>
    /// <param name="name">-n, Filter by object name</param>
    /// <param name="output">-o, Save to file</param>
    /// <param name="outputDir">Save as separate files under this directory (per object)</param>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="config">Path to configuration file</param>
    [Command("export-schema|schema")]
    public void ExportSchema(
        [Argument] string type = "all",
        string? name = null,
        string? output = null,
        string? outputDir = null,
        string? connection = null,
        string dbType = "sqlite",
        string? config = null)
    {
        try
        {
            using var db = CreateContext(connection, dbType, config);

            if (!string.IsNullOrEmpty(outputDir))
            {
                var exported = db.ExportSchemaObjectsAsFiles(type, name, outputDir);
                Console.WriteLine($"✅ Schema exported to directory: {Path.GetFullPath(outputDir)}");
                Console.WriteLine($"   Files: {exported.FileCount}");
                return;
            }

            var script = db.ExportSchemaObjects(type, name);
            if (!string.IsNullOrEmpty(output))
            {
                File.WriteAllText(output, script);
                Console.WriteLine($"✅ Schema exported to: {output}");
                return;
            }

            Console.WriteLine(script);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Enter interactive SQL mode</summary>
    /// <param name="connection">-c, Database connection string</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("interactive|i")]
    public void Interactive(
        string? connection = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        Console.WriteLine("DbCli Interactive Mode");
        Console.WriteLine("Type 'exit' or 'quit' to exit, 'help' for commands");
        Console.WriteLine(new string('-', 50));

        var outputFormat = OutputFormatter.ParseFormat(format);
        using var db = CreateContext(connection, dbType, config);

        while (true)
        {
            Console.Write("dbcli> ");
            var input = Console.ReadLine()?.Trim();

            if (string.IsNullOrEmpty(input))
                continue;

            var lower = input.ToLower();
            if (lower == "exit" || lower == "quit" || lower == "q")
                break;

            if (lower == "help" || lower == "?")
            {
                Console.WriteLine("Commands:");
                Console.WriteLine("  .tables          - List all tables");
                Console.WriteLine("  .columns <table> - Show table columns");
                Console.WriteLine("  .format <type>   - Set output format (json/table/csv)");
                Console.WriteLine("  exit/quit        - Exit interactive mode");
                Console.WriteLine("  Any SQL          - Execute SQL statement");
                continue;
            }

            if (lower == ".tables")
            {
                try
                {
                    var tables = db.GetTables();
                    foreach (var t in tables)
                        Console.WriteLine(t);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error: {ex.Message}");
                }
                continue;
            }

            if (lower.StartsWith(".columns "))
            {
                var tableName = input[9..].Trim();
                try
                {
                    var columns = db.GetTableColumns(tableName);
                    Console.WriteLine(OutputFormatter.Format(columns, outputFormat));
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error: {ex.Message}");
                }
                continue;
            }

            if (lower.StartsWith(".format "))
            {
                var newFormat = input[8..].Trim();
                outputFormat = OutputFormatter.ParseFormat(newFormat);
                Console.WriteLine($"Output format set to: {outputFormat}");
                continue;
            }

            try
            {
                if (lower.StartsWith("select") || lower.StartsWith("with") || lower.StartsWith("show") || lower.StartsWith("describe") || lower.StartsWith("pragma"))
                {
                    var result = db.Query(input);
                    Console.WriteLine(OutputFormatter.Format(result, outputFormat));
                }
                else
                {
                    var affected = db.Execute(input);
                    Console.WriteLine($"Affected rows: {affected}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
            }
        }

        Console.WriteLine("Goodbye!");
    }

    private static DbContext CreateContext(string? connection, string dbType, string? configPath)
    {
        if (!string.IsNullOrEmpty(configPath) && File.Exists(configPath))
        {
            var json = File.ReadAllText(configPath);
            var config = JsonSerializer.Deserialize<JsonElement>(json);
            if (config.TryGetProperty("ConnectionString", out var connStr))
                connection = connStr.GetString();
            if (config.TryGetProperty("DbType", out var type))
                dbType = type.GetString()!;
        }

        if (string.IsNullOrEmpty(connection))
        {
            connection = Environment.GetEnvironmentVariable("DBCLI_CONNECTION") ?? "Data Source=dbcli.db";
        }

        var envDbType = Environment.GetEnvironmentVariable("DBCLI_DBTYPE");
        if (!string.IsNullOrEmpty(envDbType))
            dbType = envDbType;

        return new DbContext(connection, DbContext.ParseDbType(dbType));
    }

    private static string GetSql(string argValue, string? file)
    {
        if (!string.IsNullOrEmpty(file) && File.Exists(file))
            return File.ReadAllText(file);
        return argValue;
    }
}

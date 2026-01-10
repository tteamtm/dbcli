using ConsoleAppFramework;
using System.Text.Json;
using System.Text.RegularExpressions;
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
            or "-p" or "--params"
            or "-P" or "--params-file"
            or "--config"
            or "-n" or "--name"
            or "--scope"
            or "--owner"
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
    // Sanitize error messages to prevent sensitive information leakage
    private static string SanitizeErrorMessage(string message)
    {
        // Remove password from connection strings
        var patterns = new[]
        {
            @"Password\s*=\s*[^;]+",
            @"Pwd\s*=\s*[^;]+",
            @"PWD\s*=\s*[^;]+",
            @"password\s*=\s*[^;]+",
            @"pwd\s*=\s*[^;]+"
        };
        
        foreach (var pattern in patterns)
        {
            message = Regex.Replace(message, pattern, "Password=***", RegexOptions.IgnoreCase);
        }
        
        return message;
    }

    /// <summary>Execute SELECT query and return results</summary>
    /// <param name="sql">SQL statement to execute</param>
    /// <param name="file">-F, Read SQL from file</param>
    /// <param name="parameters">-p, SQL parameters in JSON object</param>
    /// <param name="paramsFile">-P, Read SQL parameters from JSON file</param>
    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("query|q")]
    public void Query(
        [Argument] string sql = "",
        string? file = null,
        string? parameters = null,
        string? paramsFile = null,
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
            using var db = CreateContext(null, dbType, config);
            var sqlParams = GetSqlParams(parameters, paramsFile, outputFormat, out var paramsError);
            if (!string.IsNullOrEmpty(paramsError))
            {
                Console.WriteLine(OutputFormatter.FormatError(paramsError, outputFormat));
                Environment.ExitCode = 1;
                return;
            }
            if (sqlParams != null && !db.SupportsParameters())
            {
                Console.WriteLine(OutputFormatter.FormatError("Parameterized queries are not supported for this database type", outputFormat));
                Environment.ExitCode = 1;
                return;
            }
            var result = sqlParams == null ? db.Query(sqlText) : db.Query(sqlText, sqlParams);
            Console.WriteLine(OutputFormatter.Format(result, outputFormat));
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(SanitizeErrorMessage(ex.Message), outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Execute DML statement (INSERT/UPDATE/DELETE)</summary>
    /// <param name="sql">SQL statement to execute</param>
    /// <param name="file">-F, Read SQL from file</param>
    /// <param name="parameters">-p, SQL parameters in JSON object</param>
    /// <param name="paramsFile">-P, Read SQL parameters from JSON file</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("exec|e")]
    public void Exec(
        [Argument] string sql = "",
        string? file = null,
        string? parameters = null,
        string? paramsFile = null,
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
            using var db = CreateContext(null, dbType, config);
            var sqlParams = GetSqlParams(parameters, paramsFile, outputFormat, out var paramsError);
            if (!string.IsNullOrEmpty(paramsError))
            {
                Console.WriteLine(OutputFormatter.FormatError(paramsError, outputFormat));
                Environment.ExitCode = 1;
                return;
            }
            if (sqlParams != null && !db.SupportsParameters())
            {
                Console.WriteLine(OutputFormatter.FormatError("Parameterized statements are not supported for this database type", outputFormat));
                Environment.ExitCode = 1;
                return;
            }
            if (sqlParams != null && ContainsGoBatch(sqlText))
            {
                Console.WriteLine(OutputFormatter.FormatError("GO batch separator is not supported with parameters", outputFormat));
                Environment.ExitCode = 1;
                return;
            }

            var affected = sqlParams == null && db.SupportsGoBatches() && ContainsGoBatch(sqlText)
                ? db.ExecuteWithGo(sqlText)
                : (sqlParams == null ? db.Execute(sqlText) : db.Execute(sqlText, sqlParams));
            Console.WriteLine(OutputFormatter.FormatResult(affected, outputFormat));
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(SanitizeErrorMessage(ex.Message), outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Execute DDL statement (CREATE/ALTER/DROP)</summary>
    /// <param name="sql">SQL statement to execute</param>
    /// <param name="file">-F, Read SQL from file</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("ddl")]
    public void Ddl(
        [Argument] string sql = "",
        string? file = null,
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
            using var db = CreateContext(null, dbType, config);
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

    /// <summary>List all tables in the database</summary>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("tables|ls")]
    public void Tables(
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var outputFormat = OutputFormatter.ParseFormat(format);

        try
        {
            using var db = CreateContext(null, dbType, config);
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

    /// <summary>Execute stored procedure (non-query)</summary>
    /// <param name="name">Stored procedure name</param>
    /// <param name="parameters">-p, SQL parameters in JSON object</param>
    /// <param name="paramsFile">-P, Read SQL parameters from JSON file</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("proc|procedure|sproc")]
    public void Procedure(
        [Argument] string name,
        string? parameters = null,
        string? paramsFile = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var outputFormat = OutputFormatter.ParseFormat(format);

        if (string.IsNullOrWhiteSpace(name))
        {
            Console.WriteLine(OutputFormatter.FormatError("Procedure name is required", outputFormat));
            Environment.ExitCode = 1;
            return;
        }

        try
        {
            using var db = CreateContext(null, dbType, config);
            var sqlParams = GetSqlParams(parameters, paramsFile, outputFormat, out var paramsError);
            if (!string.IsNullOrEmpty(paramsError))
            {
                Console.WriteLine(OutputFormatter.FormatError(paramsError, outputFormat));
                Environment.ExitCode = 1;
                return;
            }
            if (sqlParams != null && !db.SupportsParameters())
            {
                Console.WriteLine(OutputFormatter.FormatError("Parameterized statements are not supported for this database type", outputFormat));
                Environment.ExitCode = 1;
                return;
            }

            var affected = db.ExecuteStoredProcedure(name, sqlParams);
            Console.WriteLine(OutputFormatter.FormatResult(affected, outputFormat));
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Execute stored procedure and return result set</summary>
    /// <param name="name">Stored procedure name</param>
    /// <param name="parameters">-p, SQL parameters in JSON object</param>
    /// <param name="paramsFile">-P, Read SQL parameters from JSON file</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("proc-query|procedure-query|sproc-query")]
    public void ProcedureQuery(
        [Argument] string name,
        string? parameters = null,
        string? paramsFile = null,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var outputFormat = OutputFormatter.ParseFormat(format);

        if (string.IsNullOrWhiteSpace(name))
        {
            Console.WriteLine(OutputFormatter.FormatError("Procedure name is required", outputFormat));
            Environment.ExitCode = 1;
            return;
        }

        try
        {
            using var db = CreateContext(null, dbType, config);
            var sqlParams = GetSqlParams(parameters, paramsFile, outputFormat, out var paramsError);
            if (!string.IsNullOrEmpty(paramsError))
            {
                Console.WriteLine(OutputFormatter.FormatError(paramsError, outputFormat));
                Environment.ExitCode = 1;
                return;
            }
            if (sqlParams != null && !db.SupportsParameters())
            {
                Console.WriteLine(OutputFormatter.FormatError("Parameterized queries are not supported for this database type", outputFormat));
                Environment.ExitCode = 1;
                return;
            }

            var result = db.QueryStoredProcedure(name, sqlParams);
            Console.WriteLine(OutputFormatter.Format(result, outputFormat));
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>List views in the database</summary>
    /// <param name="name">-n, Filter by view name (LIKE %name%)</param>
    /// <param name="owner">Filter by schema/owner</param>
    /// <param name="scope">Scope: user|all|dba (default: user)</param>
    /// <param name="withDefinition">Include view definition text</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("views|view")]
    public void Views(
        string? name = null,
        string? owner = null,
        string scope = "user",
        bool withDefinition = false,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var outputFormat = OutputFormatter.ParseFormat(format);

        try
        {
            using var db = CreateContext(null, dbType, config);
            var result = db.GetViewsInfo(scope, owner, name, withDefinition);
            Console.WriteLine(OutputFormatter.Format(result, outputFormat));
        }
        catch (Exception ex)
        {
            Console.WriteLine(OutputFormatter.FormatError(ex.Message, outputFormat));
            Environment.ExitCode = 1;
        }
    }

    /// <summary>Show columns of a table</summary>
    /// <param name="table">Table name</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("columns|cols")]
    public void Columns(
        [Argument] string table,
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        var outputFormat = OutputFormatter.ParseFormat(format);

        try
        {
            using var db = CreateContext(null, dbType, config);
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
    /// <param name="table">Table name</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="config">Path to configuration file</param>
    [Command("export")]
    public void Export(
        [Argument] string table,
        string dbType = "sqlite",
        string? config = null)
    {
        try
        {
            using var db = CreateContext(null, dbType, config);
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
    /// <param name="target">-o, Backup table name</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("backup")]
    public void Backup(
        [Argument] string table,
        string? target = null,
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
            using var db = CreateContext(null, dbType, config);
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
    /// <param name="keepData">-k, Keep existing data</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("restore")]
    public void Restore(
        [Argument] string table,
        string? from = null,
        bool keepData = false,
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
            using var db = CreateContext(null, dbType, config);
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
    /// <param name="outputDir">Save as separate files under this directory (per object)</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="config">Path to configuration file</param>
    [Command("export-schema|schema")]
    public void ExportSchema(
        [Argument] string type = "all",
        string? name = null,
        string? output = null,
        string? outputDir = null,
        string dbType = "sqlite",
        string? config = null)
    {
        try
        {
            using var db = CreateContext(null, dbType, config);

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

    /// <summary>Enter interactive SQL mode</summary>    /// <param name="dbType">-t, Database type</param>
    /// <param name="format">-f, Output format: json, table, csv</param>
    /// <param name="config">Path to configuration file</param>
    [Command("interactive|i")]
    public void Interactive(
        string dbType = "sqlite",
        string format = "json",
        string? config = null)
    {
        Console.WriteLine("DbCli Interactive Mode");
        Console.WriteLine("Type '.exit' or '.quit' to exit, '.help' for commands");
        Console.WriteLine("End SQL with ';' or press Enter on a blank line to execute");
        Console.WriteLine(new string('-', 50));

        var outputFormat = OutputFormatter.ParseFormat(format);
        using var db = CreateContext(null, dbType, config);
        var buffer = new System.Text.StringBuilder();

        while (true)
        {
            Console.Write(buffer.Length == 0 ? "dbcli> " : "...> ");
            var line = Console.ReadLine();

            if (line is null)
                break;

            if (string.IsNullOrWhiteSpace(line))
            {
                if (buffer.Length == 0)
                    continue;

                ExecuteBufferedStatement(buffer, db, ref outputFormat);
                continue;
            }

            var trimmed = line.Trim();

            if (buffer.Length == 0 && trimmed.StartsWith('.'))
            {
                var tokens = SplitArgs(trimmed);
                if (tokens.Count == 0)
                    continue;

                var command = tokens[0].ToLowerInvariant();

                if (command is ".exit" or ".quit")
                    break;

                if (command is ".help" or ".?")
                {
                    PrintInteractiveHelp();
                    continue;
                }

                if (command == ".tables")
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

                if (command == ".views")
                {
                    var scope = "user";
                    string? owner = null;
                    string? name = null;
                    var withDefinition = false;
                    var parseError = false;

                    for (var i = 1; i < tokens.Count; i++)
                    {
                        var opt = tokens[i];
                        switch (opt)
                        {
                            case "-n":
                            case "--name":
                                if (i + 1 >= tokens.Count)
                                {
                                    Console.WriteLine("Error: name pattern is required after -n/--name");
                                    parseError = true;
                                    break;
                                }
                                name = tokens[++i];
                                break;
                            case "--owner":
                                if (i + 1 >= tokens.Count)
                                {
                                    Console.WriteLine("Error: owner is required after --owner");
                                    parseError = true;
                                    break;
                                }
                                owner = tokens[++i];
                                break;
                            case "--scope":
                                if (i + 1 >= tokens.Count)
                                {
                                    Console.WriteLine("Error: scope is required after --scope");
                                    parseError = true;
                                    break;
                                }
                                scope = tokens[++i];
                                break;
                            case "--with-definition":
                            case "--definition":
                                withDefinition = true;
                                break;
                            default:
                                Console.WriteLine($"Error: unknown option '{opt}'");
                                parseError = true;
                                break;
                        }

                        if (parseError)
                            break;
                    }

                    if (parseError)
                        continue;

                    try
                    {
                        var views = db.GetViewsInfo(scope, owner, name, withDefinition);
                        Console.WriteLine(OutputFormatter.Format(views, outputFormat));
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error: {ex.Message}");
                    }
                    continue;
                }

                if (command == ".columns")
                {
                    if (tokens.Count < 2)
                    {
                        Console.WriteLine("Usage: .columns <table>");
                        continue;
                    }

                    var tableName = tokens[1];
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

                if (command == ".format")
                {
                    if (tokens.Count < 2)
                    {
                        Console.WriteLine("Usage: .format <json|table|csv>");
                        continue;
                    }

                    var newFormat = tokens[1];
                    outputFormat = OutputFormatter.ParseFormat(newFormat);
                    Console.WriteLine($"Output format set to: {outputFormat}");
                    continue;
                }

                if (command is ".query" or ".q")
                {
                    var sqlText = trimmed[tokens[0].Length..].Trim();
                    if (string.IsNullOrWhiteSpace(sqlText))
                    {
                        Console.WriteLine("Error: SQL statement is required");
                        continue;
                    }

                    try
                    {
                        var result = db.Query(sqlText);
                        Console.WriteLine(OutputFormatter.Format(result, outputFormat));
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error: {ex.Message}");
                    }
                    continue;
                }

                if (command is ".exec" or ".e")
                {
                    var sqlText = trimmed[tokens[0].Length..].Trim();
                    if (string.IsNullOrWhiteSpace(sqlText))
                    {
                        Console.WriteLine("Error: SQL statement is required");
                        continue;
                    }

                    try
                    {
                        var affected = db.Execute(sqlText);
                        Console.WriteLine($"Affected rows: {affected}");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error: {ex.Message}");
                    }
                    continue;
                }

                if (command == ".ddl")
                {
                    var sqlText = trimmed[tokens[0].Length..].Trim();
                    if (string.IsNullOrWhiteSpace(sqlText))
                    {
                        Console.WriteLine("Error: SQL statement is required");
                        continue;
                    }

                    try
                    {
                        db.ExecuteDdl(sqlText);
                        Console.WriteLine("DDL executed successfully");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error: {ex.Message}");
                    }
                    continue;
                }

                if (command == ".export")
                {
                    if (tokens.Count < 2)
                    {
                        Console.WriteLine("Usage: .export <table> [output]");
                        continue;
                    }

                    var tableName = tokens[1];
                    string? outputPath = null;

                    if (tokens.Count >= 3)
                    {
                        if (tokens[2] is "-o" or "--output")
                        {
                            if (tokens.Count < 4)
                            {
                                Console.WriteLine("Error: output path is required after -o/--output");
                                continue;
                            }
                            outputPath = tokens[3];
                        }
                        else
                        {
                            outputPath = tokens[2];
                        }
                    }

                    try
                    {
                        var sql = db.ExportTableData(tableName);
                        if (string.IsNullOrEmpty(outputPath))
                        {
                            Console.WriteLine(sql);
                        }
                        else
                        {
                            File.WriteAllText(outputPath, sql);
                            Console.WriteLine($"Exported to: {outputPath}");
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error: {ex.Message}");
                    }
                    continue;
                }

                if (command is ".export-schema" or ".schema")
                {
                    var type = "all";
                    var index = 1;
                    if (tokens.Count > 1 && !tokens[1].StartsWith('-'))
                    {
                        type = tokens[1];
                        index = 2;
                    }

                    string? name = null;
                    string? output = null;
                    string? outputDir = null;
                    var parseError = false;

                    for (var i = index; i < tokens.Count; i++)
                    {
                        var opt = tokens[i];
                        switch (opt)
                        {
                            case "-n":
                            case "--name":
                                if (i + 1 >= tokens.Count)
                                {
                                    Console.WriteLine("Error: name pattern is required after -n/--name");
                                    parseError = true;
                                    break;
                                }
                                name = tokens[++i];
                                break;
                            case "-o":
                            case "--output":
                                if (i + 1 >= tokens.Count)
                                {
                                    Console.WriteLine("Error: output path is required after -o/--output");
                                    parseError = true;
                                    break;
                                }
                                output = tokens[++i];
                                break;
                            case "--output-dir":
                                if (i + 1 >= tokens.Count)
                                {
                                    Console.WriteLine("Error: directory is required after --output-dir");
                                    parseError = true;
                                    break;
                                }
                                outputDir = tokens[++i];
                                break;
                            default:
                                Console.WriteLine($"Error: unknown option '{opt}'");
                                parseError = true;
                                break;
                        }

                        if (parseError)
                            break;
                    }

                    if (parseError)
                        continue;

                    try
                    {
                        if (!string.IsNullOrEmpty(outputDir))
                        {
                            var exported = db.ExportSchemaObjectsAsFiles(type, name, outputDir);
                            Console.WriteLine($"Schema exported to directory: {Path.GetFullPath(outputDir)}");
                            Console.WriteLine($"Files: {exported.FileCount}");
                        }
                        else
                        {
                            var script = db.ExportSchemaObjects(type, name);
                            if (!string.IsNullOrEmpty(output))
                            {
                                File.WriteAllText(output, script);
                                Console.WriteLine($"Schema exported to: {output}");
                            }
                            else
                            {
                                Console.WriteLine(script);
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Error: {ex.Message}");
                    }
                    continue;
                }

                Console.WriteLine($"Error: unknown command '{tokens[0]}'");
                continue;
            }

            buffer.AppendLine(line);

            if (EndsStatement(line))
                ExecuteBufferedStatement(buffer, db, ref outputFormat);
        }

        Console.WriteLine("Goodbye!");
    }

    /// <summary>Compare results of two SQL queries</summary>
    /// <param name="query1">First SQL query</param>
    /// <param name="query2">Second SQL query</param>    /// <param name="dbType">-t, Database type</param>
    /// <param name="config">Path to configuration file</param>
    [Command("compare")]
    public void Compare(
        [Argument] string query1 = "",
        [Argument] string query2 = "",
        string dbType = "sqlite",
        string? config = null)
    {
        if (string.IsNullOrWhiteSpace(query1) || string.IsNullOrWhiteSpace(query2))
        {
            Console.WriteLine("Error: Both query1 and query2 are required");
            Environment.ExitCode = 1;
            return;
        }

        try
        {
            using var db = CreateContext(null, dbType, config);
            
            // Determine the operator based on database type
            var operator_ = dbType.ToLower() switch
            {
                "sqlite" => "EXCEPT",
                "postgresql" => "EXCEPT",
                "sqlserver" => "EXCEPT",
                _ => "MINUS"
            };

            Console.WriteLine("[1/3] Comparing record counts...");
            
            // Count records in query1
            var count1Query = $"SELECT COUNT(*) AS Count FROM ({query1}) t";
            var count1Result = db.Query(count1Query);
            var count1 = Convert.ToInt64(count1Result[0]["Count"]);
            
            // Count records in query2
            var count2Query = $"SELECT COUNT(*) AS Count FROM ({query2}) t";
            var count2Result = db.Query(count2Query);
            var count2 = Convert.ToInt64(count2Result[0]["Count"]);
            
            Console.WriteLine($"  Query1: {count1} records");
            Console.WriteLine($"  Query2: {count2} records");
            
            if (count1 != count2)
            {
                Console.WriteLine("  ✗ Record counts differ");
            }
            else
            {
                Console.WriteLine($"  ✓ Record counts match ({count1} records)");
            }

            Console.WriteLine();
            Console.WriteLine("[2/3] Checking differences (query1 - query2)...");
            
            // Find records in query1 not in query2
            var diff1Query = $"SELECT COUNT(*) as DiffCount FROM ({query1} {operator_} {query2}) t";
            var diff1Result = db.Query(diff1Query);
            var diff1Count = Convert.ToInt64(diff1Result[0]["DiffCount"]);
            Console.WriteLine($"  Unique to query1: {diff1Count} records");

            Console.WriteLine();
            Console.WriteLine("[3/3] Checking differences (query2 - query1)...");
            
            // Find records in query2 not in query1
            var diff2Query = $"SELECT COUNT(*) as DiffCount FROM ({query2} {operator_} {query1}) t";
            var diff2Result = db.Query(diff2Query);
            var diff2Count = Convert.ToInt64(diff2Result[0]["DiffCount"]);
            Console.WriteLine($"  Unique to query2: {diff2Count} records");

            Console.WriteLine();
            
            if (diff1Count == 0 && diff2Count == 0)
            {
                Console.WriteLine("✓ Query results are identical");
                Environment.ExitCode = 0;
            }
            else
            {
                var totalDiff = diff1Count + diff2Count;
                Console.WriteLine($"✗ Query results differ ({totalDiff} total differences)");
                Environment.ExitCode = 1;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            Environment.ExitCode = 1;
        }
    }

    private static DbContext CreateContext(string? connection, string dbType, string? configPath)
    {
        var disableNvarchar = false;
        var disableClearParameters = false;

        // Default config: if no --config is provided, auto-load appsettings.json from current directory.
        // This enables "appsettings 优先" without requiring callers (including programmatic wrappers) to pass secrets.
        if (string.IsNullOrWhiteSpace(configPath))
        {
            var defaultConfigPath = Path.Combine(Directory.GetCurrentDirectory(), "appsettings.json");
            if (File.Exists(defaultConfigPath))
                configPath = defaultConfigPath;
        }

        if (!string.IsNullOrEmpty(configPath) && File.Exists(configPath))
        {
            var json = File.ReadAllText(configPath);
            var config = JsonSerializer.Deserialize<JsonElement>(json);
            if (config.TryGetProperty("ConnectionString", out var connStr))
                connection = connStr.GetString();
            if (config.TryGetProperty("DbType", out var type))
                dbType = type.GetString()!;

            if (config.TryGetProperty("DisableNvarchar", out var disableNvarcharProp) &&
                (disableNvarcharProp.ValueKind == JsonValueKind.True || disableNvarcharProp.ValueKind == JsonValueKind.False))
                disableNvarchar = disableNvarcharProp.GetBoolean();

            if (config.TryGetProperty("DisableClearParameters", out var disableClearProp) &&
                (disableClearProp.ValueKind == JsonValueKind.True || disableClearProp.ValueKind == JsonValueKind.False))
                disableClearParameters = disableClearProp.GetBoolean();

            // Backward/typo compatibility: some docs use DisableNarvchar
            if (!disableNvarchar && config.TryGetProperty("DisableNarvchar", out var disableNarvcharProp) &&
                (disableNarvcharProp.ValueKind == JsonValueKind.True || disableNarvcharProp.ValueKind == JsonValueKind.False))
                disableNvarchar = disableNarvcharProp.GetBoolean();
        }

        if (string.IsNullOrEmpty(connection))
        {
            connection = Environment.GetEnvironmentVariable("DBCLI_CONNECTION") ?? "Data Source=dbcli.db";
        }

        var envDbType = Environment.GetEnvironmentVariable("DBCLI_DBTYPE");
        if (!string.IsNullOrEmpty(envDbType))
            dbType = envDbType;

        return new DbContext(new DbConfig
        {
            ConnectionString = connection,
            DbType = DbContext.ParseDbType(dbType),
            DisableNvarchar = disableNvarchar,
            DisableClearParameters = disableClearParameters
        });
    }

    private static string GetSql(string argValue, string? file)
    {
        if (!string.IsNullOrEmpty(file) && File.Exists(file))
            return File.ReadAllText(file);
        return argValue;
    }

    private static object? GetSqlParams(string? parameters, string? paramsFile, OutputFormat outputFormat, out string? errorMessage)
    {
        errorMessage = null;
        if (string.IsNullOrWhiteSpace(parameters) && string.IsNullOrWhiteSpace(paramsFile))
            return null;

        if (!string.IsNullOrWhiteSpace(parameters) && !string.IsNullOrWhiteSpace(paramsFile))
        {
            errorMessage = "Use either --params or --params-file, not both";
            return null;
        }

        string jsonText;
        if (!string.IsNullOrWhiteSpace(paramsFile))
        {
            if (!File.Exists(paramsFile))
            {
                errorMessage = $"Params file not found: {paramsFile}";
                return null;
            }
            jsonText = File.ReadAllText(paramsFile);
        }
        else
        {
            jsonText = parameters!;
        }

        try
        {
            using var doc = JsonDocument.Parse(jsonText);
            if (doc.RootElement.ValueKind != JsonValueKind.Object)
            {
                errorMessage = "Params JSON must be an object";
                return null;
            }
            var dict = new Dictionary<string, object?>();
            foreach (var prop in doc.RootElement.EnumerateObject())
            {
                dict[prop.Name] = ConvertJsonElement(prop.Value);
            }
            return dict;
        }
        catch (Exception ex)
        {
            errorMessage = $"Invalid params JSON: {ex.Message}";
            return null;
        }
    }

    private static object? ConvertJsonElement(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.String => element.GetString(),
            JsonValueKind.Number => element.TryGetInt64(out var l) ? l : element.GetDouble(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Null => null,
            JsonValueKind.Array => element.EnumerateArray().Select(ConvertJsonElement).ToArray(),
            JsonValueKind.Object => element.EnumerateObject()
                .ToDictionary(p => p.Name, p => ConvertJsonElement(p.Value)),
            _ => element.ToString()
        };
    }

    private static List<string> SplitArgs(string input)
    {
        var args = new List<string>();
        var current = new System.Text.StringBuilder();
        char quote = '\0';

        foreach (var c in input)
        {
            if (quote != '\0')
            {
                if (c == quote)
                {
                    quote = '\0';
                }
                else
                {
                    current.Append(c);
                }
                continue;
            }

            if (c == '"' || c == '\'')
            {
                quote = c;
                continue;
            }

            if (char.IsWhiteSpace(c))
            {
                if (current.Length > 0)
                {
                    args.Add(current.ToString());
                    current.Clear();
                }
                continue;
            }

            current.Append(c);
        }

        if (current.Length > 0)
            args.Add(current.ToString());

        return args;
    }

    private static bool IsQueryStatement(string input)
    {
        var trimmed = input.TrimStart();
        if (string.IsNullOrEmpty(trimmed))
            return false;

        var lower = trimmed.ToLowerInvariant();
        return lower.StartsWith("select")
            || lower.StartsWith("with")
            || lower.StartsWith("show")
            || lower.StartsWith("describe")
            || lower.StartsWith("pragma")
            || lower.StartsWith("explain")
            || lower.StartsWith("values")
            || lower.StartsWith("table");
    }

    private static void PrintInteractiveHelp()
    {
        Console.WriteLine("Commands:");
        Console.WriteLine("  .tables                   - List all tables");
        Console.WriteLine("  .views                    - List views");
        Console.WriteLine("  .columns <table>          - Show table columns");
        Console.WriteLine("  .format <type>            - Set output format (json/table/csv)");
        Console.WriteLine("  .help                     - Show this help");
        Console.WriteLine("  .query <sql>              - Execute SQL as query and show results");
        Console.WriteLine("  .exec <sql>               - Execute SQL as non-query");
        Console.WriteLine("  .ddl <sql>                - Execute DDL (CREATE/ALTER/DROP)");
        Console.WriteLine("  .export <table> [output]  - Export table data as INSERT SQL");
        Console.WriteLine("  .export-schema <type>     - Export schema objects");
        Console.WriteLine("     Options: -n <pattern> -o <file> --output-dir <dir>");
        Console.WriteLine("  .exit/.quit               - Exit interactive mode");
        Console.WriteLine("  Any SQL (no dot)          - End with ';' or blank line to execute");
    }

    private static bool EndsStatement(string line)
    {
        return line.TrimEnd().EndsWith(";");
    }

    private static void ExecuteBufferedStatement(System.Text.StringBuilder buffer, DbContext db, ref OutputFormat outputFormat)
    {
        var sql = TrimStatementTerminator(buffer.ToString());
        buffer.Clear();

        if (string.IsNullOrWhiteSpace(sql))
            return;

        try
        {
            if (IsQueryStatement(sql))
            {
                var result = db.Query(sql);
                Console.WriteLine(OutputFormatter.Format(result, outputFormat));
            }
            else
            {
                var affected = db.Execute(sql);
                Console.WriteLine($"Affected rows: {affected}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
        }
    }

    private static string TrimStatementTerminator(string sql)
    {
        var trimmed = sql.TrimEnd();
        if (trimmed.EndsWith(";"))
            trimmed = trimmed[..^1].TrimEnd();
        return trimmed;
    }

    private static bool ContainsGoBatch(string sql)
    {
        return Regex.IsMatch(sql, @"^\s*GO\s*;?\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase);
    }
}

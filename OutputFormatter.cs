using System.Text;
using System.Text.Json;

namespace DbCli;

public enum OutputFormat
{
    Json,
    Table,
    Csv
}

public static class OutputFormatter
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
    };

    public static string Format(List<Dictionary<string, object>> data, OutputFormat format)
    {
        return format switch
        {
            OutputFormat.Json => FormatJson(data),
            OutputFormat.Table => FormatTable(data),
            OutputFormat.Csv => FormatCsv(data),
            _ => FormatJson(data)
        };
    }

    public static string FormatResult(int affectedRows, OutputFormat format)
    {
        var result = new { AffectedRows = affectedRows, Success = true };
        return format switch
        {
            OutputFormat.Json => JsonSerializer.Serialize(result, JsonOptions),
            OutputFormat.Table => $"Affected Rows: {affectedRows}",
            OutputFormat.Csv => $"AffectedRows\n{affectedRows}",
            _ => JsonSerializer.Serialize(result, JsonOptions)
        };
    }

    public static string FormatError(string message, OutputFormat format)
    {
        var result = new { Error = message, Success = false };
        return format switch
        {
            OutputFormat.Json => JsonSerializer.Serialize(result, JsonOptions),
            OutputFormat.Table => $"Error: {message}",
            OutputFormat.Csv => $"Error\n\"{message.Replace("\"", "\"\"")}\"",
            _ => JsonSerializer.Serialize(result, JsonOptions)
        };
    }

    private static string FormatJson(List<Dictionary<string, object>> data)
    {
        return JsonSerializer.Serialize(data, JsonOptions);
    }

    private static string FormatTable(List<Dictionary<string, object>> data)
    {
        if (data.Count == 0)
            return "(No rows returned)";

        var columns = data[0].Keys.ToList();
        var columnWidths = new Dictionary<string, int>();

        foreach (var col in columns)
        {
            columnWidths[col] = col.Length;
        }

        foreach (var row in data)
        {
            foreach (var col in columns)
            {
                var value = row[col]?.ToString() ?? "NULL";
                columnWidths[col] = Math.Max(columnWidths[col], GetDisplayWidth(value));
            }
        }

        foreach (var col in columns)
        {
            columnWidths[col] = Math.Min(columnWidths[col], 50);
        }

        var sb = new StringBuilder();
        var separator = "+" + string.Join("+", columns.Select(c => new string('-', columnWidths[c] + 2))) + "+";

        sb.AppendLine(separator);
        sb.Append("|");
        foreach (var col in columns)
        {
            sb.Append($" {PadRight(col, columnWidths[col])} |");
        }
        sb.AppendLine();
        sb.AppendLine(separator);

        foreach (var row in data)
        {
            sb.Append("|");
            foreach (var col in columns)
            {
                var value = Truncate(row[col]?.ToString() ?? "NULL", 50);
                sb.Append($" {PadRight(value, columnWidths[col])} |");
            }
            sb.AppendLine();
        }
        sb.AppendLine(separator);
        sb.AppendLine($"({data.Count} row(s))");

        return sb.ToString();
    }

    private static string FormatCsv(List<Dictionary<string, object>> data)
    {
        if (data.Count == 0)
            return string.Empty;

        var columns = data[0].Keys.ToList();
        var sb = new StringBuilder();

        sb.AppendLine(string.Join(",", columns.Select(EscapeCsv)));

        foreach (var row in data)
        {
            var values = columns.Select(c => EscapeCsv(row[c]?.ToString() ?? ""));
            sb.AppendLine(string.Join(",", values));
        }

        return sb.ToString();
    }

    private static string EscapeCsv(string value)
    {
        if (value.Contains(',') || value.Contains('"') || value.Contains('\n') || value.Contains('\r'))
        {
            return $"\"{value.Replace("\"", "\"\"")}\"";
        }
        return value;
    }

    private static int GetDisplayWidth(string s)
    {
        int width = 0;
        foreach (var c in s)
        {
            width += c > 127 ? 2 : 1;
        }
        return width;
    }

    private static string PadRight(string s, int totalWidth)
    {
        var currentWidth = GetDisplayWidth(s);
        if (currentWidth >= totalWidth)
            return s;
        return s + new string(' ', totalWidth - currentWidth);
    }

    private static string Truncate(string s, int maxLength)
    {
        if (GetDisplayWidth(s) <= maxLength)
            return s;

        var result = new StringBuilder();
        int width = 0;
        foreach (var c in s)
        {
            var charWidth = c > 127 ? 2 : 1;
            if (width + charWidth > maxLength - 3)
            {
                result.Append("...");
                break;
            }
            result.Append(c);
            width += charWidth;
        }
        return result.ToString();
    }

    public static OutputFormat ParseFormat(string format)
    {
        return format.ToLower() switch
        {
            "json" => OutputFormat.Json,
            "table" => OutputFormat.Table,
            "csv" => OutputFormat.Csv,
            _ => OutputFormat.Json
        };
    }
}

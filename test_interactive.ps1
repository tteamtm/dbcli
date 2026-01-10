# DbCli Interactive Test Script for PowerShell

function Resolve-DbCli {
    if ($env:DBCLI -and (Test-Path $env:DBCLI)) {
        return $env:DBCLI
    }

    $candidates = @(
        ".\\bin\\Debug\\net10.0\\win-x64\\dbcli.exe",
        ".\\bin\\Debug\\net10.0\\dbcli.exe",
        ".\\bin\\Release\\net10.0\\win-x64\\publish\\dbcli.exe",
        ".\\bin\\Release\\net10.0\\win-arm64\\publish\\dbcli.exe",
        ".\\dist-win-x64\\dbcli.exe",
        ".\\dist-win-arm64\\dbcli.exe",
        ".\\publish\\win-x64\\dbcli.exe",
        ".\\publish\\win-arm64\\dbcli.exe",
        ".\\dbcli.exe"
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

$DBCLI = Resolve-DbCli
if (-not $DBCLI) {
    Write-Error "dbcli.exe not found. Set DBCLI env var or build first."
    exit 1
}

Write-Host "=== DbCli Interactive Test Script ===" -ForegroundColor Cyan

# Set connection via environment variables
$env:DBCLI_CONNECTION = "Data Source=test_interactive.db"
$env:DBCLI_DBTYPE = "sqlite"

Remove-Item -Path "test_interactive.db" -ErrorAction SilentlyContinue
Remove-Item -Path "schema_export.sql" -ErrorAction SilentlyContinue

& $DBCLI ddl "CREATE TABLE Products (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Price REAL, Stock INTEGER)"
& $DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Apple', 1.99, 100)"
& $DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Banana', 0.99, 150)"
& $DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Orange', 2.49, 80)"

$input = @"
.help
.tables
.columns Products
.format table
SELECT Name,
       Price
FROM Products
WHERE Price > 1

SELECT COUNT(*) AS total FROM Products;
.exec UPDATE Products SET Price = Price + 1 WHERE Stock < 100
SELECT * FROM Products WHERE Stock < 100;
.export Products
.schema all -o schema_export.sql
.exit
"@

$input | & $DBCLI interactive

Write-Host "=== Interactive tests completed ===" -ForegroundColor Cyan

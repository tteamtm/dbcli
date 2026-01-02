#!/usr/bin/env pwsh
<#
.SYNOPSIS
  End-to-end smoke test for SQL Server Express LocalDB.

.DESCRIPTION
  Covers DbCli commands against LocalDB:
  - ddl / exec / query (json/table/csv)
  - parameterized query/exec (including IN array)
  - #temp table DDL + DML
  - tables / columns
  - export
  - backup / restore (including identity columns)
  - export-schema (procedure/function/trigger/view/index)

  The script creates a temporary database, runs tests, then drops the database.

.PREREQUISITES
  - SQL Server Express LocalDB installed (sqllocaldb available)
  - DbCli available on PATH

.EXAMPLE
  .\test_localdb.ps1

#>
#>

$ErrorActionPreference = 'Stop'

function Write-Step($msg) {
  Write-Host "`n=== $msg ===" -ForegroundColor Cyan
}

function Require-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Host "SKIP: missing required command '$name'" -ForegroundColor Yellow
    return $false
  }
  return $true
}

function Invoke-DbCli {
  param(
    [Parameter(Mandatory=$true)][string]$DbCli,
    [Parameter(Mandatory=$true)][string]$Command,
    [Parameter(Mandatory=$true)][string]$Connection,
    [Parameter()][string]$Sql,
    [Parameter()][string]$Format = 'json',
    [Parameter()][string]$ParamsJson
  )

  $args = @($Command)
  if ($Sql -ne $null -and $Sql -ne '') { $args += @($Sql) }
  $args += @('-t', 'sqlserver', '-c', $Connection)
  if ($ParamsJson) { $args += @('-p', $ParamsJson) }
  if ($Format) { $args += @('-f', $Format) }

  $out = & $DbCli @args
  $code = $LASTEXITCODE
  return [pscustomobject]@{ Output = $out; ExitCode = $code; Args = $args }
}

if (-not (Require-Command sqllocaldb)) { exit 0 }
if (-not (Require-Command dbcli)) { exit 1 }

$DbCli = "dbcli"
Write-Host "Using DbCli: $DbCli" -ForegroundColor Gray

# Ensure LocalDB default instance is running
try { & sqllocaldb start MSSQLLocalDB | Out-Null } catch { }

$dbName = "DbCliLocalDbTest_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss'))_$PID"
$csMaster = "Server=(localdb)\MSSQLLocalDB;Database=master;Trusted_Connection=True;TrustServerCertificate=True;"
$csDb = "Server=(localdb)\MSSQLLocalDB;Database=$dbName;Trusted_Connection=True;TrustServerCertificate=True;"

Write-Host "Test database: $dbName" -ForegroundColor Gray

try {
  Write-Step "Create database"
  $r = Invoke-DbCli -DbCli $DbCli -Command 'ddl' -Connection $csMaster -Sql "IF DB_ID('$dbName') IS NOT NULL BEGIN ALTER DATABASE [$dbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$dbName]; END"
  if ($r.ExitCode -ne 0) { throw "Failed to ensure clean DB. Output: $($r.Output)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'ddl' -Connection $csMaster -Sql "CREATE DATABASE [$dbName]"
  if ($r.ExitCode -ne 0) { throw "Failed to create DB. Output: $($r.Output)" }

  Write-Step "Create schema objects"
  $createProducts = @'
CREATE TABLE Products (
  Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Name NVARCHAR(100) NOT NULL,
  Price DECIMAL(10,2) NULL,
  Stock INT NULL,
  CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT SYSUTCDATETIME()
);
'@
  $r = Invoke-DbCli -DbCli $DbCli -Command 'ddl' -Connection $csDb -Sql $createProducts
  if ($r.ExitCode -ne 0) { throw "Create table failed. Output: $($r.Output)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'ddl' -Connection $csDb -Sql "CREATE INDEX IX_Products_Name ON Products(Name)"
  if ($r.ExitCode -ne 0) { throw "Create index failed. Output: $($r.Output)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'ddl' -Connection $csDb -Sql "CREATE VIEW vProducts AS SELECT Id, Name, Price, Stock, CreatedAt FROM Products"
  if ($r.ExitCode -ne 0) { throw "Create view failed. Output: $($r.Output)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'ddl' -Connection $csDb -Sql "CREATE OR ALTER PROCEDURE sp_GetProducts AS BEGIN SET NOCOUNT ON; SELECT * FROM Products ORDER BY Id; END"
  if ($r.ExitCode -ne 0) { throw "Create procedure failed. Output: $($r.Output)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'ddl' -Connection $csDb -Sql "CREATE OR ALTER FUNCTION fn_AddOne(@x INT) RETURNS INT AS BEGIN RETURN @x + 1; END"
  if ($r.ExitCode -ne 0) { throw "Create function failed. Output: $($r.Output)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'ddl' -Connection $csDb -Sql "CREATE OR ALTER TRIGGER tr_Products_Insert ON Products AFTER INSERT AS BEGIN SET NOCOUNT ON; END"
  if ($r.ExitCode -ne 0) { throw "Create trigger failed. Output: $($r.Output)" }

  Write-Step "Insert data (exec)"
  foreach ($sql in @(
    "INSERT INTO Products (Name, Price, Stock) VALUES ('Apple', 1.99, 100)",
    "INSERT INTO Products (Name, Price, Stock) VALUES ('Banana', 0.99, 150)",
    "INSERT INTO Products (Name, Price, Stock) VALUES ('Orange', 2.49, 80)"
  )) {
    $r = Invoke-DbCli -DbCli $DbCli -Command 'exec' -Connection $csDb -Sql $sql
    if ($r.ExitCode -ne 0) { throw "Insert failed. Output: $($r.Output)" }
  }

  Write-Step "Parameterized query"
  $r = Invoke-DbCli -DbCli $DbCli -Command 'query' -Connection $csDb -Sql "SELECT Id, Name, Price FROM Products WHERE Price >= @MinPrice ORDER BY Id" -ParamsJson '{"MinPrice":1.0}' -Format 'json'
  if ($r.ExitCode -ne 0) { throw "Parameterized query failed. Output: $($r.Output)" }
  $rows = $r.Output | ConvertFrom-Json
  if ($rows.Count -ne 2) { throw "Expected 2 rows for parameterized query, got $($rows.Count)" }

  Write-Step "#temp parameterized DDL + DML"
  $tempSql = @"
CREATE TABLE #DbcliParamTest (Id INT, Name NVARCHAR(50), Qty INT);
INSERT INTO #DbcliParamTest (Id, Name, Qty) VALUES (@Id1, @Name1, @Qty1), (@Id2, @Name2, @Qty2);
UPDATE #DbcliParamTest SET Qty = Qty + @Delta WHERE Name = @Name1;
DELETE FROM #DbcliParamTest WHERE Id IN (@Ids);
SELECT * FROM #DbcliParamTest ORDER BY Id;
"@
  $r = Invoke-DbCli -DbCli $DbCli -Command 'query' -Connection $csDb -Sql $tempSql -ParamsJson '{"Id1":1,"Name1":"Alpha","Qty1":10,"Id2":2,"Name2":"Beta","Qty2":20,"Delta":5,"Ids":[2]}' -Format 'json'
  if ($r.ExitCode -ne 0) { throw "#temp parameterized test failed. Output: $($r.Output)" }
  $tempRows = $r.Output | ConvertFrom-Json
  if ($tempRows.Count -ne 1 -or $tempRows[0].Qty -ne 15) { throw "#temp parameterized result unexpected." }

  Write-Step "Query (json/table/csv)"
  $r = Invoke-DbCli -DbCli $DbCli -Command 'query' -Connection $csDb -Sql "SELECT Id, Name, Price, Stock FROM Products ORDER BY Id" -Format 'json'
  if ($r.ExitCode -ne 0) { throw "Query(json) failed. Output: $($r.Output)" }
  $rows = $r.Output | ConvertFrom-Json
  if ($rows.Count -ne 3) { throw "Expected 3 rows, got $($rows.Count)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'query' -Connection $csDb -Sql "SELECT TOP 3 Id, Name, Price, Stock FROM Products ORDER BY Id" -Format 'table'
  if ($r.ExitCode -ne 0) { throw "Query(table) failed. Output: $($r.Output)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'query' -Connection $csDb -Sql "SELECT TOP 3 Id, Name, Price, Stock FROM Products ORDER BY Id" -Format 'csv'
  if ($r.ExitCode -ne 0) { throw "Query(csv) failed. Output: $($r.Output)" }

  Write-Step "tables / columns"
  $r = Invoke-DbCli -DbCli $DbCli -Command 'tables' -Connection $csDb -Format 'json'
  if ($r.ExitCode -ne 0) { throw "tables failed. Output: $($r.Output)" }
  $tables = $r.Output | ConvertFrom-Json
  if (-not ($tables.TableName -contains 'Products' -or $tables.TableName -contains 'dbo.Products')) {
    # Some providers return schema-qualified names, some don't.
    $flat = ($tables | ForEach-Object { $_.TableName }) -join ','
    if ($flat -notmatch 'Products') { throw "Expected Products table in tables output. Got: $flat" }
  }

  $r = & $DbCli columns Products -t sqlserver -c $csDb -f json
  if ($LASTEXITCODE -ne 0) { throw "columns failed. Output: $r" }

  Write-Step "export"
  $exportSql = & $DbCli export Products -t sqlserver -c $csDb
  if ($LASTEXITCODE -ne 0) { throw "export failed. Output: $exportSql" }
  if (($exportSql -join "`n") -notmatch 'INSERT INTO') { throw "export output did not contain INSERT statements" }

  Write-Step "backup + restore (identity-aware)"
  $backupName = "Products_backup_$PID"
  $r = & $DbCli backup Products -o $backupName -t sqlserver -c $csDb -f json
  if ($LASTEXITCODE -ne 0) { throw "backup failed. Output: $r" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'exec' -Connection $csDb -Sql "UPDATE Products SET Stock = Stock + @Delta WHERE Name = @Name" -ParamsJson '{"Delta":5,"Name":"Apple"}' -Format 'json'
  if ($r.ExitCode -ne 0) { throw "update failed. Output: $($r.Output)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'exec' -Connection $csDb -Sql "DELETE FROM Products WHERE Id IN (@Ids)" -ParamsJson '{"Ids":[2]}' -Format 'json'
  if ($r.ExitCode -ne 0) { throw "delete failed. Output: $($r.Output)" }

  $restoreOut = & $DbCli restore Products --from $backupName -t sqlserver -c $csDb -f json
  if ($LASTEXITCODE -ne 0) { throw "restore failed. Output: $restoreOut" }
  $restoreObj = $restoreOut | ConvertFrom-Json
  if (-not $restoreObj.Success) { throw "restore reported failure: $($restoreObj.Message)" }

  $r = Invoke-DbCli -DbCli $DbCli -Command 'query' -Connection $csDb -Sql "SELECT COUNT(*) AS Cnt FROM Products" -Format 'json'
  $cnt = ($r.Output | ConvertFrom-Json)[0].Cnt
  if ($cnt -ne 3) { throw "Expected 3 rows after restore, got $cnt" }

  Write-Step "export-schema"
  $schema = & $DbCli export-schema all -t sqlserver -c $csDb
  if ($LASTEXITCODE -ne 0) { throw "export-schema failed. Output: $schema" }
  $schemaText = ($schema -join "`n")
  foreach ($needle in @('sp_GetProducts','fn_AddOne','tr_Products_Insert','vProducts','IX_Products_Name')) {
    if ($schemaText -notmatch [Regex]::Escape($needle)) {
      throw "export-schema missing expected object: $needle"
    }
  }

  Write-Host "`nPASS: LocalDB end-to-end tests succeeded." -ForegroundColor Green
}
finally {
  Write-Step "Cleanup"
  try {
    & $DbCli ddl "IF DB_ID('$dbName') IS NOT NULL BEGIN ALTER DATABASE [$dbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$dbName]; END" -t sqlserver -c $csMaster -f json | Out-Null
  } catch {
    Write-Host "Cleanup warning: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

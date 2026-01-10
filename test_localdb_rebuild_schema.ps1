#!/usr/bin/env pwsh
<#
.SYNOPSIS
  E2E test: create SQL Server objects, export all scripts to one file, drop objects (with data backup), rebuild from script, restore data.

.DESCRIPTION
  Uses SQL Server Express LocalDB.

  Flow:
    1) Create DB + tables + schema objects (view/proc/func/trigger/index)
    2) Export schema objects via `export-schema all` to a file
    3) Build a single rebuild script file (tables DDL + exported schema objects)
    4) Backup data tables
    5) Drop schema objects + tables
    6) Recreate schema via `ddl -F <file>`
    7) Restore data via `restore`

.PREREQUISITES
  - SQL Server Express LocalDB installed (sqllocaldb available)
  - DbCli binary available (defaults to dist-win-x64/dbcli.exe)

.EXAMPLE
  .\test_localdb_rebuild_schema.ps1

.EXAMPLE
  $env:DBCLI = '.\dist-win-x64\dbcli.exe'; .\test_localdb_rebuild_schema.ps1
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

function Resolve-DbCliPath {
  if ($env:DBCLI -and (Test-Path $env:DBCLI)) { return (Resolve-Path $env:DBCLI).Path }

  $candidates = @(
    '.\\dist-win-x64\\dbcli.exe',
    '.\\dist-win-arm64\\dbcli.exe',
    '.\\dbcli.exe',
    '.\\publish\\win-x64\\dbcli.exe'
  )

  foreach ($p in $candidates) {
    if (Test-Path $p) { return (Resolve-Path $p).Path }
  }

  $cmd = Get-Command dbcli -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  throw "DbCli not found. Set env var DBCLI to the path of dbcli.exe, or build/publish first."
}

if (-not (Require-Command sqllocaldb)) { exit 0 }

$DbCli = Resolve-DbCliPath
Write-Host "Using DbCli: $DbCli" -ForegroundColor Gray

# Ensure LocalDB default instance is running
try { & sqllocaldb start MSSQLLocalDB | Out-Null } catch { }

$dbName = "DbCliLocalDbRebuild_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss'))_$PID"
$csMaster = "Server=(localdb)\MSSQLLocalDB;Database=master;Trusted_Connection=True;TrustServerCertificate=True;"
$csDb = "Server=(localdb)\MSSQLLocalDB;Database=$dbName;Trusted_Connection=True;TrustServerCertificate=True;"

$workDir = Join-Path $PSScriptRoot '.tmp'
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

$schemaObjectsFile = Join-Path $workDir "$dbName.schema-objects.sql"
$rebuildFile = Join-Path $workDir "$dbName.rebuild.sql"
$schemaDir = Join-Path $workDir "$dbName.schema.d"

Write-Host "Test database: $dbName" -ForegroundColor Gray
Write-Host "Work dir:      $workDir" -ForegroundColor Gray

try {
  Write-Step "Create database"
  $env:DBCLI_CONNECTION = $csMaster
  $env:DBCLI_DBTYPE = 'sqlserver'
  & $DbCli ddl "IF DB_ID('$dbName') IS NOT NULL BEGIN ALTER DATABASE [$dbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$dbName]; END" -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Failed to ensure clean DB" }

  & $DbCli ddl "CREATE DATABASE [$dbName]" -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Failed to create DB" }

  Write-Step "Create tables"
  $tablesSql = @'
CREATE TABLE Products (
  Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Products PRIMARY KEY,
  Name NVARCHAR(100) NOT NULL,
  Price DECIMAL(10,2) NULL,
  Stock INT NULL,
  CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT SYSUTCDATETIME()
);

CREATE TABLE Orders (
  Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
  ProductId INT NOT NULL,
  Qty INT NOT NULL,
  CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Orders_CreatedAt DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Orders_Products FOREIGN KEY (ProductId) REFERENCES Products(Id)
);
'@
  $env:DBCLI_CONNECTION = $csDb
  & $DbCli ddl $tablesSql -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Create tables failed" }

  Write-Step "Create schema objects (index/view/proc/func/trigger)"
  & $DbCli ddl "CREATE INDEX IX_Products_Name ON Products(Name);" -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Create index failed" }

  & $DbCli ddl "CREATE VIEW vProducts AS SELECT Id, Name, Price, Stock, CreatedAt FROM Products;" -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Create view failed" }

  & $DbCli ddl "CREATE OR ALTER PROCEDURE sp_GetProducts AS BEGIN SET NOCOUNT ON; SELECT * FROM Products ORDER BY Id; END" -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Create procedure failed" }

  & $DbCli ddl "CREATE OR ALTER FUNCTION fn_AddOne(@x INT) RETURNS INT AS BEGIN RETURN @x + 1; END" -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Create function failed" }

  & $DbCli ddl "CREATE OR ALTER TRIGGER tr_Products_Insert ON Products AFTER INSERT AS BEGIN SET NOCOUNT ON; END" -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Create trigger failed" }

  Write-Step "Insert data"
  & $DbCli exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Apple', 1.99, 100);" -f json | Out-Null
  & $DbCli exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Banana', 0.99, 150);" -f json | Out-Null
  & $DbCli exec "INSERT INTO Orders (ProductId, Qty) VALUES (1, 2);" -f json | Out-Null
  & $DbCli exec "INSERT INTO Orders (ProductId, Qty) VALUES (2, 5);" -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Insert data failed" }

  Write-Step "Export schema objects to file"
  & $DbCli export-schema all -o $schemaObjectsFile | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "export-schema failed" }
  if (-not (Test-Path $schemaObjectsFile)) { throw "export-schema did not create output file" }

  Write-Step "Export schema objects to directory (per-object files)"
  $schemaDir = Join-Path $workDir "$dbName.schema.d"
  if (Test-Path $schemaDir) { Remove-Item -Recurse -Force $schemaDir }
  $out = & $DbCli export-schema all --output-dir $schemaDir
  if ($LASTEXITCODE -ne 0) { throw "export-schema --output-dir failed. Output: $out" }
  if (-not (Test-Path $schemaDir)) { throw "export-schema did not create output directory" }
  $files = Get-ChildItem -Path $schemaDir -File -Filter '*.sql'
  if ($files.Count -lt 4) { throw "Expected multiple per-object .sql files, got $($files.Count)" }
  $expected = @('procedure__sp_GetProducts.sql','function__fn_AddOne.sql','trigger__tr_Products_Insert.sql','view__vProducts.sql')
  foreach ($f in $expected) {
    if (-not (Test-Path (Join-Path $schemaDir $f))) { throw "Missing expected exported file: $f" }
  }

  Write-Step "Export schema objects to directory (separate files)"
  if (Test-Path $schemaDir) { Remove-Item -Recurse -Force $schemaDir }
  $out = & $DbCli export-schema all --output-dir $schemaDir
  if ($LASTEXITCODE -ne 0) { throw "export-schema --output-dir failed. Output: $out" }
  if (-not (Test-Path $schemaDir)) { throw "export-schema --output-dir did not create directory" }
  $files = Get-ChildItem -Path $schemaDir -File -Filter '*.sql'
  if ($files.Count -lt 3) { throw "Expected at least 3 .sql files in schema output dir, got $($files.Count)" }
  foreach ($needle in @('sp_GetProducts','fn_AddOne','tr_Products_Insert','vProducts')) {
    $hit = $false
    foreach ($f in $files) {
      $t = Get-Content -LiteralPath $f.FullName -Raw
      if ($t -match [Regex]::Escape($needle)) { $hit = $true; break }
    }
    if (-not $hit) { throw "Did not find expected object '$needle' in any per-object file" }
  }

  Write-Step "Build single rebuild script (tables + exported schema objects)"
  $schemaObjectsText = Get-Content -LiteralPath $schemaObjectsFile -Raw
  $rebuildText = @(
    "-- DbCli LocalDB rebuild script",
    "-- Generated: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))",
    "",
    "-- ========================================",
    "-- Tables",
    "-- ========================================",
    "",
    $tablesSql.Trim(),
    "",
    "GO",
    "",
    "-- ========================================",
    "-- Schema Objects (export-schema all)",
    "-- ========================================",
    "",
    $schemaObjectsText.Trim(),
    ""
  ) -join "`r`n"
  Set-Content -LiteralPath $rebuildFile -Value $rebuildText -Encoding UTF8

  Write-Step "Backup data tables"
  $backupProducts = "Products_backup_$PID"
  $backupOrders = "Orders_backup_$PID"

  $out = & $DbCli backup Products -o $backupProducts -f json
  if ($LASTEXITCODE -ne 0) { throw "backup Products failed. Output: $out" }

  $out = & $DbCli backup Orders -o $backupOrders -f json
  if ($LASTEXITCODE -ne 0) { throw "backup Orders failed. Output: $out" }

  Write-Step "Drop schema objects + tables (keep backups)"
  # Drop dependents first
  & $DbCli ddl "DROP TRIGGER IF EXISTS tr_Products_Insert;" -f json | Out-Null
  & $DbCli ddl "DROP PROCEDURE IF EXISTS sp_GetProducts;" -f json | Out-Null
  & $DbCli ddl "DROP FUNCTION IF EXISTS fn_AddOne;" -f json | Out-Null
  & $DbCli ddl "DROP VIEW IF EXISTS vProducts;" -f json | Out-Null
  & $DbCli ddl "DROP INDEX IF EXISTS IX_Products_Name ON Products;" -f json | Out-Null

  # Drop tables (FK order)
  & $DbCli ddl "DROP TABLE IF EXISTS Orders; DROP TABLE IF EXISTS Products;" -f json | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Drop objects/tables failed" }

  Write-Step "Rebuild from script file"
  $out = & $DbCli ddl --file $rebuildFile -f json
  if ($LASTEXITCODE -ne 0) { throw "Rebuild ddl failed (script execution). Output: $out" }

  Write-Step "Restore data"
  $out = & $DbCli restore Products --from $backupProducts -f json
  if ($LASTEXITCODE -ne 0) { throw "restore Products failed. Output: $out" }

  $out = & $DbCli restore Orders --from $backupOrders -f json
  if ($LASTEXITCODE -ne 0) { throw "restore Orders failed. Output: $out" }

  Write-Step "Verify counts and objects"
  $prodCnt = (& $DbCli query "SELECT COUNT(*) AS Cnt FROM Products" -f json | ConvertFrom-Json)[0].Cnt
  $orderCnt = (& $DbCli query "SELECT COUNT(*) AS Cnt FROM Orders" -f json | ConvertFrom-Json)[0].Cnt
  if ($prodCnt -ne 2) { throw "Expected 2 Products rows, got $prodCnt" }
  if ($orderCnt -ne 2) { throw "Expected 2 Orders rows, got $orderCnt" }

  $schema = & $DbCli export-schema all
  if ($LASTEXITCODE -ne 0) { throw "export-schema after rebuild failed" }
  $schemaText = ($schema -join "`n")
  foreach ($needle in @('sp_GetProducts','fn_AddOne','tr_Products_Insert','vProducts','IX_Products_Name')) {
    if ($schemaText -notmatch [Regex]::Escape($needle)) {
      throw "Rebuilt schema missing expected object: $needle"
    }
  }

  Write-Host "`nPASS: Rebuild from exported schema script succeeded." -ForegroundColor Green
  Write-Host "Schema objects file: $schemaObjectsFile" -ForegroundColor Gray
  Write-Host "Rebuild script file: $rebuildFile" -ForegroundColor Gray
}
finally {
  Write-Step "Cleanup"
  try {
    $env:DBCLI_CONNECTION = $csMaster
    & $DbCli ddl "IF DB_ID('$dbName') IS NOT NULL BEGIN ALTER DATABASE [$dbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$dbName]; END" -f json | Out-Null
  } catch {
    Write-Host "Cleanup warning: $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

# DbCli Test Script for PowerShell

$DBCLI = "dbcli"
if (-not (Get-Command $DBCLI -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: dbcli not found in PATH. Install DbCli and add PATH first." -ForegroundColor Red
    exit 1
}

# Set connection via environment variables
$env:DBCLI_CONNECTION = "Data Source=test_ps.db"
$env:DBCLI_DBTYPE = "sqlite"

Write-Host "=== DbCli Test Script ===" -ForegroundColor Cyan
Write-Host ""

# Clean up
Remove-Item -Path "test_ps.db" -ErrorAction SilentlyContinue

# Test 1: Create table
Write-Host "1. Creating table..." -ForegroundColor Yellow
& $DBCLI ddl "CREATE TABLE Products (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Price REAL, Stock INTEGER)"

# Test 2: Insert data
Write-Host ""
Write-Host "2. Inserting data..." -ForegroundColor Yellow
& $DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Apple', 1.99, 100)"
& $DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Banana', 0.99, 150)"
& $DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Orange', 2.49, 80)"

# Test 2b: Parameterized query
Write-Host ""
Write-Host "2b. Parameterized query..." -ForegroundColor Yellow
& $DBCLI query "SELECT * FROM Products WHERE Stock > @MinStock" -p '{"MinStock":90}'

# Test 2c: Backup before DML
Write-Host ""
Write-Host "2c. Backup before DML..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "backups"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$backupFile = Join-Path $backupDir "Products_backup_${timestamp}.sql"
& $DBCLI export Products > $backupFile
Write-Host "Backup written: $backupFile" -ForegroundColor Cyan

# Test 2d: Parameterized exec (UPDATE)
Write-Host ""
Write-Host "2d. Parameterized exec (UPDATE)..." -ForegroundColor Yellow
& $DBCLI exec "UPDATE Products SET Stock = Stock + @Delta WHERE Name = @Name" -p '{"Delta":5,"Name":"Apple"}'

# Test 2e: Parameterized exec (DELETE + IN)
Write-Host ""
Write-Host "2e. Parameterized exec (DELETE + IN)..." -ForegroundColor Yellow
& $DBCLI exec "DELETE FROM Products WHERE Id IN (@Ids)" -p '{"Ids":[999]}' | Out-Null

# Test 3: Query data (JSON)
Write-Host ""
Write-Host "3. Query data (JSON):" -ForegroundColor Yellow
& $DBCLI query "SELECT * FROM Products"

# Test 4: Query data (Table)
Write-Host ""
Write-Host "4. Query data (Table):" -ForegroundColor Yellow
& $DBCLI query "SELECT * FROM Products" -f table

# Test 5: Query data (CSV)
Write-Host ""
Write-Host "5. Query data (CSV):" -ForegroundColor Yellow
& $DBCLI query "SELECT * FROM Products" -f csv

# Test 6: List tables
Write-Host ""
Write-Host "6. List tables:" -ForegroundColor Yellow
& $DBCLI tables -f table

# Test 7: Show columns
Write-Host ""
Write-Host "7. Show columns:" -ForegroundColor Yellow
& $DBCLI columns Products -f table

# Test 8: Update data
Write-Host ""
Write-Host "8. Update data:" -ForegroundColor Yellow
& $DBCLI exec "UPDATE Products SET Price = Price * 1.1 WHERE Stock < 100"

# Test 9: Query updated data
Write-Host ""
Write-Host "9. Query after update:" -ForegroundColor Yellow
& $DBCLI query "SELECT * FROM Products" -f table

# Test 10: Export data
Write-Host ""
Write-Host "10. Export data:" -ForegroundColor Yellow
& $DBCLI export Products

Write-Host ""
Write-Host "11. SQL Server tests are in test_localdb.ps1" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== All tests completed ===" -ForegroundColor Cyan

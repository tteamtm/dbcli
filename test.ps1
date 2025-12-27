# DbCli Test Script for PowerShell

$DBCLI = ".\bin\Release\net10.0\win-x64\publish\dbcli.exe"
$DB = "Data Source=test_ps.db"

Write-Host "=== DbCli Test Script ===" -ForegroundColor Cyan
Write-Host ""

# Clean up
Remove-Item -Path "test_ps.db" -ErrorAction SilentlyContinue

# Test 1: Create table
Write-Host "1. Creating table..." -ForegroundColor Yellow
& $DBCLI ddl "CREATE TABLE Products (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Price REAL, Stock INTEGER)" -c $DB

# Test 2: Insert data
Write-Host ""
Write-Host "2. Inserting data..." -ForegroundColor Yellow
& $DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Apple', 1.99, 100)" -c $DB
& $DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Banana', 0.99, 150)" -c $DB
& $DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Orange', 2.49, 80)" -c $DB

# Test 3: Query data (JSON)
Write-Host ""
Write-Host "3. Query data (JSON):" -ForegroundColor Yellow
& $DBCLI query "SELECT * FROM Products" -c $DB

# Test 4: Query data (Table)
Write-Host ""
Write-Host "4. Query data (Table):" -ForegroundColor Yellow
& $DBCLI query "SELECT * FROM Products" -c $DB -f table

# Test 5: Query data (CSV)
Write-Host ""
Write-Host "5. Query data (CSV):" -ForegroundColor Yellow
& $DBCLI query "SELECT * FROM Products" -c $DB -f csv

# Test 6: List tables
Write-Host ""
Write-Host "6. List tables:" -ForegroundColor Yellow
& $DBCLI tables -c $DB -f table

# Test 7: Show columns
Write-Host ""
Write-Host "7. Show columns:" -ForegroundColor Yellow
& $DBCLI columns Products -c $DB -f table

# Test 8: Update data
Write-Host ""
Write-Host "8. Update data:" -ForegroundColor Yellow
& $DBCLI exec "UPDATE Products SET Price = Price * 1.1 WHERE Stock < 100" -c $DB

# Test 9: Query updated data
Write-Host ""
Write-Host "9. Query after update:" -ForegroundColor Yellow
& $DBCLI query "SELECT * FROM Products" -c $DB -f table

# Test 10: Export data
Write-Host ""
Write-Host "10. Export data:" -ForegroundColor Yellow
& $DBCLI export Products -c $DB

Write-Host ""
Write-Host "=== All tests completed ===" -ForegroundColor Cyan

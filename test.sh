#!/bin/bash
# DbCli Test Script for Bash

if [ -z "${DBCLI:-}" ]; then
	if command -v dbcli >/dev/null 2>&1; then
		DBCLI="dbcli"
	else
		echo "ERROR: dbcli not found in PATH. Install DbCli and add PATH first." >&2
		exit 1
	fi
fi

# Set connection via environment variables
export DBCLI_CONNECTION="Data Source=test_bash.db"
export DBCLI_DBTYPE="sqlite"

echo "=== DbCli Test Script ==="
echo ""

# Clean up
rm -f test_bash.db

# Test 1: Create table
echo "1. Creating table..."
$DBCLI ddl "CREATE TABLE Products (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Price REAL, Stock INTEGER)"

# Test 2: Insert data
echo ""
echo "2. Inserting data..."
$DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Apple', 1.99, 100)"
$DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Banana', 0.99, 150)"
$DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Orange', 2.49, 80)"

# Test 2b: Parameterized query
echo ""
echo "2b. Parameterized query..."
$DBCLI query "SELECT * FROM Products WHERE Stock > @MinStock" -p '{"MinStock":90}'

# Test 2c: Backup before DML
echo ""
echo "2c. Backup before DML..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p backups
$DBCLI export Products > "backups/Products_backup_${TIMESTAMP}.sql"
echo "Backup written: backups/Products_backup_${TIMESTAMP}.sql"

# Test 2d: Parameterized exec (UPDATE)
echo ""
echo "2d. Parameterized exec (UPDATE)..."
$DBCLI exec "UPDATE Products SET Stock = Stock + @Delta WHERE Name = @Name" -p '{"Delta":5,"Name":"Apple"}'

# Test 2e: Parameterized exec (DELETE + IN)
echo ""
echo "2e. Parameterized exec (DELETE + IN)..."
$DBCLI exec "DELETE FROM Products WHERE Id IN (@Ids)" -p '{"Ids":[999]}'

# Test 3: Query data (JSON)
echo ""
echo "3. Query data (JSON):"
$DBCLI query "SELECT * FROM Products"

# Test 4: Query data (Table)
echo ""
echo "4. Query data (Table):"
$DBCLI query "SELECT * FROM Products" -f table

# Test 5: Query data (CSV)
echo ""
echo "5. Query data (CSV):"
$DBCLI query "SELECT * FROM Products" -f csv

# Test 6: List tables
echo ""
echo "6. List tables:"
$DBCLI tables -f table

# Test 7: Show columns
echo ""
echo "7. Show columns:"
$DBCLI columns Products -f table

# Test 8: Update data
echo ""
echo "8. Update data:"
$DBCLI exec "UPDATE Products SET Price = Price * 1.1 WHERE Stock < 100"

# Test 9: Query updated data
echo ""
echo "9. Query after update:"
$DBCLI query "SELECT * FROM Products" -f table

# Test 10: Export data
echo ""
echo "10. Export data:"
$DBCLI export Products

echo ""
echo "11. SQL Server tests are in test_localdb.ps1"

echo ""
echo "=== All tests completed ==="

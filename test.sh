#!/bin/bash
# DbCli Test Script for Bash

DB="Data Source=test_bash.db"

if [ -z "${DBCLI:-}" ]; then
	if [ -f "./dist-linux-x64/dbcli" ]; then
		chmod +x ./dist-linux-x64/dbcli 2>/dev/null || true
		DBCLI="./dist-linux-x64/dbcli"
	elif [ -f "./dist-linux-arm64/dbcli" ]; then
		chmod +x ./dist-linux-arm64/dbcli 2>/dev/null || true
		DBCLI="./dist-linux-arm64/dbcli"
	elif [ -f "./dbcli" ]; then
		chmod +x ./dbcli 2>/dev/null || true
		DBCLI="./dbcli"
	elif [ -f "./dbcli.exe" ]; then
		DBCLI="./dbcli.exe"
	elif command -v dbcli >/dev/null 2>&1; then
		DBCLI="dbcli"
	else
		echo "ERROR: dbcli not found. Set DBCLI=... or run from repo root with dist-linux-* present." >&2
		exit 1
	fi
fi

echo "=== DbCli Test Script ==="
echo ""

# Clean up
rm -f test_bash.db

# Test 1: Create table
echo "1. Creating table..."
$DBCLI ddl "CREATE TABLE Products (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Price REAL, Stock INTEGER)" -c "$DB"

# Test 2: Insert data
echo ""
echo "2. Inserting data..."
$DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Apple', 1.99, 100)" -c "$DB"
$DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Banana', 0.99, 150)" -c "$DB"
$DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Orange', 2.49, 80)" -c "$DB"

# Test 3: Query data (JSON)
echo ""
echo "3. Query data (JSON):"
$DBCLI query "SELECT * FROM Products" -c "$DB"

# Test 4: Query data (Table)
echo ""
echo "4. Query data (Table):"
$DBCLI query "SELECT * FROM Products" -c "$DB" -f table

# Test 5: Query data (CSV)
echo ""
echo "5. Query data (CSV):"
$DBCLI query "SELECT * FROM Products" -c "$DB" -f csv

# Test 6: List tables
echo ""
echo "6. List tables:"
$DBCLI tables -c "$DB" -f table

# Test 7: Show columns
echo ""
echo "7. Show columns:"
$DBCLI columns Products -c "$DB" -f table

# Test 8: Update data
echo ""
echo "8. Update data:"
$DBCLI exec "UPDATE Products SET Price = Price * 1.1 WHERE Stock < 100" -c "$DB"

# Test 9: Query updated data
echo ""
echo "9. Query after update:"
$DBCLI query "SELECT * FROM Products" -c "$DB" -f table

# Test 10: Export data
echo ""
echo "10. Export data:"
$DBCLI export Products -c "$DB"

echo ""
echo "=== All tests completed ==="

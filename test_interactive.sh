#!/bin/bash
# DbCli Interactive Test Script for Bash

if [ -z "${DBCLI:-}" ]; then
    if [ -n "${WSL_DISTRO_NAME:-}" ]; then
        if [ -f "./bin/Debug/net10.0/win-x64/dbcli.exe" ]; then
            DBCLI="./bin/Debug/net10.0/win-x64/dbcli.exe"
        elif [ -f "./bin/Release/net10.0/win-x64/publish/dbcli.exe" ]; then
            DBCLI="./bin/Release/net10.0/win-x64/publish/dbcli.exe"
        elif [ -f "./dist-win-x64/dbcli.exe" ]; then
            DBCLI="./dist-win-x64/dbcli.exe"
        elif [ -f "./dist-win-arm64/dbcli.exe" ]; then
            DBCLI="./dist-win-arm64/dbcli.exe"
        elif [ -f "./dbcli.exe" ]; then
            DBCLI="./dbcli.exe"
        elif command -v dbcli.exe >/dev/null 2>&1; then
            DBCLI="dbcli.exe"
        fi
    fi

    if [ -z "${DBCLI:-}" ]; then
        case "$(uname -s 2>/dev/null)" in
            MINGW*|MSYS*|CYGWIN*)
                if [ -f "./bin/Debug/net10.0/win-x64/dbcli.exe" ]; then
                    DBCLI="./bin/Debug/net10.0/win-x64/dbcli.exe"
                elif [ -f "./bin/Release/net10.0/win-x64/publish/dbcli.exe" ]; then
                    DBCLI="./bin/Release/net10.0/win-x64/publish/dbcli.exe"
                elif [ -f "./dist-win-x64/dbcli.exe" ]; then
                    DBCLI="./dist-win-x64/dbcli.exe"
                elif [ -f "./dist-win-arm64/dbcli.exe" ]; then
                    DBCLI="./dist-win-arm64/dbcli.exe"
                elif [ -f "./dbcli.exe" ]; then
                    DBCLI="./dbcli.exe"
                elif command -v dbcli.exe >/dev/null 2>&1; then
                    DBCLI="dbcli.exe"
                else
                    echo "ERROR: dbcli.exe not found. Set DBCLI=... or build first." >&2
                    exit 1
                fi
                ;;
            *)
                if [ -f "./dist-linux-x64/dbcli" ]; then
                    chmod +x ./dist-linux-x64/dbcli 2>/dev/null || true
                    DBCLI="./dist-linux-x64/dbcli"
                elif [ -f "./dist-linux-arm64/dbcli" ]; then
                    chmod +x ./dist-linux-arm64/dbcli 2>/dev/null || true
                    DBCLI="./dist-linux-arm64/dbcli"
                elif [ -f "./dbcli" ]; then
                    chmod +x ./dbcli 2>/dev/null || true
                    DBCLI="./dbcli"
                elif command -v dbcli >/dev/null 2>&1; then
                    DBCLI="dbcli"
                else
                    echo "ERROR: dbcli not found. Set DBCLI=... or run from repo root with dist-* present." >&2
                    exit 1
                fi
                ;;
        esac
    fi
fi

echo "Using DBCLI: $DBCLI"

echo "=== DbCli Interactive Test Script ==="
echo ""

# Set connection via environment variables
export DBCLI_CONNECTION="Data Source=test_interactive.db"
export DBCLI_DBTYPE="sqlite"

rm -f test_interactive.db schema_export.sql

$DBCLI ddl "CREATE TABLE Products (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Price REAL, Stock INTEGER)"
$DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Apple', 1.99, 100)"
$DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Banana', 0.99, 150)"
$DBCLI exec "INSERT INTO Products (Name, Price, Stock) VALUES ('Orange', 2.49, 80)"

cat <<'EOF' | $DBCLI interactive
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
EOF

echo ""
echo "=== Interactive tests completed ==="

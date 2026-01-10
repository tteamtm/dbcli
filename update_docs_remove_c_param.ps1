#!/usr/bin/env pwsh
<#
.SYNOPSIS
  批量移除文档和脚本中的 -c/--connection 参数引用

.DESCRIPTION
  为了避免在文档/脚本中直接暴露连接字符串（尤其是密码），建议不再使用
  `dbcli -c/--connection` 方式传参，而改用环境变量/配置文件。
  此脚本会自动把常见的 `dbcli -c ... [-t ...]` 示例替换为环境变量模式。

.EXAMPLE
  .\update_docs_remove_c_param.ps1 -WhatIf
  预览将要进行的更改

.EXAMPLE
  .\update_docs_remove_c_param.ps1
  执行实际更新
#>

param(
  [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$excludedPathPatterns = @(
  '\\\.git\\',
  '\\bin\\',
  '\\obj\\',
  '\\dist-',
  '\\backups\\'
)

$filesToUpdate = Get-ChildItem -Path $PSScriptRoot -Recurse -File -Include *.md, *.ps1, *.sh, *.py |
  Where-Object {
    $full = $_.FullName
    foreach ($p in $excludedPathPatterns) {
      if ($full -match $p) { return $false }
    }
    return $true
  } |
  ForEach-Object { $_.FullName }

function Update-FileContent {
  param([string]$FilePath)
  
  if (-not (Test-Path $FilePath)) {
    Write-Warning "跳过不存在的文件: $FilePath"
    return 0
  }
  
  $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
  $originalContent = $content
  $changes = 0
  
  # 1. 移除命令参数表格中的 -c/--connection 行
  # 匹配: | `-c, --connection <string>` | ... |
  # 或: - `-c, --connection <string>`
  $pattern1 = '(?m)^\s*[-|]\s*`-c,?\s*--connection[^`]*`[^\r\n]*[\r\n]+'
  if ($content -match $pattern1) {
    $content = $content -replace $pattern1, ''
    $changes++
  }
  
  # 2. 移除 Global Options 表格中的 connection 行
  # | `--connection` | `-c` | Database connection string |
  $pattern2 = '(?m)^\s*\|\s*`--connection`\s*\|[^\r\n]*[\r\n]+'
  if ($content -match $pattern2) {
    $content = $content -replace $pattern2, ''
    $changes++
  }
  
  # 3. 移除示例命令中的 -c 参数（简化版，只处理明显的情况）
  # dbcli -c "connection" -t sqlserver query "SELECT 1"
  # -> DBCLI_CONNECTION="connection" DBCLI_DBTYPE="sqlserver" dbcli query "SELECT 1"
  $pattern3a = '(?m)^(\s*)dbcli\s+-c\s+("[^"]*"|''[^'']*''|\S+)\s+-t\s+(\S+)\s+'
  if ($content -match $pattern3a) {
    $content = [regex]::Replace($content, $pattern3a, '$1DBCLI_CONNECTION=$2 DBCLI_DBTYPE="$3" dbcli ')
    $changes++
  }

  # dbcli -c "connection" query "SELECT 1"
  # -> DBCLI_CONNECTION="connection" dbcli query "SELECT 1"
  $pattern3b = '(?m)^(\s*)dbcli\s+-c\s+("[^"]*"|''[^'']*''|\S+)\s+'
  if ($content -match $pattern3b) {
    $content = [regex]::Replace($content, $pattern3b, '$1DBCLI_CONNECTION=$2 dbcli ')
    $changes++
  }
  
  # 统计改动
  if ($content -ne $originalContent) {
    if ($WhatIf) {
      Write-Host "[DRY-RUN] 将更新: $FilePath (发现 $changes 处匹配)" -ForegroundColor Yellow
    } else {
      Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
      Write-Host "[UPDATED] $FilePath (应用 $changes 处更改)" -ForegroundColor Green
    }
    return 1
  }
  
  Write-Host "[SKIPPED] $FilePath (无需更改)" -ForegroundColor Gray
  return 0
}

Write-Host "开始批量更新文档..." -ForegroundColor Cyan
if ($WhatIf) {
  Write-Host "(预览模式 - 不会实际修改文件)`n" -ForegroundColor Yellow
}

$updatedCount = 0
foreach ($file in $filesToUpdate) {
  $updatedCount += Update-FileContent -FilePath $file
}

Write-Host "`n完成！更新了 $updatedCount 个文件。" -ForegroundColor Cyan

Write-Host "`n⚠️  重要提示：" -ForegroundColor Yellow
Write-Host '此脚本只处理了常见的 `dbcli -c ... [-t ...]` 行首示例。' -ForegroundColor Yellow
Write-Host '如仍存在 `dbcli -c/--connection` 或程序化数组参数（例如 Python 列表里的 ''-c''），请手动检查并改为环境变量方式。' -ForegroundColor Yellow
Write-Host "`n建议：" -ForegroundColor Cyan
Write-Host '- 全局搜索: `dbcli -c` / `--connection` / `''-c''`' -ForegroundColor Cyan
Write-Host "- 逐个文件审查替换以确保正确性" -ForegroundColor Cyan

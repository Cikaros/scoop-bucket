# install-all.ps1
# 一键安装完整 Windows 开发环境（通过 Scoop）。
#
# 用法：
#   1) 右键 PowerShell -> 以管理员身份运行
#   2) powershell -ExecutionPolicy Bypass -File install-all.ps1
#
# 或跳过需要管理员的 VS2015 + Win10 SDK 步骤：
#   powershell -ExecutionPolicy Bypass -File install-all.ps1 -SkipSystemLevel
#
# 预计耗时：45-90 分钟（主要取决于 VS2015 + Qt 的下载速度）。

#Requires -Version 5.1

param(
    [switch]$SkipSystemLevel = $false
)

$ErrorActionPreference = 'Stop'

function Write-Step([int]$idx, [int]$total, [string]$msg) {
    Write-Host "[$idx/$total] $msg" -ForegroundColor Yellow
}

function Write-OK([string]$msg) {
    Write-Host "      完成  $msg" -ForegroundColor Green
}

function Write-Skip([string]$msg) {
    Write-Host "      跳过  $msg" -ForegroundColor DarkGray
}

$total = 9
$step = 0

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " 开发环境一键安装（通过 Scoop）" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Bootstrap Scoop if missing
$step++
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Step $step $total "正在安装 Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw "Scoop 安装失败。请打开新的 PowerShell 窗口后重新运行本脚本。"
    }
    Write-OK "Scoop 安装完成。"
} else {
    Write-Step $step $total "Scoop 已安装。"
}

# 2. Add buckets
$step++
Write-Step $step $total "正在添加 bucket..."
scoop bucket add extras      2>&1 | Out-Null
scoop bucket add java        2>&1 | Out-Null
scoop bucket add versions    2>&1 | Out-Null
scoop bucket add cikaros https://github.com/Cikaros/scoop-bucket
Write-OK "bucket 添加完成。"

# 3. Easy tools from official buckets
$step++
Write-Step $step $total "正在从官方 bucket 安装 Node.js / Python / Git / SVN..."
scoop install nodejs | Out-Null
scoop install python | Out-Null
scoop install git    | Out-Null
scoop install svn     | Out-Null
Write-OK "Node.js、Python、Git、SVN 安装完成。"

# 4. JDK 15 (pinned via this bucket)
$step++
Write-Step $step $total "正在安装 JDK 15（Temurin 15.0.1+9）..."
scoop install cikaros/openjdk15 | Out-Null
Write-OK "JDK 15 安装完成。JAVA_HOME 已设置。"

# 5. MySQL 8.0.21 (pinned)
$step++
Write-Step $step $total "正在安装 MySQL 8.0.21（版本锁定）..."
scoop install cikaros/mysql-8.0.21 | Out-Null
Write-OK "MySQL 8.0.21 安装完成。请运行 'mysqld --initialize-insecure --console' 完成初始化。"

# 6. Erlang + RabbitMQ (order matters)
$step++
Write-Step $step $total "正在安装 Erlang，然后安装 RabbitMQ..."
scoop install erlang  | Out-Null
scoop install rabbitmq | Out-Null
Write-OK "Erlang + RabbitMQ 安装完成。"

# 7. VS2015 + C++ (admin required, slow)
$step++
if ($SkipSystemLevel) {
    Write-Step $step $total "跳过 VS2015（指定了 -SkipSystemLevel 参数）。"
    Write-Skip "去掉 -SkipSystemLevel 并以管理员身份运行可安装。"
} else {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Step $step $total "VS2015 安装需要管理员权限，跳过。"
        Write-Skip "请以管理员身份重新运行本脚本以安装 VS2015。"
    } else {
        Write-Step $step $total "正在安装 VS2015 + C++ 工作负载（预计 20-40 分钟）..."
        scoop install cikaros/vs2015-cpp
        Write-OK "VS2015 + C++ 安装完成。"
    }
}

# 8. Windows 10 SDK 14393
$step++
if ($SkipSystemLevel) {
    Write-Step $step $total "跳过 Win10 SDK（指定了 -SkipSystemLevel 参数）。"
    Write-Skip "去掉 -SkipSystemLevel 并以管理员身份运行可安装。"
} else {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Step $step $total "Win10 SDK 安装需要管理员权限，跳过。"
        Write-Skip "请以管理员身份重新运行本脚本以安装 Win10 SDK。"
    } else {
        Write-Step $step $total "正在安装 Windows 10 SDK 14393..."
        scoop install cikaros/windows10sdk-14393
        Write-OK "Win10 SDK 14393 安装完成。"
    }
}

# 9. Qt 5.6.2 (must come AFTER VS2015 so it detects MSVC2015)
$step++
if ($SkipSystemLevel) {
    Write-Step $step $total "跳过 Qt 5.6.2（依赖 VS2015 先安装）。"
    Write-Skip "去掉 -SkipSystemLevel 并以管理员身份运行（VS2015 安装完后）可安装。"
} else {
    Write-Step $step $total "正在安装 Qt 5.6.2（MSVC2015 x64）..."
    scoop install cikaros/qt-5.6.2-msvc2015-64
    Write-OK "Qt 5.6.2 安装完成。QTDIR 已设置。"
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " 所有步骤已完成。" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Cyan
Write-Host "  * 打开新的 PowerShell 窗口，让 PATH 更新生效。"
Write-Host "  * 初始化 MySQL（一次性）："
Write-Host "      mysqld --initialize-insecure --console"
Write-Host "      net start MySQL   （可选，如果作为服务安装）"
Write-Host "  * 使用 'Developer Command Prompt for VS2015' 快捷方式加载构建环境。"
Write-Host "  * 启动 Qt Creator，应自动检测到 MSVC2015 64-bit Kit。"
Write-Host ""

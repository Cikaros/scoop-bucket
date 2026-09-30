# install-all.ps1
# 一键安装开发环境（通过 Scoop）。
# 前期目标：在 Windows 上编译 ONLYOFFICE 所需的工具链。
# 后续可根据需要扩展到其他工具。
#
# 用法：
#   1) 右键 PowerShell -> 以管理员身份运行
#   2) powershell -ExecutionPolicy Bypass -File install-all.ps1
#
# 或跳过需要管理员的 VS2015 + Win10 SDK 步骤：
#   powershell -ExecutionPolicy Bypass -File install-all.ps1 -SkipSystemLevel
#
# 预计耗时：30-60 分钟（主要取决于 VS2015 + Qt 的下载速度）。
#
# 说明：
#   - 本脚本只安装本 bucket 维护的版本锁定工具（VS2015 / Win10 SDK / Qt 5.6.2）
#     以及官方 bucket 已覆盖的常用基础工具（Node.js / Python / Git / SVN / Erlang / RabbitMQ）。
#   - JDK 与 MySQL 不在本脚本覆盖范围 —— 官方 bucket 已有，请按需自行安装：
#       scoop install openjdk      # JDK 最新 LTS
#       scoop install mysql         # MySQL 最新 8.x

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

$total = 7
$step = 0

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " 开发环境一键安装（通过 Scoop）" -ForegroundColor Cyan
Write-Host " 前期目标：ONLYOFFICE Windows 编译工具链" -ForegroundColor Cyan
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

# 4. Erlang + RabbitMQ (order matters)
$step++
Write-Step $step $total "正在安装 Erlang，然后安装 RabbitMQ..."
scoop install erlang  | Out-Null
scoop install rabbitmq | Out-Null
Write-OK "Erlang + RabbitMQ 安装完成。"

# 5. VS2015 + C++ (admin required, slow)
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

# 6. Windows 10 SDK 14393
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

# 7. Qt 5.6.2 (must come AFTER VS2015 so it detects MSVC2015)
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
Write-Host "未覆盖的工具（按需自行安装）：" -ForegroundColor Cyan
Write-Host "  * JDK:    scoop install openjdk        # 官方 java bucket"
Write-Host "  * MySQL:  scoop install mysql           # 官方 main bucket"
Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Cyan
Write-Host "  * 打开新的 PowerShell 窗口，让 PATH 更新生效。"
Write-Host "  * 使用 'Developer Command Prompt for VS2015' 快捷方式加载构建环境。"
Write-Host "  * 启动 Qt Creator，应自动检测到 MSVC2015 64-bit Kit。"
Write-Host ""

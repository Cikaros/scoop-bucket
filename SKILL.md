# Scoop Manifest 构建 SKILL

> 本文档基于 Scoop 官方文档与 GitHub 仓库整理，作为本 bucket 维护与新增 manifest 的权威操作指南。
>
> **官方参考来源**：
> - [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop) — 主仓库
> - [ScoopInstaller/Scoop Wiki](https://github.com/ScoopInstaller/Scoop/wiki) — 官方文档（首页）
> - [App-Manifests](https://github.com/ScoopInstaller/Scoop/wiki/App-Manifests) — manifest 字段完整规范
> - [Pre-Post-(un)install-scripts](https://github.com/ScoopInstaller/Scoop/wiki/Pre-Post-\(un\)install-scripts) — 安装钩子脚本规范
> - [Persistent-data](https://github.com/ScoopInstaller/Scoop/wiki/Persistent-data) — `persist` 字段说明
> - [Creating-an-app-manifest](https://github.com/ScoopInstaller/Scoop/wiki/Creating-an-app-manifest) — 入门教程
> - [ScoopInstaller/Versions](https://github.com/ScoopInstaller/Versions) — 官方 versions bucket（参照对象）
> - [ScoopInstaller/Extras](https://github.com/ScoopInstaller/Extras) — 官方 extras bucket（参照对象）

---

## 1. 概述

### 1.1 什么是 manifest

Scoop 的 manifest 是一个 JSON 文件，描述如何安装一个程序：从哪里下载、如何解压或安装、哪些可执行文件需要加进 PATH、需要持久化哪些数据、安装前后要跑什么脚本等等。

manifest 的**文件名（去掉 `.json` 后缀）**就是包名，例如 `mysql-8.0.21.json` 对应 `scoop install cikaros/mysql-8.0.21`。

### 1.2 最小可用的 manifest

来自官方文档的例子：

```json
{
  "version": "1.0",
  "url": "https://github.com/lukesampson/cowsay-psh/archive/master.zip",
  "extract_dir": "cowsay-psh-master",
  "bin": "cowsay.ps1"
}
```

### 1.3 本 bucket 的特殊约定

本 bucket 严格遵循**版本锁定模式**（参照官方 `Versions` bucket），所有 manifest 必须满足：

1. **文件名带具体版本号**（如 `mysql-8.0.21.json`），不允许通用名（如 `mysql.json`）
2. **不使用 `autoupdate` 字段** — 否则 `scoop update` 会自动升级版本
3. **不使用 `checkver` 字段** — 不需要主动检测上游新版本
4. **`notes` 字段统一用中文**
5. **manifest 一旦发布，`version` 字段不可变**；上游 URL 失效时改 `url` 指向自己镜像，不动版本号

---

## 2. 字段总览

下表为完整字段速查，详细说明见后续章节。带 ✅ 的为本 bucket 必填。

| 字段 | 类型 | 必填 | 简述 |
|------|------|------|------|
| `version` | string | ✅ | 本 manifest 锁定的具体版本号 |
| `description` | string | ✅ | 一行简短描述（不包含包名本身） |
| `homepage` | string | ✅ | 程序官网 |
| `license` | string \| `{identifier, url}` | ✅ | SPDX 标识符或特殊关键字（Freeware/Proprietary 等） |
| `url` | string \| array | ✅ | 下载地址，支持多 URL 与 `#/rename` 片段重命名 |
| `hash` | string \| array | 推荐 | SHA256 默认；可前缀 `sha512:`/`sha1:`/`md5:` |
| `extract_dir` | string | 视情况 | 从压缩包中提取的子目录名 |
| `extract_to` | string | 视情况 | 把压缩包内容解到该目录 |
| `bin` | string \| array | 视情况 | 加进 PATH 的可执行文件 |
| `env_set` | object | 可选 | 设置环境变量 |
| `env_add_path` | string | 可选 | 把 `$dir` 下的子目录加入 PATH |
| `persist` | string \| array | 可选 | 跨升级持久化的目录/文件 |
| `shortcuts` | array<array> | 可选 | 开始菜单快捷方式 |
| `notes` | string \| array | 推荐 | 安装后提示信息（**本 bucket 用中文**） |
| `pre_install` | string \| array | 可选 | 安装前 PowerShell 脚本 |
| `installer` | object | 视情况 | 自定义安装器调用（args / script / file / keep） |
| `post_install` | string \| array | 可选 | 安装后 PowerShell 脚本 |
| `uninstaller` | object | 可选 | 卸载时调用的安装器配置 |
| `pre_uninstall` / `post_uninstall` | string \| array | 可选 | 卸载前/后脚本 |
| `architecture` | object | 可选 | 按架构（32bit/64bit/arm64）差异化 |
| `innosetup` | boolean | 可选 | 标记安装器为 Inno Setup，自动用 `/VERYSILENT /SILENT` 参数 |
| `suggest` | object | 可选 | 建议用户配套安装的包 |
| `depends` | string \| array | 可选 | 运行时依赖（自动安装） |
| `##` | string \| array | 可选 | 注释字段（**官方推荐**，替代 `_comment`） |
| `psmodule` | `{name}` | 可选 | 安装为 PowerShell 模块 |
| `autoupdate` | object | **❌ 本 bucket 禁用** | 自动升级配置 |
| `checkver` | string \| object | **❌ 本 bucket 禁用** | 上游版本检测 |
| `_comment` | string \| array | **❌ 已废弃** | 用 `##` 代替 |
| `msi` | `{code, silent}` | **❌ 已废弃** | 直接省略即可触发"MSI 当 zip 解"行为 |
| `cookie` | 未文档化 | 不推荐 | 官方未公开说明 |

---

## 3. 必填字段详解

### 3.1 `version` — 版本号字符串

```json
"version": "8.0.21"
```

本 bucket 要求 `version` 字段与文件名中的版本号一致，例如 `mysql-8.0.21.json` 对应 `"version": "8.0.21"`。

### 3.2 `description` — 一行简短描述

```json
"description": "MySQL Community Server 8.0.21（锁定版本，不滚动最新）。"
```

**注意**：不要在 description 里重复包名本身（官方建议）。比如 `mysql-8.0.21` 的 description 不需要再写 "MySQL 8.0.21 是 ..."，直接说功能即可。

### 3.3 `homepage` — 程序官网

```json
"homepage": "https://dev.mysql.com/downloads/mysql/"
```

必须是合法 URL，会显示在 `scoop info <name>` 输出里。

### 3.4 `license` — 许可证

支持两种写法：

**简单 SPDX 标识符**：
```json
"license": "MIT"
```

**对象形式（推荐，更精确）**：
```json
"license": {
    "identifier": "GPL-2.0-or-later",
    "url": "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html"
}
```

特殊关键字（非 SPDX）：`Freeware`、`Proprietary`、`Public Domain`、`Shareware`、`Unknown`。

**多 license 写法约定**：
- 不同文件不同 license → 逗号分隔：`"MIT,GPL-3.0-only"`
- 整个 app 双重 license → 竖线分隔：`"MIT|Apache-2.0"`
- 开源 + 非开源混合 → **非开源 license 排在前面**
- 列不全时末尾加 `,...`

### 3.5 `url` — 下载地址

```json
"url": "https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.21-winx64.zip"
```

支持 HTTP / HTTPS / FTP。多个文件用数组：

```json
"url": [
    "https://example.org/main.zip",
    "https://example.org/deps.zip"
]
```

**重要技巧 — 片段重命名**：URL 末尾加 `#/new_name.7z`，Scoop 会按这个新名保存。这是绕过 exe 安装器副作用的常用手段：

```json
"url": "https://example.org/program-installer.exe#/dl.7z"
```

这样下载下来不会运行 exe，而是当成 7z 解压。片段**必须以 `#/` 开头**才生效。

---

## 4. 压缩/解压相关字段

### 4.1 `extract_dir` — 从压缩包提取指定子目录

```json
"url": "https://example.org/app-1.0.zip",
"extract_dir": "app-1.0"
```

如果 zip 解压后是 `app-1.0/` 目录，加这个字段会让 Scoop 把 `app-1.0/` 内的内容平铺到 `$dir`，不要外层目录。

### 4.2 `extract_to` — 把压缩包内容解到指定子目录

```json
"extract_to": "vendor"
```

与 `extract_dir` 区别：`extract_dir` 是"挑出一个子目录平铺"，`extract_to` 是"全部解压到某个子目录下"。

### 4.3 `hash` — 文件哈希校验

```json
"hash": "abcdef0123456789..."
```

**默认 SHA256**。要换算法加前缀：

```json
"hash": "sha512:abcdef..."
"hash": "sha1:abcdef..."
"hash": "md5:abcdef..."
```

`url` 是数组时，`hash` 也必须是数组，按顺序对应。

**计算方法**：

```powershell
Get-FileHash <下载的文件> -Algorithm SHA256
```

本 bucket 对部分上游 URL 不稳定的 manifest **故意省略 hash**（VS2015 / Win10 SDK / Qt 5.6.2），用户安装时用 `--skip` 跳过校验。但对下载源稳定的 manifest（如 Adoptium GitHub Release）**强烈建议填 hash**。

---

## 5. 可执行文件与 PATH

### 5.1 `bin` — 加入 PATH 的可执行文件

```json
"bin": "bin\\mysql.exe"
```

数组形式（多个 exe）：

```json
"bin": [
    "bin\\mysql.exe",
    "bin\\mysqld.exe",
    "bin\\mysqldump.exe"
]
```

**带别名的 shim**（给可执行文件起别名）：

```json
"bin": [
    ["python.exe", "py3", "-I"],
    ["pythonw.exe", "pyw3"]
]
```

**注意**：单个 alias shim 必须**包在外层数组里**，否则会被误读为多个独立 shim：

```json
// ❌ 错误：会被读成 3 个 shim
"bin": ["program.exe", "alias", "--args"]

// ✅ 正确：一个带参 alias shim
"bin": [["program.exe", "alias", "--args"]]
```

### 5.2 `env_add_path` — 把子目录加入 PATH

```json
"env_add_path": "bin"
```

`bin` 是相对 `$dir` 的子目录。Scoop 会把 `$dir\bin` 加进用户 PATH。

**约束**：路径**必须在 `$dir` 内部**，不能是绝对路径或上级目录。

### 5.3 `env_set` — 设置环境变量

```json
"env_set": {
    "MYSQL_HOME": "$dir",
    "QTDIR": "$dir"
}
```

值可以用 `$dir`、`$version` 等变量，会被展开。

---

## 6. 安装器类型与调用

### 6.1 便携式归档（zip / 7z / tar.gz / lzma）

最简单，无需 `installer` 字段：

```json
{
    "version": "1.0",
    "url": "https://example.org/app-1.0.zip",
    "extract_dir": "app-1.0",
    "bin": "app.exe"
}
```

### 6.2 Inno Setup 安装器

加 `"innosetup": true`（**字面布尔值，不要引号**），Scoop 自动用 `/VERYSILENT /SILENT /SP-` 等参数：

```json
{
    "version": "1.0",
    "url": "https://example.org/app-setup.exe",
    "innosetup": true,
    "installer": {
        "args": ["/DIR=\"$dir\"", "/MERGETASKS=\"!desktopicon,!quicklaunchicon\""]
    }
}
```

### 6.3 MSI 安装器

**新方法**：直接省略 `msi` 字段，Scoop 会把 `.msi` 当 zip 解压（不调用 msiexec，不写注册表）。这是当前推荐做法。

**老方法（已废弃）**：用 `msi: {code, silent: true}` — 不要再用。

### 6.4 通用 EXE 安装器（NSIS、自定义安装器等）

用 `installer.args` 传静默参数：

```json
{
    "version": "1.0",
    "url": "https://example.org/app-installer.exe",
    "installer": {
        "args": ["/S", "/D=$dir"]
    }
}
```

### 6.5 系统级 EXE 安装器（如 VS2015）

某些安装器（VS2015、Win10 SDK、Oracle JDK 安装版）**强制装到系统路径**，没法 portable。本 bucket 的处理：

```json
{
    "version": "14.0.25431",
    "url": "https://download.microsoft.com/.../vs_community_ENU.exe",
    "installer": {
        "args": ["/install", "/quiet", "/norestart", "/Features", "VC++,MFC,ATL"]
    },
    "post_install": [
        "Remove-Item -Path \"$dir\\$fname\" -Force -ErrorAction SilentlyContinue"
    ],
    "env_set": {
        "VS140COMNTOOLS": "C:\\Program Files (x86)\\Microsoft Visual Studio 14.0\\Common7\\Tools\\"
    }
}
```

关键点：
- `installer.args` 把静默参数传给 exe
- `post_install` 把下载的安装器从 `$dir` 清掉（节省空间）
- `env_set` 把系统路径相关的环境变量设好，方便后续构建脚本调用

### 6.6 复杂安装器（如 Qt Installer Framework）

Qt 的安装器不接受标准静默参数，必须用 QtIF 自己的脚本机制。本 bucket 在 `pre_install` 阶段把一个 `.qs` 脚本写进 `$dir`，再在 `installer.args` 里通过 `--script` 传给安装器：

```json
{
    "pre_install": [
        "$qs = @'",
        "function Controller() {",
        "    installer.autoRejectMessageBoxes = true;",
        "    var page = gui.pageWidgetByObjectName('ComponentSelection');",
        "    page.deselectAll();",
        "    page.selectComponent('qt.562.win64_msvc2015_64');",
        "    installer.installationFinished = function() {",
        "        gui.clickButton(buttons.NextButton);",
        "    };",
        "}",
        "'@",
        "$qs | Set-Content -Path \"$dir\\installscript.qs\" -Encoding UTF8"
    ],
    "installer": {
        "args": ["--script", "$dir\\installscript.qs", "--silent"]
    },
    "post_install": [
        "Remove-Item -Path \"$dir\\installscript.qs\" -Force -ErrorAction SilentlyContinue"
    ]
}
```

**JSON 中写 PowerShell here-string 的关键约束**：
- 闭合的 `'@` 必须在**行首**（前面不能有空格）
- 在 JSON 数组里，每个数组元素就是一行，所以 `'@` 要单独占一行
- 内部 PowerShell 字符串里的双引号要在 JSON 中转义为 `\"`

### 6.7 自定义安装脚本

完全用 PowerShell 替代安装器调用：

```json
{
    "installer": {
        "script": "Invoke-Expression \"$dir\\install.bat\""
    }
}
```

或在 `installer` 里同时给 `file` 和 `args`：

```json
{
    "installer": {
        "file": "$fname",
        "args": ["/quiet"],
        "keep": "true"
    }
}
```

`keep: "true"` 表示安装器文件保留（便于未来 `uninstaller` 复用，**注意是字符串 "true"，不是布尔**）。

---

## 7. 安装钩子脚本

### 7.1 4 个钩子位置

| 字段 | 触发时机 | 典型用途 |
|------|---------|---------|
| `pre_install` | 下载和解压之后、调用安装器之前 | 准备配置文件、生成临时脚本 |
| `installer.script` | 替代默认安装器调用 | 自定义安装流程 |
| `post_install` | 调用安装器之后 | 清理临时文件、写快捷方式、初始化数据 |
| `pre_uninstall` / `post_uninstall` | 卸载前/后 | 备份数据、清理残留 |

### 7.2 钩子里的可用变量

| 变量 | 含义 |
|------|------|
| `$app` | 包名（manifest 文件名） |
| `$version` | 当前版本号 |
| `$architecture` | `64bit` / `32bit` / `arm64` |
| `$cmd` | `install` / `update` / `uninstall` |
| `$global` | 是否 `--global` 全局安装 |
| `$manifest` | 反序列化后的 manifest 对象 |
| `$dir` | 安装目录（**详见下方"展开规则"**） |
| `$persist_dir` | 持久化数据目录 |
| `$cachedir` | Scoop 缓存目录 |
| `$fname` | 最后一个下载的文件名（在 `installer.script` 中可用） |
| `$original_dir` | 带版本号的原始安装目录 |

### 7.3 `$dir` 的展开规则（**关键陷阱**）

| 钩子 | `$dir` 展开为 |
|------|--------------|
| `pre_install` | 带版本号的原始路径（`...\app\1.2.3`） |
| `installer.script` | 带版本号的原始路径 |
| `post_install` | **"current" 软链接路径**（`...\app\current`） |
| `pre_uninstall` / `post_uninstall` | 带版本号的原始路径 |

写 `post_install` 脚本时要特别注意：此时 `$dir` 指向的是 `current` 链接，不是带版本号的目录。

### 7.4 实用函数

- `appdir <otherapp>` — 引用另一个 Scoop 安装的 app 路径，便于跨包探测：

  ```json
  "post_install": [
      "if (Test-Path \"$(appdir otherapp)\\current\\otherapp.exe\") { Write-Host '发现 otherapp，已配置集成' }"
  ]
  ```

---

## 8. 持久化数据

### 8.1 `persist` 字段

```json
"persist": [
    "data",
    "my.ini",
    "log",
    ["original_name", "new_name_in_persist_dir"]
]
```

机制：Scoop 把 `$dir\data` 等路径在 `$persist_dir`（`~/scoop/persist/$app/`）里建立链接（目录用 junction，文件用 hard link）。

升级时数据自动迁移，**不需要在脚本里手动搬数据**。

### 8.2 卸载行为

- 默认：`scoop uninstall` 会保留持久化数据，方便重装
- 加 `-p` 参数：`scoop uninstall -p mysql-8.0.21` 会**清空**持久化数据

### 8.3 本 bucket 使用 `persist` 的 manifest

`mysql-8.0.21.json` 持久化 `data` / `my.ini` / `log` 三项，确保 `scoop update mysql-8.0.21` 不丢数据库。

---

## 9. 架构特定 manifest

当 32/64 bit / arm64 安装包不一样时，用 `architecture` 字段：

```json
{
    "version": "1.0",
    "architecture": {
        "64bit": {
            "url": "https://example.org/app-x64.zip",
            "extract_dir": "app-x64"
        },
        "32bit": {
            "url": "https://example.org/app-x86.zip",
            "extract_dir": "app-x86"
        },
        "arm64": {
            "url": "https://example.org/app-arm64.zip",
            "extract_dir": "app-arm64"
        }
    }
}
```

`architecture.<arch>` 下允许的字段：`bin`、`checkver`、`extract_dir`、`hash`、`installer`、`pre_install`、`post_install`、`shortcuts`、`uninstaller`、`url`、（已废弃的 `msi`）。

本 bucket 当前所有 manifest 只针对 x64 架构（VS2015 / Win10 SDK / Qt 5.6.2 msvc2015_64 / OpenJDK 15 x64 / MySQL 8.0.21 winx64），所以没有用 `architecture` 字段。后续如果要支持 ARM64，加 `architecture` 即可。

---

## 10. 开始菜单快捷方式

```json
"shortcuts": [
    ["app.exe", "MyApp"],
    ["app.exe", "Utils\\MyApp (Admin)", "--admin"]
]
```

每条快捷方式是 `[targetPath, label, startParams?, iconPath?]`，后两个可选。Label 可以用反斜杠组织子目录（如 `Utils\\MyApp`）。

---

## 11. Hash 校验

### 11.1 计算方法

```powershell
Get-FileHash <下载的文件> -Algorithm SHA256
```

### 11.2 跳过校验

某些上游 URL 不可控时，可以省略 `hash` 字段，用户安装时加 `--skip`：

```powershell
scoop install cikaros/vs2015-cpp --skip
```

### 11.3 多 URL 的 hash

```json
"url": ["https://a", "https://b"],
"hash": ["sha256:...", "sha256:..."]
```

数组顺序与 `url` 一致。

---

## 12. 调试技巧

### 12.1 检查 manifest 是否能被 scoop 解析

```powershell
scoop cat <name>
```

如果 manifest JSON 语法错误或必填字段缺失，会直接报错。CI workflow 就是跑这个来校验所有 manifest。

### 12.2 安装时绕过缓存

```powershell
scoop install <name> --no-cache-dir
```

强制重新下载，便于验证 hash 是否匹配实际下载内容。

### 12.3 单文件 JSON 语法校验

```powershell
Get-Content bucket/mysql-8.0.21.json -Raw | ConvertFrom-Json | Out-Null
Write-Host "JSON OK"
```

或者用 Python：

```bash
python3 -c "import json; json.load(open('bucket/mysql-8.0.21.json'))"
```

### 12.4 查看 manifest 字段

```powershell
scoop info <name>
```

输出 manifest 解析后的关键字段，便于排查 `bin`、`env_set`、`persist` 是否正确。

---

## 13. 常见陷阱

### 13.1 URL 失效

微软 / Oracle 等厂商会调整下载链接。处理方法：

1. 从上游找新地址，更新 `url` 字段
2. 如果上游彻底下线，**镜像到你自己的 GitHub Release**，更新 `url` 指向 Release asset
3. **不要修改 `version` 字段**（版本锁定承诺）

### 13.2 Hash 不匹配

可能原因：
- 上游静默更新了补丁版本
- 下载源切换
- hash 字段算错算法（默认 SHA256，确认没用错前缀）

修复：重新算 hash，或者用 `--skip` 暂时绕过。

### 13.3 PowerShell here-string 在 JSON 中的写法

闭合 `'@` 必须在**行首无空格**。在 JSON 数组里写时，每个数组元素就是一行，闭合的 `'@` 单独占一行：

```json
"pre_install": [
    "$qs = @'",
    "function Controller() {",
    "    ...",
    "}",
    "'@",
    "$qs | Set-Content -Path \"$dir\\installscript.qs\""
]
```

### 13.4 `extract_dir` 与压缩包内容不匹配

如果 zip 解压后顶层目录名变了（比如上游调整了打包结构），`extract_dir` 不匹配会导致 `$dir` 为空。安装后用 `ls $dir` 验证。

### 13.5 `bin` 单 alias shim 没包外层数组

```json
// ❌ 被读成 3 个独立 shim
"bin": ["program.exe", "alias", "--args"]

// ✅ 一个带 2 个参数的 alias shim
"bin": [["program.exe", "alias", "--args"]]
```

### 13.6 系统级安装器的 `$dir` 行为

VS2015 这类系统级安装器，`$dir` 仍然是 Scoop 管理的临时目录（里面有下载的安装器 exe），但**真正的安装目标是 `C:\Program Files (x86)\...`**。`post_install` 清理 `$dir` 里的安装器文件即可，不要试图改 `$dir` 指向系统目录。

### 13.7 `env_add_path` 的约束

必须是 `$dir` 内部的子目录路径，不能用 `..` 或绝对路径。

### 13.8 `keep` 是字符串不是布尔

```json
// ❌
"keep": true

// ✅
"keep": "true"
```

---

## 14. 本 bucket 中的 manifest 实例参考

| Manifest | 类型 | 看点 |
|----------|------|------|
| `bucket/mysql-8.0.21.json` | 便携式归档 | `persist` 字段持久化数据库目录；多 `bin` shim |
| `bucket/openjdk15.json` | 便携式归档 | `extract_dir` 配合 GitHub Release；`env_set JAVA_HOME` |
| `bucket/vs2015-cpp.json` | 系统级 EXE 安装器 | `installer.args` + `/quiet` 静默参数 + 系统 PATH 配置 |
| `bucket/windows10sdk-14393.json` | 系统级 EXE 安装器 | 与 VS2015 类似的模式，针对独立 SDK 安装器 |
| `bucket/qt-5.6.2-msvc2015-64.json` | QtIF 自定义安装器 | `pre_install` 写 `.qs` 脚本，`installer.args` 用 `--script` 调用 |

---

## 15. 本 bucket 不用的功能（仅供查阅）

### 15.1 `autoupdate`

官方 `main` / `extras` / `versions` 仓库用 `autoupdate` + `checkver` 实现"manifest 自动跟随上游版本滚动"。本 bucket 是**版本锁定**模式，禁用这两个字段。

如需了解 autoupdate 配置（`autoupdate.url`、`autoupdate.hash` 等子字段），查 [App-Manifest-Autoupdate](https://github.com/ScoopInstaller/Scoop/wiki/App-Manifest-Autoupdate) wiki 页。

### 15.2 `checkver`

同上，禁用。如果需要追踪某个工具的最新版本，建议在本仓库的**单独工具脚本**里实现，不要放进 manifest。

### 15.3 `msi`

已废弃。直接省略即可让 Scoop 把 `.msi` 当 zip 解。如果非要走 msiexec 静默安装，用 `installer.args` 传 `/quiet /norestart` 等参数。

### 15.4 `cookie`

官方未文档化字段。不要用。如需带认证的下载，把认证信息放在 `installer.script` 里用 PowerShell `Invoke-WebRequest -Headers @{...}` 处理，或者把二进制上传到自己 GitHub Release 用公开 URL。

### 15.5 `_comment`

已废弃，用 `##` 代替：

```json
{
    "##": "本 manifest 由 @cikaros 维护",
    "version": "1.0",
    ...
}
```

---

## 16. 参考 manifest 模板

### 16.1 便携式 zip 包模板

```json
{
    "version": "<版本号>",
    "description": "<简短描述>",
    "homepage": "<官网 URL>",
    "license": { "identifier": "<SPDX>", "url": "<License URL>" },
    "notes": ["【版本锁定说明】本 manifest 已锁定到 <版本号>。"],
    "url": "<下载 URL>",
    "hash": "<SHA256>",
    "extract_dir": "<解压后的顶层目录名>",
    "bin": ["<相对 $dir 的 exe 路径>"],
    "env_set": { "<ENV_VAR>": "$dir" },
    "persist": ["<要持久化的目录或文件>"]
}
```

### 16.2 系统级 EXE 安装器模板

```json
{
    "version": "<版本号>",
    "description": "<简短描述>",
    "homepage": "<官网 URL>",
    "license": { "identifier": "Freeware", "url": "<License URL>" },
    "notes": ["【版本锁定说明】...", "【安装路径】系统级安装到 C:\\Program Files\\..."],
    "url": "<下载 URL>",
    "installer": {
        "args": ["<静默参数>", "<工作负载选项>"]
    },
    "post_install": ["Remove-Item -Path \"$dir\\$fname\" -Force -ErrorAction SilentlyContinue"],
    "env_set": { "<ENV_VAR>": "C:\\Program Files\\<固定路径>" }
}
```

### 16.3 复杂自定义安装器模板（参考 Qt 5.6.2 的完整实现）

参见 `bucket/qt-5.6.2-msvc2015-64.json`。核心模式：`pre_install` 生成脚本文件，`installer.args` 传 `--script` 参数，`post_install` 清理临时文件。

---

## 17. 官方文档链接汇总

| 文档 | 链接 | 说明 |
|------|------|------|
| Wiki 首页 | https://github.com/ScoopInstaller/Scoop/wiki | 所有 wiki 页面索引 |
| App-Manifests | https://github.com/ScoopInstaller/Scoop/wiki/App-Manifests | **manifest 字段完整规范** |
| Pre-Post-(un)install-scripts | https://github.com/ScoopInstaller/Scoop/wiki/Pre-Post-\(un\)install-scripts | **安装钩子脚本变量与函数** |
| Persistent-data | https://github.com/ScoopInstaller/Scoop/wiki/Persistent-data | `persist` 字段说明 |
| Creating-an-app-manifest | https://github.com/ScoopInstaller/Scoop/wiki/Creating-an-app-manifest | 入门教程 |
| App-Manifest-Autoupdate | https://github.com/ScoopInstaller/Scoop/wiki/App-Manifest-Autoupdate | autoupdate 子字段（本 bucket 禁用，仅供查阅） |
| Buckets | https://github.com/ScoopInstaller/Scoop/wiki/Buckets | bucket 概念与维护 |
| Using Scoop behind a proxy | https://github.com/ScoopInstaller/Scoop/wiki/Using-Scoop-behind-a-proxy | 代理下载配置 |

| 官方 bucket 仓库 | 链接 | 用途 |
|------------------|------|------|
| main | https://github.com/ScoopInstaller/Main | 主仓库，常见工具的最新版 |
| extras | https://github.com/ScoopInstaller/Extras | GUI 应用、字体、扩展工具 |
| versions | https://github.com/ScoopInstaller/Versions | **本 bucket 参照对象**，旧版本锁定（但带 autoupdate） |
| java | https://github.com/ScoopInstaller/Java | JDK 各种发行版 |
| nerd-fonts | https://github.com/ScoopInstaller/NerdFonts | 字体 |

---

## 18. 修订记录

| 日期 | 改动 |
|------|------|
| 2026-09-30 | 初版。基于 ScoopInstaller/Scoop wiki（App-Manifests / Pre-Post-(un)install-scripts / Persistent-data / Creating-an-app-manifest 页面）+ ScoopInstaller/Versions bucket 实践整理而成。 |
